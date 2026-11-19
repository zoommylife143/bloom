"""LangGraph intake agent (plan sections 4-5, build steps 6 and 9).

One graph invocation = one patient turn:

    START -> safety_pre --hit--> urgent -> END
                 |
               intake -> safety_post --hit--> urgent -> END
                              |
                          save_turn --not done--> END (reply to patient)
                              |
                            done or turn 12
                              v
                  deidentify -> retrieve -> brief -> END (status=ready)

A session whose intake completed but whose brief failed (e.g. refused route) re-enters
at ``deidentify`` on the next message (``resume_brief``).

Unusable model output (live 2026-11-19: most intake answers were prose, not JSON):
- The router asks for a JSON object (json_object mode in dev), shows earlier Bloom turns
  as JSON, and makes one repair call (dev only). ``parse_path`` records which worked:
  ``first_pass``, ``repair`` or ``fallback`` (``rule`` = urgent, no model call).
- Intake fallback (deterministic, no model): fill the three required fields from the
  answers by fixed rules, then ask the NEXT required field that is still missing and was
  never asked. A question is never repeated. The intake is done as soon as the three
  are known, or when every missing one has been asked once, or after
  ``FALLBACK_TURN_LIMIT`` fallback turns, so it always ends well within ``MAX_TURNS``.
- Brief fallback: if the brief's output is unusable after the repair call (or the turn
  budget ran out), a clearly labelled DRAFT is built from the IntakeRecord with no AI
  (``fallback_brief``). It cites only retrieved passages, its provenance says
  ``source="fallback"``, and it still needs Confirm / Edit / Reject.
- Neither fallback runs after a refusal or an HTTP error, and neither calls any model:
  private mode stays fail-closed.

Safety:
- The urgent path never calls a model; it returns the fixed ``URGENT_MESSAGES`` text.
- ``ConfidentialRouteUnavailable`` and ``ModelCallError`` propagate out of ``run_turn``
  unchanged. Nothing is retried or sent to another model, the session status is not
  changed, and the API maps them to 502.
- Every patient-facing model reply passes ``safety.filter_patient_reply``.
"""

from __future__ import annotations

import contextlib
import re
import dataclasses
import threading
from dataclasses import dataclass
from typing import Any, Callable, TypedDict

from langgraph.graph import END, START, StateGraph
from pydantic import BaseModel, ValidationError

from app import safety
from app.config import Settings
from app.deidentify import build_queries
from app.models import (
    Brief,
    EvidenceItem,
    IntakeRecord,
    Provenance,
    RedFlagHit,
    RedFlagRule,
    ScreeningLine,
    SessionStatus,
    TrustEvent,
    TrustOutcome,
)
from app.prompts import CLOSING_MESSAGE, MAX_TURNS, brief_messages, intake_messages
from app.retrieve import NO_GUIDELINE
from app.router import ModelCallError
from app.store import Store

# Fields counted for the patient progress bar.
PROGRESS_FIELDS = (
    "reason_for_visit", "symptom", "lmp_date", "bleeding_pattern", "pregnancy_possible",
    "pregnant_or_postpartum", "contraception", "last_pap_hpv", "age_band", "medications",
)

# Deterministic next questions: used when the model's answer was unusable, or when a model
# reply is filtered for diagnosis language. One per required field, in this order.
_FALLBACK_QUESTIONS = (
    ("reason_for_visit", "What brings you in today?"),
    ("age_band", "Which age group are you in: 18-24, 25-29, 30-39, 40-49, 50-64, or 65 and over?"),
    ("pregnancy_possible", "Is there any chance you could be pregnant? You can say yes, no, or not sure."),
)
_FALLBACK_LAST = "Is there anything else you would like your care team to know?"
# Bloom text that counts as having asked a required field (model-worded or fixed).
_ASKED_RES = {
    "reason_for_visit": re.compile(r"brings you in|reason for (?:your|the|this) visit", re.I),
    "age_band": re.compile(r"\bage\b|how old|age group", re.I),
    "pregnancy_possible": re.compile(r"pregnan", re.I),
}
# After this many fallback turns in one session the intake is marked done.
FALLBACK_TURN_LIMIT = 4


