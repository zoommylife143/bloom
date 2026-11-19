"""Graph + store + API tests (agent 05). Offline.

The real ModelRouter is used with an OpenAI client whose httpx2 transport is a
scripted fake gateway (respx cannot patch httpx2), so every model call is counted at
the HTTP level. Retrieval uses a fake retriever. Synthetic data only.
"""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

import httpx2
import pytest
from fastapi.testclient import TestClient
from openai import OpenAI

from app.config import Settings
from app.graph import merge_intake, sanitize_brief
from app.main import build_services, create_app, make_token
from app.models import Brief, EvidenceItem, IntakeRecord, ScreeningLine, TrustOutcome
from app.prompts import BRIEF_SYSTEM_PROMPT, INTAKE_SYSTEM_PROMPT, OPENING_QUESTION
from app.retrieve import GuidelineRetriever
from app.router import ModelRouter
from app.store import Store

BASE = "https://tr.test/v1"
SCENARIO_DIR = Path(__file__).resolve().parents[2] / "scenarios"
BRIEF_IDS = ["S1", "S2", "S3", "S4", "S5"]
URGENT = {"S6": "R1", "S7": "R2", "S8": "R3", "S9": "R4", "S10": "R5"}
BOGUS_URL = "https://example.invalid/not-a-passage"
PLANTED = "zebra umbrella forty two"  # synthetic planted clinical phrase
REFUSAL_400 = {"error": {"type": "bad_request", "code": "confidential_privacy_required",
                         "message": "No route meets min_privacy=confidential"}}


def load(sid: str) -> dict:
    return json.loads((SCENARIO_DIR / f"{sid}.json").read_text(encoding="utf-8"))


def _completion(content: str) -> dict:
    return {
        "id": "gen-test", "object": "chat.completion", "created": 1, "model": "fortanix/glm-5.3-flash",
        "choices": [{"index": 0, "message": {"role": "assistant", "content": content}, "finish_reason": "stop"}],
    }


class Gateway:
    """Scripted TrustedRouter stand-in. Decides by system prompt which node is calling."""

    def __init__(self, *, turns: int = 8, fields: dict | None = None, refuse: set[str] | None = None,
                 refuse_once: set[str] | None = None, intake_replies: list | None = None,
                 brief_override: dict | None = None):
        self.turns = turns
        self.fields = fields or {}
        self.refuse = refuse or set()
        self.refuse_once = set(refuse_once or set())
        self.intake_replies = list(intake_replies or [])
        self.brief_override = brief_override
        self.calls: list[str] = []  # node per HTTP call

    def __call__(self, request: httpx2.Request) -> httpx2.Response:
        body = json.loads(request.content)
        msgs = body["messages"]
        system = msgs[0]["content"]
        node = "intake" if system == INTAKE_SYSTEM_PROMPT else "brief" if system == BRIEF_SYSTEM_PROMPT else "other"
        self.calls.append(node)
        if node in self.refuse or node in self.refuse_once or node == "other":
            self.refuse_once.discard(node)
            return httpx2.Response(400, json=REFUSAL_400)
        if node == "intake":
            if self.intake_replies:
                return httpx2.Response(200, json=_completion(self.intake_replies.pop(0)))
            turn = sum(1 for m in msgs if m["role"] == "user")
            out = {"reply": f"Thanks. Question number {turn + 1}?", "extracted": self.fields,
                   "done": turn >= self.turns}
            return httpx2.Response(200, json=_completion(json.dumps(out)))
        urls = re.findall(r"URL: (\S+)", msgs[1]["content"])
        brief = self.brief_override or {
            "subjective": "Patient reports a routine visit request.",
            "objective": "Patient-reported data only; no exam yet.",
            "assessment_considerations": "Physician to consider cervical screening interval and irregular cycles.",
            "plan_considerations": "Consider screening per guideline.",
            "flags": [],
            "screenings_possibly_due": (
                [{"text": "Cervical screening may be due", "source_url": urls[0]}] if urls else []
            ) + [{"text": "Uncited screening line", "source_url": BOGUS_URL}],
            "suggested_questions": ["When was your last screening?"],
        }
        return httpx2.Response(200, json=_completion(json.dumps(brief)))

    def count(self, node: str | None = None) -> int:
        return len(self.calls) if node is None else self.calls.count(node)


