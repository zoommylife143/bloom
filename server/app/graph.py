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

Safety:
- The urgent path never calls a model; it returns the fixed ``URGENT_MESSAGES`` text.
- ``ConfidentialRouteUnavailable`` and ``ModelCallError`` propagate out of ``run_turn``
  unchanged. Nothing is retried or sent to another model, the session status is not
  changed, and the API maps them to 502.
- Every patient-facing model reply passes ``safety.filter_patient_reply``.
"""

from __future__ import annotations

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

# Fallback next questions when a model reply is filtered for diagnosis language.
_FALLBACK_QUESTIONS = (
    ("reason_for_visit", "What brings you in today?"),
    ("age_band", "Which age group are you in: 18-24, 25-29, 30-39, 40-49, 50-64, or 65 and over?"),
    ("pregnancy_possible", "Is there any chance you could be pregnant? You can say yes, no, or not sure."),
)
_FALLBACK_LAST = "Is there anything else you would like your care team to know?"


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


def _fallback_question(rec: IntakeRecord) -> str:
    for field, question in _FALLBACK_QUESTIONS:
        if getattr(rec, field) is None:
            return question
    return _FALLBACK_LAST


@dataclass
class TurnResult:
    session_id: str
    reply: str
    status: str
    progress: float
    urgent: dict | None = None
    done: bool = False
    brief_id: str | None = None


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
        parsed = self._complete_validated(msgs, IntakeTurn, node="intake", session_id=s["session_id"])
        merged = merge_intake(rec, parsed.extracted)
        reply, filtered = safety.filter_patient_reply(parsed.reply.strip(), _fallback_question(merged))
        if filtered:
            self.store.audit("system", "reply_filtered", s["session_id"])
        return {
            "intake": merged.model_dump(mode="json"),
            "reply": reply,
            "done": parsed.done,
            "reply_filtered": filtered,
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
        self.store.add_message(sid, "bloom", payload["body"])
        self.store.save_intake(sid, IntakeRecord.model_validate(s["intake"]))
        self.store.add_red_flag(sid, hit)
        self.store.set_status(sid, SessionStatus.URGENT)
        self.store.audit("system", "red_flag_locked", sid)
        return {"status": SessionStatus.URGENT.value, "reply": payload["body"], "urgent": payload}

    def _save_turn(self, s: BloomState) -> dict:
        sid = s["session_id"]
        rec = IntakeRecord.model_validate(s["intake"])
        final = (s.get("done") and rec.is_complete()) or s["turn"] >= MAX_TURNS
        reply = CLOSING_MESSAGE if final else s["reply"]
        self.store.add_message(sid, "patient", s["text"])
        self.store.add_message(sid, "bloom", reply)
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
        brief, event = self._complete_validated(
            msgs, Brief, node="brief", session_id=sid, with_event=True
        )
        brief = sanitize_brief(brief, evidence)
        provenance = Provenance(
            generated_by=f"{event.model_id or 'unknown-model'} ({event.mode})",
            evidence_urls=[e.url for e in evidence],
        )
        bid = self.store.save_brief(sid, brief, provenance)
        self.store.set_status(sid, SessionStatus.READY)
        self.store.audit("system", "brief_generated", sid)
        return {"brief": brief.model_dump(mode="json"), "brief_id": bid, "status": SessionStatus.READY.value}

    # ---------------------------------------------------------------- helpers

    def _complete_validated(
        self, msgs: list[dict], model: type[BaseModel], *, node: str, session_id: str, with_event: bool = False
    ):
        """One model call; one more only in dev mode if the JSON has the wrong shape.

        Refusals (ConfidentialRouteUnavailable) propagate immediately: no retry, no fallback.
        """
        attempts = 2 if self.settings.bloom_mode == "dev" else 1
        last_event: TrustEvent | None = None
        for _ in range(attempts):
            text, event = self.router.complete(msgs, node=node, session_id=session_id, json_mode=True)
            last_event = event
            try:
                value = model.model_validate_json(text)
            except ValidationError:
                continue
            return (value, event) if with_event else value
        bad = last_event.model_copy(update={  # type: ignore[union-attr]
            "outcome": TrustOutcome.ERROR, "evidence": {**last_event.evidence, "error": "schema_validation_failed"},  # type: ignore[union-attr]
        })
        self.store.record_trust_event(bad)
        raise ModelCallError(bad, f"{node} output did not match the expected schema")

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

    def run_turn(self, session_id: str, text: str) -> TurnResult:
        """Run one patient turn. Raises SessionNotFound, SessionLocked,
        ConfidentialRouteUnavailable or ModelCallError."""
        with self._lock(session_id):
            session = self.store.get_session(session_id)
            if session is None:
                raise SessionNotFound(session_id)
            if session["status"] != SessionStatus.IN_PROGRESS.value:
                raise SessionLocked(session["status"])
            rec, completed_at = self.store.get_intake(session_id)
            history = [{"role": m["role"], "text": m["text"]} for m in self.store.get_messages(session_id)]
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
            }
            out = self.graph.invoke(state)
            status = out.get("status") or session["status"]
            final_rec = IntakeRecord.model_validate(out["intake"])
            return TurnResult(
                session_id=session_id,
                reply=out.get("reply") or "",
                status=status,
                progress=progress(final_rec, status),
                urgent=out.get("urgent"),
                done=status != SessionStatus.IN_PROGRESS.value,
                brief_id=out.get("brief_id"),
            )