class BloomState(TypedDict, total=False):
    session_id: str
    mode: str
    text: str  # this turn's patient message
    messages: list[dict]  # stored history before this turn: [{"role", "text"}]
    intake: dict
    red_flag: dict | None
    evidence_queries: list[str]
    evidence: list[dict]
    brief: dict | None
    brief_id: str | None
    status: str
    error: str | None
    # per-turn bookkeeping
    turn: int
    reply: str
    done: bool
    reply_filtered: bool
    urgent: dict | None
    resume_brief: bool
    parse_path: str | None  # first_pass | repair | fallback | rule
    brief_parse_path: str | None  # first_pass | repair | fallback
    asked_field: str | None  # required field the fixed fallback question asks
    force_done: bool  # fallback exhausted: finish even if a required field is unknown


class IntakeTurn(BaseModel):
    reply: str
    extracted: dict = {}
    done: bool = False


def urgent_payload(rule: RedFlagRule | str) -> dict:
    msg = safety.URGENT_MESSAGES[RedFlagRule(rule)]
    return {
        "rule_id": RedFlagRule(rule).value,
        "title": msg.title,
        "body": msg.body,
        "actions": [{"label": a.label, "tel": a.tel} for a in msg.actions],
        "support": msg.support,
    }


def merge_intake(rec: IntakeRecord, extracted: dict) -> IntakeRecord:
    """Merge a partial extraction field by field; a field that fails validation is skipped."""
    data = rec.model_dump(mode="json")
    if not isinstance(extracted, dict):
        return rec
    for key, value in extracted.items():
        if key not in IntakeRecord.model_fields or value is None or value == "" or value == []:
            continue
        if key == "symptom":
            if not isinstance(value, dict):
                continue
            value = {**(data.get("symptom") or {}), **{k: v for k, v in value.items() if v is not None}}
        elif key in ("medications", "allergies"):
            if isinstance(value, str):
                value = [value]
            if not isinstance(value, list):
                continue
            value = data[key] + [v for v in value if isinstance(v, str) and v not in data[key]]
        candidate = {**data, key: value}
        try:
            IntakeRecord.model_validate(candidate)
        except ValidationError:
            continue
        data = candidate
    return IntakeRecord.model_validate(data)


def progress(rec: IntakeRecord, status: str) -> float:
    if status != SessionStatus.IN_PROGRESS.value:
        return 1.0
    filled = sum(1 for f in PROGRESS_FIELDS if getattr(rec, f) not in (None, [], ""))
    return round(min(0.95, filled / len(PROGRESS_FIELDS)), 2)


def sanitize_brief(brief: Brief, evidence: list[EvidenceItem]) -> Brief:
    """Drop any citation URL that is not one of the retrieved passages."""
    allowed = {e.url for e in evidence}
    lines: list[ScreeningLine] = []
    for line in brief.screenings_possibly_due:
        if line.source_url is not None and line.source_url in allowed:
            lines.append(line)
        else:
            text = line.text if NO_GUIDELINE.lower() in line.text.lower() else f"{line.text} ({NO_GUIDELINE})"
            lines.append(ScreeningLine(text=text, source_url=None))
    if not evidence and not lines:
        lines.append(ScreeningLine(text=NO_GUIDELINE, source_url=None))
    return brief.model_copy(update={"screenings_possibly_due": lines})


# Model output that arrived but was not usable JSON. Anything else (HTTP errors,
# timeouts) still surfaces as 502 model_error.
_FORMAT_ERRORS = frozenset({"json_parse_failed", "schema_validation_failed"})
# The brief also falls back when the turn budget ran out (no call made) or the call timed
# out, so the final turn still ends in a reviewable draft. Refusals never fall back.
_BRIEF_FALLBACK_ERRORS = _FORMAT_ERRORS | {"turn_deadline_exceeded", "APITimeoutError"}