class FakeRetriever:
    def __init__(self, empty: bool = False):
        self.empty = empty
        self.queries: list[str] = []

    def search_with_event(self, query: str):
        self.queries.append(query)
        event = {"node": "retrieve", "route": "context.dev", "policy_required": "deidentified_query",
                 "model_id": None, "request_id": "ctx-test", "latency_ms": 1, "outcome": "ok",
                 "evidence": {"cache": "fixture", "result_count": 0 if self.empty else 1}}
        if self.empty:
            return [], event
        h = hashlib.sha256(query.encode()).hexdigest()[:8]
        return [EvidenceItem(query=query, url=f"https://www.acog.org/guidance/{h}", title="Synthetic guidance",
                             passage="Synthetic guideline passage for tests.")], event


def _settings(**kw) -> Settings:
    base = dict(bloom_mode="dev", trustedrouter_api_key="test-key", trustedrouter_base_url=BASE,
                private_model_id="", demo_login_secret="test-secret", database_url="sqlite:///:memory:")
    base.update(kw)
    return Settings(**base)


class Harness:
    def __init__(self, gw: Gateway, *, retriever=None, **settings_kw):
        self.gw = gw
        self.settings = _settings(**settings_kw)
        self.store = Store(":memory:")
        client = OpenAI(api_key="test-key", base_url=BASE, http_client=httpx2.Client(transport=httpx2.MockTransport(gw)))
        router = ModelRouter(self.settings, client=client, on_event=self.store.record_trust_event)
        self.services = build_services(self.settings, store=self.store, router=router,
                                       retriever=retriever or FakeRetriever(),
                                       attestation_fn=lambda: {"status": "unavailable", "verified_claims": False})
        self.client = TestClient(create_app(self.services))
        self.patient = {"Authorization": f"Bearer {make_token(self.services.secret, 'patient')[0]}"}
        self.doctor = {"Authorization": f"Bearer {make_token(self.services.secret, 'doctor')[0]}"}

    def new_session(self, scenario_id=None) -> str:
        res = self.client.post("/api/sessions", json={"scenario_id": scenario_id}, headers=self.patient)
        assert res.status_code == 200, res.text
        assert res.json()["reply"] == OPENING_QUESTION
        return res.json()["session_id"]

    def say(self, sid: str, text: str):
        return self.client.post(f"/api/sessions/{sid}/messages", json={"text": text}, headers=self.patient)

    def run(self, turns: list[str], sid: str | None = None):
        sid = sid or self.new_session()
        last = None
        for i, t in enumerate(turns):
            last = self.say(sid, t)
            assert last.status_code == 200, last.text
            if last.json()["done"]:
                return sid, last, i + 1
        return sid, last, len(turns)

    def dump(self, table: str) -> str:
        return json.dumps([dict(r) for r in self.store.conn.execute(f"SELECT * FROM {table}")], default=str)


def _fields(sid: str) -> dict:
    return {**(load(sid).get("expected_fields") or {}), "reason_for_visit": "routine gynecology visit"}


# ------------------------------------------------------------------ scenario harness


@pytest.mark.parametrize("sid", BRIEF_IDS)
def test_brief_scenarios_reach_a_brief(sid):
    s = load(sid)
    h = Harness(Gateway(turns=len(s["turns"]), fields=_fields(sid)))
    session, last, used = h.run(s["turns"])
    body = last.json()
    assert body["status"] == "ready" and body["done"] and body["progress"] == 1.0
    assert body["urgent"] is None
    assert used <= 12
    assert h.gw.count("brief") == 1
    brief = h.client.get(f"/api/sessions/{session}/brief", headers=h.doctor)
    assert brief.status_code == 200
    data = brief.json()
    assert data["provenance"]["review_status"] == "draft"
    assert data["provenance"]["generated_by"].endswith("(dev)")
    urls = {e["url"] for e in data["evidence"]}
    for line in data["brief"]["screenings_possibly_due"]:
        assert line["source_url"] is None or line["source_url"] in urls
    # The finished session takes no more messages.
    assert h.say(session, "one more thing").status_code == 409


