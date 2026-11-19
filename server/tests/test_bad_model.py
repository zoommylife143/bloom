"""The intake reaches a brief even when the model answers badly (live issue 2026-11-19:
60-80 % of intake answers were prose, not JSON). Offline: the dev-only fake gateway
simulates prose, truncated JSON, wrong-shape JSON and a 400 to json_object mode.
Synthetic data only.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import httpx2
import pytest
from fastapi.testclient import TestClient
from openai import OpenAI

from app.config import Settings
from app.fake_gateway import FakeGateway, fake_client
from app.graph import FALLBACK_BRIEF_LABEL, _FALLBACK_QUESTIONS, rule_extract
from app.main import build_services, create_app, make_token
from app.models import EvidenceItem, IntakeRecord
from app.prompts import CLOSING_MESSAGE, MAX_TURNS
from app.router import REPAIR_INSTRUCTION, ModelRouter

SCENARIO_DIR = Path(__file__).resolve().parents[2] / "scenarios"
NON_URGENT = ["S1", "S3"]
RATES = [1.0, 0.5, 0.0]
FILLER = "No, nothing else."


def load(sid: str) -> dict:
    return json.loads((SCENARIO_DIR / f"{sid}.json").read_text(encoding="utf-8"))


class FakeRetriever:
    def search_with_event(self, query: str):
        event = {"node": "retrieve", "route": "context.dev", "policy_required": "deidentified_query",
                 "model_id": None, "request_id": "ctx-test", "latency_ms": 1, "outcome": "ok",
                 "evidence": {"cache": "fixture", "result_count": 1}}
        h = hashlib.sha256(query.encode()).hexdigest()[:8]
        return [EvidenceItem(query=query, url=f"https://www.acog.org/guidance/{h}", title="Synthetic guidance",
                             passage="Synthetic guideline passage for tests.")], event


class Harness:
    def __init__(self, gateway: FakeGateway | None = None, *, transport=None, **settings_kw):
        base = dict(bloom_mode="dev", trustedrouter_api_key="", demo_login_secret="s",
                    database_url="sqlite:///:memory:", context_dev_api_key="", tr_model_id="bloom-fake/offline")
        self.settings = Settings(**{**base, **settings_kw})
        self.gw = gateway
        if transport is not None:
            client = OpenAI(api_key="k", base_url="https://fake-gateway.invalid/v1",
                            http_client=httpx2.Client(transport=httpx2.MockTransport(transport)))
        else:
            client = fake_client(gateway)
        from app.store import Store
        self.store = Store(":memory:")
        self.router = ModelRouter(self.settings, client=client, on_event=self.store.record_trust_event)
        self.services = build_services(self.settings, store=self.store, router=self.router,
                                       retriever=FakeRetriever(),
                                       attestation_fn=lambda: {"status": "unavailable", "verified_claims": False})
        self.client = TestClient(create_app(self.services))
        self.patient = {"Authorization": f"Bearer {make_token(self.services.secret, 'patient')[0]}"}
        self.doctor = {"Authorization": f"Bearer {make_token(self.services.secret, 'doctor')[0]}"}

    def run(self, turns: list[str]) -> tuple[str, list[dict]]:
        """Scenario turns, then a filler answer until done, as live_check.py does."""
        sid = self.client.post("/api/sessions", json={}, headers=self.patient).json()["session_id"]
        out: list[dict] = []
        for i in range(MAX_TURNS):
            text = turns[i] if i < len(turns) else FILLER
            res = self.client.post(f"/api/sessions/{sid}/messages", json={"text": text}, headers=self.patient)
            assert res.status_code == 200, res.text
            out.append(res.json())
            if res.json()["done"]:
                break
        return sid, out

    def brief(self, sid: str) -> dict:
        res = self.client.get(f"/api/sessions/{sid}/brief", headers=self.doctor)
        assert res.status_code == 200, res.text
        return res.json()


def _assert_no_repeated_fallback_question(h: Harness, sid: str) -> None:
    bloom = [m["text"] for m in h.store.get_messages(sid) if m["role"] == "bloom"]
    for _, question in _FALLBACK_QUESTIONS:
        assert sum(question in t for t in bloom) <= 1, (question, bloom)
    asks = [e.evidence.get("asks") for e in h.store.list_trust_events(sid) if e.node == "intake_fallback"]
    asks = [a for a in asks if a]
    assert len(asks) == len(set(asks)), asks


@pytest.mark.parametrize("rate", RATES)
@pytest.mark.parametrize("sid_name", NON_URGENT)
def test_non_urgent_scenario_reaches_a_brief(sid_name, rate):
    h = Harness(FakeGateway(garbage_rate=rate, seed=11))
    sid, replies = h.run(load(sid_name)["turns"])
    last = replies[-1]
    assert last["status"] == "ready" and last["done"] is True and len(replies) <= MAX_TURNS
    assert last["reply"] == CLOSING_MESSAGE
    assert last["brief_parse_path"] in ("first_pass", "repair", "fallback")
    assert all(r["parse_path"] in ("first_pass", "repair", "fallback") for r in replies)
    _assert_no_repeated_fallback_question(h, sid)
    brief = h.brief(sid)
    evidence_urls = {e["url"] for e in brief["evidence"]}
    cited = [x["source_url"] for x in brief["brief"]["screenings_possibly_due"] if x["source_url"]]
    assert cited and set(cited) <= evidence_urls  # never a citation that was not retrieved
    assert brief["provenance"]["review_status"] == "draft"
    if last["brief_parse_path"] == "fallback":
        assert brief["provenance"]["source"] == "fallback"
        assert "fallback" in brief["provenance"]["generated_by"]
        assert brief["brief"]["subjective"].startswith(FALLBACK_BRIEF_LABEL)
    else:
        assert brief["provenance"]["source"] == "model"
    if rate == 0.0:
        assert {r["parse_path"] for r in replies} == {"first_pass"} and last["brief_parse_path"] == "first_pass"
        assert h.gw.count(outcome="ok") == h.gw.count()


@pytest.mark.parametrize("sid_name", NON_URGENT)
def test_all_garbage_uses_fixed_rules_and_a_fallback_draft(sid_name):
    s = load(sid_name)
    h = Harness(FakeGateway(garbage_rate=1.0))
    sid, replies = h.run(s["turns"])
    assert [r["parse_path"] for r in replies] == ["fallback"] * len(replies)
    assert len(replies) <= 4  # ends as soon as each required field was asked once
    rec, completed = h.store.get_intake(sid)
    assert completed and rec.reason_for_visit == s["turns"][0]
    assert rec.age_band.value == s["age_band"]
    assert replies[-1]["brief_parse_path"] == "fallback"
    # every intake turn: one call + one repair call; the brief: the same
    assert h.gw.count("intake") == 2 * len(replies) and h.gw.count("brief") == 2
    assert h.brief(sid)["brief"]["assessment_considerations"].startswith(FALLBACK_BRIEF_LABEL)


def test_half_garbage_repairs_some_turns():
    h = Harness(FakeGateway(garbage_rate=0.5, seed=3))
    _, replies = h.run(load("S1")["turns"])
    paths = [r["parse_path"] for r in replies] + [replies[-1]["brief_parse_path"]]
    assert "repair" in paths or "fallback" in paths
    assert replies[-1]["status"] == "ready"


@pytest.mark.parametrize("rate", RATES)
def test_s7_still_goes_urgent(rate):
    h = Harness(FakeGateway(garbage_rate=rate, seed=5))
    _, replies = h.run(load("S7")["turns"])
    assert replies[-1]["status"] == "urgent" and replies[-1]["urgent"]["rule_id"] == "R2"
    assert replies[-1]["parse_path"] == "rule"


def test_json_mode_400_is_retried_without_it_and_remembered():
    gw = FakeGateway(reject_json_mode=True)
    h = Harness(gw)
    _, replies = h.run(load("S1")["turns"])
    assert replies[-1]["status"] == "ready"
    assert gw.count(outcome="json_mode_400") == 1  # only the very first call
    assert h.router.json_mode_rejected is True
    assert {r["parse_path"] for r in replies} == {"first_pass"}


def test_json_mode_off_sends_no_response_format():
    seen: list[dict] = []
    gw = FakeGateway()

    def transport(request):
        seen.append(json.loads(request.content))
        return gw(request)

    h = Harness(transport=transport, tr_json_mode=False)
    h.run(load("S1")["turns"])
    assert seen and all("response_format" not in b for b in seen)


def test_garbage_turn_count_ignores_the_repair_message():
    # The fake counts patient turns only, so a repair call answers like the first call.
    gw = FakeGateway()
    body = {"model": "m", "provider": {"min_privacy": "zdr"}, "messages": [
        {"role": "system", "content": __import__("app.prompts", fromlist=["x"]).INTAKE_SYSTEM_PROMPT},
        {"role": "user", "content": "hi"}, {"role": "assistant", "content": "prose"},
        {"role": "user", "content": REPAIR_INSTRUCTION}]}
    res = gw(httpx2.Request("POST", "https://x/v1/chat/completions", content=json.dumps(body)))
    out = json.loads(res.json()["choices"][0]["message"]["content"])
    assert out["extracted"] == {"reason_for_visit": "routine gynecology visit (offline fake model)"}


def test_private_mode_garbage_uses_no_repair_and_no_other_model():
    seen: list[dict] = []

    def prose_only(request):
        body = json.loads(request.content)
        seen.append(body)
        return httpx2.Response(200, json={
            "id": "g", "object": "chat.completion", "created": 1, "model": body["model"],
            "choices": [{"index": 0, "message": {"role": "assistant", "content": "Plain prose."},
                         "finish_reason": "stop"}]})

    h = Harness(transport=prose_only, bloom_mode="private", private_model_id="conf/model-x")
    sid, replies = h.run(load("S1")["turns"])
    assert replies[-1]["status"] == "ready" and replies[-1]["brief_parse_path"] == "fallback"
    assert len(seen) == len(replies) + 1  # one call per intake turn + one brief call, no retries
    assert {b["model"] for b in seen} == {"conf/model-x"}
    assert all(b["provider"]["min_privacy"] == "confidential" and "response_format" not in b for b in seen)
    _assert_no_repeated_fallback_question(h, sid)


def test_fallback_off_restores_502_on_garbage_intake():
    h = Harness(FakeGateway(garbage_rate=1.0), bloom_deterministic_fallback=False)
    sid = h.client.post("/api/sessions", json={}, headers=h.patient).json()["session_id"]
    res = h.client.post(f"/api/sessions/{sid}/messages", json={"text": "A checkup."}, headers=h.patient)
    assert res.status_code == 502 and res.json()["error"] == "model_error"


def test_fallback_never_repeats_an_answered_question_and_finishes():
    # Required fields asked by the model in its own words count as asked.
    h = Harness(FakeGateway(garbage_rate=1.0))
    sid, replies = h.run(["A checkup.", "Not sure what you mean.", "Still not sure.", "Hmm.", "Okay."])
    # "Not sure what you mean." answers the age question with no age: age is never re-asked.
    assert replies[-1]["status"] == "ready"
    assert len(replies) <= 4
    _assert_no_repeated_fallback_question(h, sid)


def test_rule_extract_new_cases():
    assert rule_extract(IntakeRecord(), "Anything else?", "Also I'm 34 by the way.") == {"age_band": "30-39"}
    assert rule_extract(IntakeRecord(), "Anything else?", "I'm 30 weeks along.") == {}
    assert rule_extract(IntakeRecord(), "Could you be pregnant?",
                        "No, I don't think I could be pregnant.") == {"pregnancy_possible": "no"}
    # A long answer that does not mention pregnancy is not read as one.
    assert rule_extract(IntakeRecord(), "Could you be pregnant?",
                        "My last Pap was in 2019, so it's been a while. I've never had an HPV test.") == {}
    assert rule_extract(IntakeRecord(), "When did your period start?",
                        "About 3 weeks ago. I can't be pregnant though.") == {"pregnancy_possible": "no"}
    assert rule_extract(IntakeRecord(), "Is there anything else?", "Nope.",
                        first_patient="Painful periods.") == {"reason_for_visit": "Painful periods."}


def test_prior_bloom_turns_are_sent_as_json_with_their_fields():
    from app.prompts import intake_messages
    seen: list[dict] = []
    gw = FakeGateway()

    def transport(request):
        seen.append(json.loads(request.content))
        return gw(request)

    h = Harness(transport=transport)
    h.run(load("S1")["turns"])  # done after turn 3; seen[2] is turn 3's intake call
    assistant = [m["content"] for m in seen[2]["messages"] if m["role"] == "assistant"]
    assert len(assistant) == 3 and all(json.loads(a)["reply"] for a in assistant)
    assert json.loads(assistant[1])["extracted"]["reason_for_visit"]  # fields known after turn 1
    msgs = intake_messages([{"role": "bloom", "text": "Q?", "meta": {"extracted": {"age_band": "30-39"}}},
                            {"role": "patient", "text": "A."}], IntakeRecord(), 1)
    assert json.loads(msgs[2]["content"]) == {"reply": "Q?", "extracted": {"age_band": "30-39"}, "done": False}


def test_old_database_gets_the_messages_meta_column(tmp_path):
    import sqlite3
    from app.db import init_db
    conn = sqlite3.connect(tmp_path / "old.db")
    conn.execute("CREATE TABLE messages (id INTEGER PRIMARY KEY AUTOINCREMENT, session_id TEXT NOT NULL, "
                 "role TEXT NOT NULL, text TEXT NOT NULL, created_at TEXT NOT NULL)")
    init_db(conn)
    assert "meta" in {r[1] for r in conn.execute("PRAGMA table_info(messages)")}