_AGE_RE = re.compile(r"\b(1[89]|[2-9]\d|1[01]\d)\b")
# "I'm 34", "I am 52", "aged 40", "34 years old": an age stated outright, asked or not.
_AGE_STATED_RE = re.compile(
    r"\b(?:i'?m|i am|aged?)\s+(1[89]|[2-9]\d|1[01]\d)\b(?!\s*(?:days?|weeks?|months?|%|years? (?:ago|since)))"
    r"|\b(1[89]|[2-9]\d|1[01]\d)\s*(?:years? old|yrs? old|y/?o)\b"
)
_BANDS = ((24, "18-24"), (29, "25-29"), (39, "30-39"), (49, "40-49"), (64, "50-64"))
_UNSURE_RE = re.compile(r"\b(not sure|unsure|maybe|don'?t know|do not know|no idea)\b")
_NO_RE = re.compile(
    r"\b(no|not|nope|never|can'?t|cannot|couldn'?t|isn'?t|don'?t think|do not think|unlikely)\b"
)
_YES_RE = re.compile(r"\b(yes|yeah|yep|possibly|could be|might be|i'?m pregnant|i am pregnant)\b")
_SHORT_ANSWER_WORDS = 8


def _band(age: int) -> str:
    return next((band for top, band in _BANDS if age <= top), "65+")


def _pregnancy_answer(text: str) -> str | None:
    low = text.lower().replace("’", "'")
    if _UNSURE_RE.search(low):
        return "unsure"
    if _NO_RE.search(low):
        return "no"
    if _YES_RE.search(low):
        return "yes"
    return None


def rule_extract(rec: IntakeRecord, last_bloom: str, text: str, first_patient: str | None = None) -> dict:
    """Deterministic fallback for the three fields an intake needs to finish, used only
    when the model's answer was unusable. Fills a field only if it is still missing, and
    only from what the patient said (never a guess).

    - reason_for_visit: the answer to "what brings you in", else the first patient message.
    - age_band: a number after an age question, or an age stated outright ("I'm 34").
    - pregnancy_possible: the answer to a pregnancy question when it mentions pregnancy or
      is short; otherwise a first-person sentence that mentions pregnancy.
    """
    out: dict = {}
    low = text.lower().replace("’", "'")
    asked = last_bloom.lower()
    if rec.reason_for_visit is None:
        if _ASKED_RES["reason_for_visit"].search(asked) and text.strip():
            out["reason_for_visit"] = text.strip()[:200]
        elif first_patient and first_patient.strip():
            out["reason_for_visit"] = first_patient.strip()[:200]
    if rec.age_band is None:
        stated = _AGE_STATED_RE.search(low)
        m = _AGE_RE.search(low) if _ASKED_RES["age_band"].search(asked) else None
        if stated:
            out["age_band"] = _band(int(stated.group(1) or stated.group(2)))
        elif m:
            out["age_band"] = _band(int(m.group(1)))
    if rec.pregnancy_possible is None:
        answer = None
        if "pregnan" in asked and ("pregnan" in low or len(low.split()) <= _SHORT_ANSWER_WORDS):
            answer = _pregnancy_answer(low)
        if answer is None:
            for sentence in re.split(r"[.!?;\n]+", low):
                if "pregnan" in sentence and re.search(r"\b(i|i'?m|me|my)\b", sentence):
                    answer = _pregnancy_answer(sentence)
                    if answer:
                        break
        if answer:
            out["pregnancy_possible"] = answer
    return out


def asked_fields(bloom_messages: list[dict]) -> set[str]:
    """Required fields Bloom has already asked about (fixed fallback or model wording)."""
    asked: set[str] = set()
    for m in bloom_messages:
        meta = m.get("meta") or {}
        if meta.get("asked_field"):
            asked.add(meta["asked_field"])
        for field, pattern in _ASKED_RES.items():
            if pattern.search(m.get("text") or ""):
                asked.add(field)
    return asked


def next_fallback_question(rec: IntakeRecord, asked: set[str]) -> tuple[str | None, str]:
    """(field, question) for the next required field that is missing and never asked,
    else (None, the closing "anything else" question)."""
    for field, question in _FALLBACK_QUESTIONS:
        if getattr(rec, field) is None and field not in asked:
            return field, question
    return None, _FALLBACK_LAST