@pytest.mark.parametrize("sid", list(URGENT))
def test_urgent_scenarios_lock(sid):
    s = load(sid)
    h = Harness(Gateway(turns=99, fields=_fields(sid)))
    session, last, used = h.run(s["turns"])
    body = last.json()
    assert body["status"] == "urgent" and body["done"]
    assert body["urgent"]["rule_id"] == URGENT[sid]
    assert body["reply"] == body["urgent"]["body"]
    assert h.gw.count("brief") == 0
    flag = h.client.get(f"/api/sessions/{session}/flag", headers=h.doctor).json()
    assert flag["rule_id"] == URGENT[sid]
    if flag["source"] == "text":  # caught before the model: no call on the urgent turn
        assert h.gw.count("intake") == used - 1
    calls = h.gw.count()
    assert h.say(session, "hello?").status_code == 409
    assert h.gw.count() == calls


def test_s9_spans_turns():
    """Postpartum (turn 1) + headache/vision (turn 3) with no extracted fields still fires R4."""
    s = load("S9")
    h = Harness(Gateway(turns=99, fields={}))
    _, last, used = h.run(s["turns"])
    assert last.json()["urgent"]["rule_id"] == "R4" and used == 3


# ----------------------------------------------------------------------------- refusal


def test_private_refusal_returns_502_after_one_call():
    h = Harness(Gateway(refuse={"intake", "brief"}), bloom_mode="private", private_model_id="conf/model")
    sid = h.new_session()
    res = h.say(sid, "I'd like a checkup.")
    assert res.status_code == 502
    assert res.json()["error"] == "confidential_route_unavailable"
    assert h.gw.count() == 1
    events = h.store.list_trust_events(sid)
    assert [e.outcome for e in events] == [TrustOutcome.REFUSED]
    assert h.store.get_session(sid)["status"] == "in_progress"
    assert h.store.get_messages(sid) == h.store.get_messages(sid)[:1]  # only the opening question


def test_private_mode_without_model_makes_no_call():
    h = Harness(Gateway(), bloom_mode="private", private_model_id="")
    sid = h.new_session()
    res = h.say(sid, "I'd like a checkup.")
    assert res.status_code == 502 and res.json()["error"] == "confidential_route_unavailable"
    assert h.gw.count() == 0


def test_brief_refusal_then_resume():
    s = load("S1")
    h = Harness(Gateway(turns=len(s["turns"]), fields=_fields("S1"), refuse_once={"brief"}))
    sid = h.new_session()
    for t in s["turns"][:-1]:
        assert h.say(sid, t).status_code == 200
    res = h.say(sid, s["turns"][-1])
    assert res.status_code == 502 and res.json()["error"] == "confidential_route_unavailable"
    assert h.gw.count("brief") == 1  # no retry, no other model
    assert h.store.get_session(sid)["status"] == "in_progress"
    assert h.client.get(f"/api/sessions/{sid}/brief", headers=h.doctor).status_code == 404
    intake_calls = h.gw.count("intake")
    res = h.say(sid, "retry")
    assert res.status_code == 200 and res.json()["status"] == "ready"
    assert h.gw.count("intake") == intake_calls  # resumed straight at the brief


# ------------------------------------------------------------------------------- brief


def test_brief_drops_uncited_urls():
    s = load("S1")
    h = Harness(Gateway(turns=len(s["turns"]), fields=_fields("S1")))
    sid, _, _ = h.run(s["turns"])
    data = h.client.get(f"/api/sessions/{sid}/brief", headers=h.doctor).json()
    lines = data["brief"]["screenings_possibly_due"]
    assert all(line["source_url"] != BOGUS_URL for line in lines)
    assert any(line["source_url"] is None and "No guideline retrieved" in line["text"] for line in lines)
    assert any(line["source_url"] for line in lines)
    assert BOGUS_URL not in h.dump("briefs")


def test_no_evidence_says_no_guideline_retrieved(tmp_path):
    s = load("S1")
    retriever = GuidelineRetriever(_settings(context_dev_api_key=""), cache_dir=tmp_path)  # no key, empty cache
    h = Harness(Gateway(turns=len(s["turns"]), fields=_fields("S1")), retriever=retriever)
    sid, last, _ = h.run(s["turns"])
    assert last.json()["status"] == "ready"
    data = h.client.get(f"/api/sessions/{sid}/brief", headers=h.doctor).json()
    assert data["evidence"] == []
    lines = data["brief"]["screenings_possibly_due"]
    assert lines and all(line["source_url"] is None and "No guideline retrieved" in line["text"] for line in lines)
    retrieve_events = [e for e in h.store.list_trust_events(sid) if e.node == "retrieve"]
    assert retrieve_events and all(e.session_id == sid and e.mode == "dev" for e in retrieve_events)


def test_sanitize_brief_unit():
    ev = [EvidenceItem(query="q", url="https://www.acog.org/a", passage="p")]
    b = Brief(subjective="s", objective="o", assessment_considerations="a", plan_considerations="p",
              screenings_possibly_due=[ScreeningLine(text="ok", source_url="https://www.acog.org/a"),
                                       ScreeningLine(text="bad", source_url="https://evil.test/x")])
    out = sanitize_brief(b, ev).screenings_possibly_due
    assert out[0].source_url == "https://www.acog.org/a"
    assert out[1].source_url is None and "No guideline retrieved" in out[1].text
    empty = sanitize_brief(b.model_copy(update={"screenings_possibly_due": []}), [])
    assert empty.screenings_possibly_due == [ScreeningLine(text="No guideline retrieved", source_url=None)]


# ---------------------------------------------------------------------------- decision


def _ready_session(h: Harness) -> tuple[str, str]:
    s = load("S1")
    sid, last, _ = h.run(s["turns"])
    assert last.json()["status"] == "ready"
    return sid, h.client.get(f"/api/sessions/{sid}/brief", headers=h.doctor).json()["brief_id"]


@pytest.mark.parametrize(("decision", "status"), [("approve", "approved"), ("reject", "rejected"), ("edit", "edited")])
def test_decisions(decision, status):
    h = Harness(Gateway(turns=len(load("S1")["turns"]), fields=_fields("S1")))
    sid, bid = _ready_session(h)
    original = h.client.get(f"/api/sessions/{sid}/brief", headers=h.doctor).json()["brief"]
    payload = {"decision": decision, "reviewer": "Dr. Demo"}
    if decision == "edit":
        payload["edited"] = {**original, "plan_considerations": "Edited by physician."}
    res = h.client.post(f"/api/briefs/{bid}/decision", json=payload, headers=h.doctor)
    assert res.status_code == 200, res.text
    data = res.json()
    assert data["provenance"]["review_status"] == status
    assert data["provenance"]["reviewed_by"] == "Dr. Demo" and data["provenance"]["reviewed_at"]
    assert data["original_brief"] == original
    if decision == "edit":
        assert data["edited"] and data["brief"]["plan_considerations"] == "Edited by physician."
    assert h.store.get_session(sid)["status"] == status
    again = h.client.post(f"/api/briefs/{bid}/decision", json={"decision": "approve", "reviewer": "x"}, headers=h.doctor)
    assert again.status_code == 409 and again.json()["error"] == "already_decided"


def test_edit_without_brief_is_rejected():
    h = Harness(Gateway(turns=len(load("S1")["turns"]), fields=_fields("S1")))
    _, bid = _ready_session(h)
    res = h.client.post(f"/api/briefs/{bid}/decision", json={"decision": "edit", "reviewer": "Dr. Demo"}, headers=h.doctor)
    assert res.status_code == 422
    assert h.client.post("/api/briefs/nope/decision", json={"decision": "approve", "reviewer": "x"},
                         headers=h.doctor).status_code == 404


# ------------------------------------------------------------------------- audit grep