_FIELD_LABELS = {
    "reason_for_visit": "Reason for visit", "lmp_date": "Last period started",
    "cycle_length_days": "Cycle length (days)", "bleeding_pattern": "Bleeding pattern",
    "pregnancy_possible": "Pregnancy possible", "pregnant_or_postpartum": "Pregnant or postpartum",
    "gravida": "Gravida", "para": "Para", "contraception": "Contraception",
    "last_pap_hpv": "Last Pap/HPV", "last_mammogram": "Last mammogram", "sti_concerns": "STI concerns",
    "medications": "Medications", "allergies": "Allergies", "age_band": "Age group",
    "other_notes": "Other notes",
}
_MISSING_QUESTIONS = {
    "reason_for_visit": "What brings you in today?",
    "age_band": "Which age group are you in?",
    "pregnancy_possible": "Is there any chance you could be pregnant?",
}
FALLBACK_BRIEF_LABEL = "DRAFT (automatic fallback, written without AI: the model's answer was unusable)."


def _fmt(value: Any) -> str:
    return ", ".join(str(v) for v in value) if isinstance(value, list) else str(value)


def fallback_brief(rec: IntakeRecord, evidence: list[EvidenceItem]) -> Brief:
    """A deterministic, clearly labelled DRAFT built only from the IntakeRecord and the
    retrieved passages. No model, no outside knowledge, no diagnosis. Screening lines
    point only at retrieved passages (for the physician to read), never at anything else."""
    data = rec.model_dump(mode="json")
    subj = [f"{_FIELD_LABELS[k]}: {_fmt(data[k])}" for k in (
        "reason_for_visit", "lmp_date", "cycle_length_days", "bleeding_pattern", "contraception",
        "medications", "allergies", "sti_concerns", "other_notes") if data.get(k) not in (None, "", [])]
    if rec.symptom is not None:
        sym = {k: v for k, v in rec.symptom.model_dump().items() if v is not None}
        if sym:
            subj.append("Symptom: " + "; ".join(f"{k.replace('_', ' ')} {v}" for k, v in sym.items()))
    obj = [f"{_FIELD_LABELS[k]}: {_fmt(data[k])}" for k in (
        "age_band", "pregnancy_possible", "pregnant_or_postpartum", "gravida", "para",
        "last_pap_hpv", "last_mammogram") if data.get(k) not in (None, "")]
    missing = [f for f in IntakeRecord.REQUIRED_FOR_DONE if getattr(rec, f) is None]
    flags = ["Built without AI from the patient's structured answers; verify every line before use."]
    flags += [f"{_FIELD_LABELS[f]} not recorded in the intake." for f in missing]
    lines = [
        ScreeningLine(text=f"Retrieved guideline passage for physician review: {e.title or e.query}",
                      source_url=e.url)
        for e in evidence
    ] or [ScreeningLine(text=NO_GUIDELINE, source_url=None)]
    return Brief(
        subjective=f"{FALLBACK_BRIEF_LABEL} Patient-reported: " + ("; ".join(subj) if subj else "nothing recorded") + ".",
        objective="Patient-reported structured data only; no exam has happened. "
        + ("; ".join(obj) if obj else "No structured data recorded") + ".",
        assessment_considerations=f"{FALLBACK_BRIEF_LABEL} No assessment was drafted. Physician to evaluate.",
        plan_considerations=f"{FALLBACK_BRIEF_LABEL} No plan was drafted. Physician to decide; "
        "review any retrieved guideline passages listed below.",
        flags=flags,
        screenings_possibly_due=lines,
        suggested_questions=[_MISSING_QUESTIONS[f] for f in missing],
    )


@dataclass
class TurnResult:
    session_id: str
    reply: str
    status: str
    progress: float
    urgent: dict | None = None
    done: bool = False
    brief_id: str | None = None
    # How this turn's model output was obtained (see module docstring); None if no intake ran.
    parse_path: str | None = None
    brief_parse_path: str | None = None


class SessionLocked(Exception):
    """The session is urgent-locked or finished; no more patient messages."""


class SessionNotFound(Exception):
    pass