def test_planted_phrase_never_reaches_audit_or_trust():
    s = load("S1")
    turns = [s["turns"][0] + f" Also {PLANTED}."] + s["turns"][1:]
    fields = {**_fields("S1"), "other_notes": PLANTED}
    h = Harness(Gateway(turns=len(turns), fields=fields))
    sid, last, _ = h.run(turns)
    assert last.json()["status"] == "ready"
    h.client.get(f"/api/sessions/{sid}/brief", headers=h.doctor)
    assert PLANTED in h.dump("messages")
    assert PLANTED in h.dump("intake_records")
    assert PLANTED not in h.dump("audit_log")
    assert PLANTED not in h.dump("trust_events")
    assert PLANTED not in h.client.get("/api/audit", headers=h.doctor).text
    assert PLANTED not in h.client.get(f"/api/sessions/{sid}/trust", headers=h.doctor).text
    assert all(PLANTED not in q for q in h.services.retriever.queries)


# -------------------------------------------------------------------------------- auth


DOCTOR_ROUTES = [
    ("get", "/api/sessions", None),
    ("get", "/api/sessions/x/brief", None),
    ("post", "/api/briefs/x/decision", {"decision": "approve", "reviewer": "x"}),
    ("get", "/api/sessions/x/trust", None),
    ("get", "/api/sessions/x/flag", None),
    ("get", "/api/audit", None),
    ("post", "/api/demo/negative-test", {}),
    ("post", "/api/demo/scenarios/S1/run", None),
]


@pytest.mark.parametrize(("method", "path", "body"), DOCTOR_ROUTES)
def test_doctor_routes_reject_patient_and_anonymous(method, path, body):
    h = Harness(Gateway())
    call = getattr(h.client, method)
    kw = {"json": body} if body is not None else {}
    assert call(path, headers=h.patient, **kw).status_code == 403
    assert call(path, **kw).status_code == 401
    assert call(path, headers={"Authorization": "Bearer forged.token"}, **kw).status_code == 401
    assert h.gw.count() == 0


def test_login_issues_working_tokens():
    h = Harness(Gateway())
    tok = h.client.post("/api/login", json={"role": "doctor"}).json()["token"]
    assert h.client.get("/api/sessions", headers={"Authorization": f"Bearer {tok}"}).status_code == 200
    ptok = h.client.post("/api/login", json={"role": "patient"}).json()["token"]
    assert h.client.post("/api/sessions", json={}, headers={"Authorization": f"Bearer {ptok}"}).status_code == 200
    assert h.client.post("/api/sessions", json={}).status_code == 401
    assert h.client.post("/api/login", json={"role": "admin"}).status_code == 422


# --------------------------------------------------------------------- other endpoints


def test_healthz_reports_no_key_values():
    h = Harness(Gateway())
    body = h.client.get("/api/healthz").json()
    assert body == {"ok": True, "mode": "dev", "trustedrouter_configured": True, "fake_model": False}
    assert "test-key" not in json.dumps(body)


def test_negative_test_endpoint_stores_refused_event():
    h = Harness(Gateway())
    sid = h.new_session()
    res = h.client.post("/api/demo/negative-test", json={"session_id": sid}, headers=h.doctor)
    assert res.status_code == 200 and res.json()["outcome"] == "refused"
    assert h.gw.count() == 1
    trust = h.client.get(f"/api/sessions/{sid}/trust", headers=h.doctor).json()
    assert [e["outcome"] for e in trust["events"]] == ["refused"]
    assert trust["attestation"]["status"] == "unavailable"


def test_scenario_run_endpoint():
    h = Harness(Gateway(turns=len(load("S1")["turns"]), fields=_fields("S1")))
    res = h.client.post("/api/demo/scenarios/S1/run", headers=h.doctor)
    assert res.status_code == 200 and res.json()["status"] == "ready" and res.json()["brief_id"]
    h2 = Harness(Gateway(turns=99, fields=_fields("S9")))
    res = h2.client.post("/api/demo/scenarios/S9/run", headers=h2.doctor)
    assert res.json()["status"] == "urgent" and res.json()["turns_run"] == 3
    assert h2.client.post("/api/demo/scenarios/..%2Fx/run", headers=h2.doctor).status_code == 404
    assert h2.client.post("/api/demo/scenarios/S99/run", headers=h2.doctor).status_code == 404


def test_queue_lists_red_flags_first_then_newest():
    h = Harness(Gateway(turns=99, fields=_fields("S8")))
    first = h.new_session()
    urgent, _, _ = h.run(load("S8")["turns"])
    newest = h.new_session()
    rows = h.client.get("/api/sessions", headers=h.doctor).json()["sessions"]
    assert [r["session_id"] for r in rows] == [urgent, newest, first]
    assert rows[0]["red_flag_rule"] == "R3" and rows[0]["status"] == "urgent"


def test_unknown_session_404():
    h = Harness(Gateway())
    assert h.say("missing", "hi").status_code == 404
    assert h.client.get("/api/sessions/missing/brief", headers=h.doctor).status_code == 404
    assert h.client.get("/api/sessions/missing/flag", headers=h.doctor).status_code == 404
    assert h.client.get("/api/sessions/missing/trust", headers=h.doctor).status_code == 404


# ------------------------------------------------------------------------ intake node


def test_diagnosis_reply_is_filtered():
    bad = json.dumps({"reply": "You might have fibroids. How old are you?", "extracted": {}, "done": False})
    h = Harness(Gateway(intake_replies=[bad]))
    sid = h.new_session()
    reply = h.say(sid, "My periods are heavy.").json()["reply"]
    assert "fibroid" not in reply.lower()
    # The opening question already asked "what brings you in", so the filtered reply asks
    # the next required field instead of repeating it.
    assert reply.endswith("65 and over?")


def test_bad_schema_retried_once_in_dev():
    good = json.dumps({"reply": "How old are you?", "extracted": {"reason_for_visit": "checkup"}, "done": False})
    h = Harness(Gateway(intake_replies=[json.dumps({"nope": 1}), good]))
    sid = h.new_session()
    res = h.say(sid, "I want a checkup.")
    assert res.status_code == 200 and res.json()["reply"] == "How old are you?"
    assert h.gw.count("intake") == 2
    bad = json.dumps({"nope": 1})
    h2 = Harness(Gateway(intake_replies=[bad, bad]))
    sid2 = h2.new_session()
    res2 = h2.say(sid2, "I want a checkup.")
    # Unusable model output on an intake turn: the next fixed question, not a 502.
    assert res2.status_code == 200, res2.text
    assert res2.json()["status"] == "in_progress" and res2.json()["reply"].endswith("?")
    assert h2.gw.count("intake") == 2
    assert "intake_fallback_question" in h2.dump("audit_log")
    assert h2.say(sid2, "I'm 30.").status_code == 200  # the session continues


def test_unparseable_intake_text_falls_back_to_a_fixed_question():
    h = Harness(Gateway(intake_replies=["Plain text, no JSON at all.", "Still no JSON here."]))
    sid = h.new_session()
    res = h.say(sid, "I want a checkup.")
    assert res.status_code == 200 and res.json()["status"] == "in_progress"
    assert "Plain text" not in res.json()["reply"]


def test_twelve_turn_cap_forces_brief():
    h = Harness(Gateway(turns=99, fields={}))
    sid = h.new_session()
    statuses = [h.say(sid, f"Answer number {i}.").json()["status"] for i in range(12)]
    assert statuses[:11] == ["in_progress"] * 11 and statuses[11] == "ready"
    assert h.gw.count("intake") == 12 and h.gw.count("brief") == 1


def test_merge_intake_skips_invalid_fields():
    rec = merge_intake(IntakeRecord(medications=["a"]), {
        "age_band": "30-39", "bleeding_pattern": "bogus", "medications": ["b", "a"],
        "symptom": {"severity_0_10": 4}, "unknown_key": 1, "pregnancy_possible": None,
    })
    assert rec.age_band.value == "30-39" and rec.bleeding_pattern is None
    assert rec.medications == ["a", "b"] and rec.symptom.severity_0_10 == 4
    rec = merge_intake(rec, {"symptom": {"location": "left"}})
    assert rec.symptom.severity_0_10 == 4 and rec.symptom.location == "left"


def test_evidence_title_round_trips():
    from app.models import EvidenceItem
    from app.store import Store

    store = Store(":memory:")
    sid = store.create_session("dev")
    store.add_evidence(sid, [EvidenceItem(query="q", url="https://www.cdc.gov/x", title="CDC page", passage="p")])
    assert store.get_evidence(sid)[0].title == "CDC page"


# ------------------------------------------------- resend safety (contract check 2026-11-19)