class BloomGraph:
    def __init__(self, settings: Settings, store: Store, router: Any, retriever: Any):
        """router: ModelRouter (or a test double with the same ``complete``).
        retriever: anything with ``search_with_event(query) -> (list[EvidenceItem], dict)``."""
        self.settings = settings
        self.store = store
        self.router = router
        self.retriever = retriever
        self._locks: dict[str, threading.Lock] = {}
        self._locks_guard = threading.Lock()
        self.graph = self._build()

    # ------------------------------------------------------------------ nodes

    def _safety_pre(self, s: BloomState) -> dict:
        rec = IntakeRecord.model_validate(s["intake"])
        patient_texts = [m["text"] for m in s["messages"] if m["role"] == "patient"] + [s["text"]]
        # S9-style rules span turns, so the joined session text is checked too.
        hit = safety.check_text(s["text"], rec) or safety.check_text(" . ".join(patient_texts), rec)
        return {"red_flag": hit.model_dump(mode="json") if hit else None}

    def _intake(self, s: BloomState) -> dict:
        rec = IntakeRecord.model_validate(s["intake"])
        history = s["messages"] + [{"role": "patient", "text": s["text"]}]
        msgs = intake_messages(history, rec, s["turn"])
        bloom_msgs = [m for m in s["messages"] if m["role"] == "bloom"]
        asked = asked_fields(bloom_msgs)
        asked_field: str | None = None
        force_done = False
        try:
            parsed, event = self._complete_validated(
                msgs, IntakeTurn, node="intake", session_id=s["session_id"], with_event=True
            )
            parse_path = event.evidence.get("parse_path", "first_pass")
        except ModelCallError as exc:
            # The model answered, but not in the JSON shape, even after the repair call.
            # The error TrustEvents are already stored. Deterministic turn instead of a
            # 502; no other model is called. HTTP errors and timeouts still raise.
            error = exc.event.evidence.get("error")
            if error not in _FORMAT_ERRORS or not self.settings.bloom_deterministic_fallback:
                raise
            parse_path = "fallback"
            self.store.audit("system", "intake_fallback_question", s["session_id"])
            last_bloom = bloom_msgs[-1]["text"] if bloom_msgs else ""
            first_patient = next((m["text"] for m in history if m["role"] == "patient"), None)
            fields = rule_extract(rec, last_bloom, s["text"], first_patient=first_patient)
            filled = merge_intake(rec, fields)
            asked_field, question = next_fallback_question(filled, asked)
            fallback_turns = 1 + sum(1 for m in bloom_msgs if (m.get("meta") or {}).get("parse_path") == "fallback")
            force_done = filled.is_complete() or asked_field is None or fallback_turns >= FALLBACK_TURN_LIMIT
            parsed = IntakeTurn(reply=question, extracted=fields, done=force_done)
            self.store.record_trust_event(TrustEvent(
                session_id=s["session_id"], node="intake_fallback", mode=s["mode"], model_id=None,
                policy_required="no_model_call", outcome=TrustOutcome.OK,
                evidence={"parse_path": "fallback", "after_error": error, "no_model_call": True,
                          "fields_filled": sorted(fields), "asks": asked_field, "done": force_done,
                          "fallback_turn": fallback_turns},
            ))
        merged = merge_intake(rec, parsed.extracted)
        filter_field, filter_question = next_fallback_question(merged, asked)
        reply, filtered = safety.filter_patient_reply(parsed.reply.strip(), filter_question)
        if filtered:
            asked_field = filter_field
            self.store.audit("system", "reply_filtered", s["session_id"])
        return {
            "intake": merged.model_dump(mode="json"),
            "reply": reply,
            "done": parsed.done,
            "reply_filtered": filtered,
            "parse_path": parse_path,
            "asked_field": asked_field,
            "force_done": force_done,
        }

    def _safety_post(self, s: BloomState) -> dict:
        hit = safety.check_fields(IntakeRecord.model_validate(s["intake"]))
        return {"red_flag": hit.model_dump(mode="json") if hit else None}

    def _urgent(self, s: BloomState) -> dict:
        """Lock the session. Fixed message only; no model call on this path."""
        sid = s["session_id"]
        hit = RedFlagHit.model_validate(s["red_flag"])
        payload = urgent_payload(hit.rule_id)
        self.store.add_message(sid, "patient", s["text"])
        self.store.add_message(sid, "bloom", payload["body"], meta={"parse_path": s.get("parse_path") or "rule"})
        self.store.save_intake(sid, IntakeRecord.model_validate(s["intake"]))
        self.store.add_red_flag(sid, hit)
        self.store.set_status(sid, SessionStatus.URGENT)
        self.store.audit("system", "red_flag_locked", sid)
        return {"status": SessionStatus.URGENT.value, "reply": payload["body"], "urgent": payload,
                "parse_path": s.get("parse_path") or "rule"}

    def _save_turn(self, s: BloomState) -> dict:
        sid = s["session_id"]
        rec = IntakeRecord.model_validate(s["intake"])
        final = (s.get("done") and (rec.is_complete() or s.get("force_done"))) or s["turn"] >= MAX_TURNS
        reply = CLOSING_MESSAGE if final else s["reply"]
        meta = {
            "extracted": rec.model_dump(mode="json", exclude_none=True, exclude_defaults=True),
            "done": bool(final),
            "parse_path": s.get("parse_path"),
            "asked_field": None if final else s.get("asked_field"),
        }
        self.store.add_message(sid, "patient", s["text"])
        self.store.add_message(sid, "bloom", reply, meta=meta)
        self.store.save_intake(sid, rec, completed=bool(final))
        if final:
            self.store.audit("system", "intake_completed", sid)
        return {"reply": reply, "done": bool(final)}

    def _deidentify(self, s: BloomState) -> dict:
        rec = IntakeRecord.model_validate(s["intake"])
        try:
            queries = build_queries(rec)
        except Exception:  # a bad query is never sent; brief says "No guideline retrieved"
            queries = []
        return {"evidence_queries": queries, "reply": CLOSING_MESSAGE, "done": True}

    def _retrieve(self, s: BloomState) -> dict:
        sid = s["session_id"]
        seen: set[str] = set()
        items: list[EvidenceItem] = []
        for q in s.get("evidence_queries") or []:
            found, event = self.retriever.search_with_event(q)
            self.store.record_trust_event(TrustEvent(**{**event, "session_id": sid, "mode": s["mode"]}))
            for it in found:
                if it.url not in seen:
                    seen.add(it.url)
                    items.append(it)
        if items:
            self.store.add_evidence(sid, items)
        return {"evidence": [i.model_dump(mode="json") for i in items]}

    def _brief(self, s: BloomState) -> dict:
        sid = s["session_id"]
        rec = IntakeRecord.model_validate(s["intake"])
        evidence = [EvidenceItem.model_validate(e) for e in s.get("evidence") or []]
        msgs = brief_messages(rec, evidence)
        try:
            brief, event = self._complete_validated(msgs, Brief, node="brief", session_id=sid, with_event=True)
        except ModelCallError as exc:
            error = exc.event.evidence.get("error")
            if error not in _BRIEF_FALLBACK_ERRORS or not self.settings.bloom_deterministic_fallback:
                raise
            brief = fallback_brief(rec, evidence)
            provenance = Provenance(
                generated_by=f"deterministic-fallback ({s['mode']})",
                evidence_urls=[e.url for e in evidence], source="fallback",
            )
            self.store.record_trust_event(TrustEvent(
                session_id=sid, node="brief_fallback", mode=s["mode"], model_id=None,
                policy_required="no_model_call", outcome=TrustOutcome.OK,
                evidence={"parse_path": "fallback", "after_error": error, "no_model_call": True,
                          "citations": len([x for x in brief.screenings_possibly_due if x.source_url])},
            ))
            path = "fallback"
            self.store.audit("system", "brief_fallback_draft", sid)
        else:
            brief = sanitize_brief(brief, evidence)
            provenance = Provenance(
                generated_by=f"{event.model_id or 'unknown-model'} ({event.mode})",
                evidence_urls=[e.url for e in evidence],
            )
            path = event.evidence.get("parse_path", "first_pass")
        bid = self.store.save_brief(sid, brief, provenance)
        self.store.set_status(sid, SessionStatus.READY)
        self.store.audit("system", "brief_generated", sid)
        return {"brief": brief.model_dump(mode="json"), "brief_id": bid, "status": SessionStatus.READY.value,
                "brief_parse_path": path}

    # ---------------------------------------------------------------- helpers

    def _complete_validated(
        self, msgs: list[dict], model: type[BaseModel], *, node: str, session_id: str, with_event: bool = False
    ):
        """One model call, plus (dev mode only) one repair call inside the router if the
        output is not JSON or does not match ``model``.

        Refusals (ConfidentialRouteUnavailable) propagate immediately: no retry, no fallback.
        """
        text, event = self.router.complete(
            msgs, node=node, session_id=session_id, json_mode=True, validate=model.model_validate_json
        )
        value = model.model_validate_json(text)
        return (value, event) if with_event else value

    # ------------------------------------------------------------------ graph

    def _build(self):
        g = StateGraph(BloomState)
        g.add_node("safety_pre", self._safety_pre)
        g.add_node("intake", self._intake)
        g.add_node("safety_post", self._safety_post)
        g.add_node("urgent", self._urgent)
        g.add_node("save_turn", self._save_turn)
        g.add_node("deidentify", self._deidentify)
        g.add_node("retrieve", self._retrieve)
        g.add_node("brief", self._brief)

        g.add_conditional_edges(
            START, lambda s: "deidentify" if s.get("resume_brief") else "safety_pre",
            {"deidentify": "deidentify", "safety_pre": "safety_pre"},
        )
        hit_or: Callable[[str], Callable[[BloomState], str]] = (
            lambda nxt: lambda s: "urgent" if s.get("red_flag") else nxt
        )
        g.add_conditional_edges("safety_pre", hit_or("intake"), {"urgent": "urgent", "intake": "intake"})
        g.add_edge("intake", "safety_post")
        g.add_conditional_edges("safety_post", hit_or("save_turn"), {"urgent": "urgent", "save_turn": "save_turn"})
        g.add_conditional_edges(
            "save_turn", lambda s: "deidentify" if s.get("done") else END, {"deidentify": "deidentify", END: END}
        )
        g.add_edge("deidentify", "retrieve")
        g.add_edge("retrieve", "brief")
        g.add_edge("brief", END)
        g.add_edge("urgent", END)
        return g.compile()

    # ----------------------------------------------------------------- public

    def _lock(self, session_id: str) -> threading.Lock:
        with self._locks_guard:
            return self._locks.setdefault(session_id, threading.Lock())

    def run_turn(self, session_id: str, text: str, client_message_id: str | None = None) -> TurnResult:
        """Run one patient turn. Raises SessionNotFound, SessionLocked,
        ConfidentialRouteUnavailable or ModelCallError.

        With ``client_message_id``, a resend of a turn that already succeeded returns the
        stored result (nothing is appended, no model call). The per-session lock makes a
        resend that arrives while the first request is still running wait for it.
        """
        with self._lock(session_id):
            session = self.store.get_session(session_id)
            if session is None:
                raise SessionNotFound(session_id)
            if client_message_id:
                stored = self.store.get_turn_result(session_id, client_message_id)
                if stored is not None:
                    return TurnResult(**stored)
            if session["status"] != SessionStatus.IN_PROGRESS.value:
                raise SessionLocked(session["status"])
            rec, completed_at = self.store.get_intake(session_id)
            history = [{"role": m["role"], "text": m["text"], "meta": m.get("meta")}
                       for m in self.store.get_messages(session_id)]
            turn = sum(1 for m in history if m["role"] == "patient") + 1
            self.store.audit("patient", "message_received", session_id)
            state: BloomState = {
                "session_id": session_id,
                "mode": session["mode"],
                "text": text,
                "messages": history,
                "intake": rec.model_dump(mode="json"),
                "red_flag": None,
                "evidence_queries": [],
                "evidence": [],
                "brief": None,
                "brief_id": None,
                "status": session["status"],
                "error": None,
                "turn": turn,
                "reply": "",
                "done": False,
                "urgent": None,
                "resume_brief": completed_at is not None,
                "parse_path": None,
                "brief_parse_path": None,
                "asked_field": None,
                "force_done": False,
            }
            deadline = getattr(self.router, "deadline", None)
            with deadline(self.settings.turn_budget_s) if deadline else contextlib.nullcontext():
                out = self.graph.invoke(state)
            status = out.get("status") or session["status"]
            final_rec = IntakeRecord.model_validate(out["intake"])
            result = TurnResult(
                session_id=session_id,
                reply=out.get("reply") or "",
                status=status,
                progress=progress(final_rec, status),
                urgent=out.get("urgent"),
                done=status != SessionStatus.IN_PROGRESS.value,
                brief_id=out.get("brief_id"),
                parse_path=out.get("parse_path"),
                brief_parse_path=out.get("brief_parse_path"),
            )
            if client_message_id:
                self.store.save_turn_result(session_id, client_message_id, dataclasses.asdict(result))
            return result