def test_session_locked_409_carries_status_and_urgent_payload():
    h = Harness(Gateway(turns=99, fields=_fields("S7")))
    sid, last, _ = h.run(load("S7")["turns"])
    assert last.json()["status"] == "urgent"
    res = h.say(sid, "hello again")
    assert res.status_code == 409
    body = res.json()
    assert body["error"] == "session_locked" and body["status"] == "urgent"
    assert body["urgent"] == last.json()["urgent"]
    s1 = load("S1")
    h2 = Harness(Gateway(turns=len(s1["turns"]), fields=_fields("S1")))
    sid2, _, _ = h2.run(s1["turns"])
    body2 = h2.say(sid2, "one more").json()
    assert body2["status"] == "ready" and body2["urgent"] is None
    assert h.client.get("/openapi.json").status_code == 200


def test_resend_with_same_client_message_id_is_idempotent():
    h = Harness(Gateway())
    sid = h.new_session()
    send = lambda text, mid: h.client.post(  # noqa: E731
        f"/api/sessions/{sid}/messages", json={"text": text, "client_message_id": mid}, headers=h.patient)
    first = send("I want a checkup.", "m-1")
    again = send("I want a checkup.", "m-1")
    assert first.status_code == again.status_code == 200
    assert again.json() == first.json()
    assert h.gw.count("intake") == 1
    assert sum(1 for m in h.store.get_messages(sid) if m["role"] == "patient") == 1
    assert send("I'm 30.", "m-2").status_code == 200
    assert h.gw.count("intake") == 2


def test_resend_after_urgent_returns_the_urgent_turn_not_409():
    h = Harness(Gateway(turns=99, fields=_fields("S7")))
    sid = h.new_session()
    body = None
    for i, text in enumerate(load("S7")["turns"]):
        body = h.client.post(f"/api/sessions/{sid}/messages", json={"text": text, "client_message_id": f"t{i}"},
                             headers=h.patient).json()
    assert body["status"] == "urgent"
    again = h.client.post(f"/api/sessions/{sid}/messages",
                          json={"text": load("S7")["turns"][-1], "client_message_id": f"t{i}"}, headers=h.patient)
    assert again.status_code == 200 and again.json() == body


def test_turn_budget_used_up_fails_fast_without_a_call():
    h = Harness(Gateway(), turn_budget_s=0.0)
    sid = h.new_session()
    res = h.say(sid, "I want a checkup.")
    assert res.status_code == 502 and res.json()["error"] == "model_error"
    assert h.gw.count() == 0
    assert "turn_deadline_exceeded" in h.dump("trust_events")


def test_unusable_model_output_on_every_turn_still_finishes_the_intake():
    # Every intake answer is prose; the deterministic fallback asks the three required
    # questions, fills those fields from the answers, and the brief is drafted.
    h = Harness(Gateway(intake_replies=["prose"] * 6))
    sid = h.new_session()
    replies = [h.say(sid, t).json() for t in ("I'd like a checkup.", "I'm 34.", "No, I don't think so.")]
    assert [r["status"] for r in replies] == ["in_progress", "in_progress", "ready"]
    assert "age group" in replies[0]["reply"] and "pregnant" in replies[1]["reply"]
    rec, completed = h.store.get_intake(sid)
    assert rec.age_band.value == "30-39" and rec.pregnancy_possible == "no" and completed
    assert h.gw.count("brief") == 1


def test_rule_extract_only_fills_missing_required_fields():
    from app.graph import rule_extract
    assert rule_extract(IntakeRecord(), "What brings you in today?", "A checkup.") == {"reason_for_visit": "A checkup."}
    assert rule_extract(IntakeRecord(), "Which age group are you in?", "I'm 52.") == {"age_band": "50-64"}
    assert rule_extract(IntakeRecord(), "How old are you?", "I am 70") == {"age_band": "65+"}
    assert rule_extract(IntakeRecord(), "Could you be pregnant?", "Not sure") == {"pregnancy_possible": "unsure"}
    assert rule_extract(IntakeRecord(pregnancy_possible="no"), "Could you be pregnant?", "yes") == {}
    assert rule_extract(IntakeRecord(), "What stage is it at?", "34") == {}
