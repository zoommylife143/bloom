"""Context.dev Monitor webhook + guideline updates (runbook section 3, step 5). Offline.

Synthetic data only: change titles and summaries are made up; URLs are public guideline pages.
"""

from __future__ import annotations

import json
import time
from datetime import timedelta

import pytest
from fastapi.testclient import TestClient

from app import monitor
from app.config import Settings
from app.main import build_services, create_app, make_token
from app.models import Brief, EvidenceItem, Provenance, utcnow
from app.store import Store

SECRET = "whsec_synthetic_test_secret"
PATH = "/api/webhooks/context-monitor"
USPSTF = "https://www.uspreventiveservicestaskforce.org/uspstf/recommendation/cervical-cancer-screening"
CDC = "https://www.cdc.gov/female-blood-disorders/about/heavy-menstrual-bleeding.html"


def _settings(**kw) -> Settings:
    base = dict(bloom_mode="dev", trustedrouter_api_key="", demo_login_secret="test-secret",
                database_url="sqlite:///:memory:", context_dev_webhook_secret=SECRET)
    base.update(kw)
    return Settings(**base)


class Harness:
    def __init__(self, **kw):
        self.store = Store(":memory:")
        self.services = build_services(_settings(**kw), store=self.store, router=object(), retriever=object(),
                                       attestation_fn=lambda: {})
        self.client = TestClient(create_app(self.services))
        self.doctor = {"Authorization": f"Bearer {make_token(self.services.secret, 'doctor')[0]}"}
        self.patient = {"Authorization": f"Bearer {make_token(self.services.secret, 'patient')[0]}"}

    def post(self, payload: dict, *, secret: str = SECRET, ts: int | None = None, header: str | None = None):
        body = json.dumps(payload).encode()
        sig = header if header is not None else monitor.sign(secret, body, ts or int(time.time()))
        return self.client.post(PATH, content=body, headers={"X-Context-Signature": sig,
                                                             "X-Context-Event": payload.get("event", ""),
                                                             "Content-Type": "application/json"})


def change_payload(url: str, *, change_id: str = "chg_test1", detected_at: str | None = None,
                   summary: str = "Synthetic: the recommendation text changed.") -> dict:
    return {
        "event": "change.detected",
        "id": f"evt_{change_id}",
        "created_at": utcnow().isoformat(),
        "data": {
            "change": {
                "mode": "web", "id": change_id, "monitor_id": "mon_test", "run_id": "run_test",
                "target_type": "page", "change_detection_type": "exact",
                "title": "Guideline page changed", "summary": summary,
                "detected_at": detected_at or utcnow().isoformat(), "url": url,
                "tags": ["bloom"], "request_id": "00000000-0000-0000-0000-000000000000",
            },
            "run": {"id": "run_test"},
        },
    }


def test_good_signature_stores():
    h = Harness()
    r = h.post(change_payload(USPSTF, summary="x" * 900))
    assert r.status_code == 200, r.text
    assert r.json() == {"stored": 1}
    rows = h.store.list_guideline_updates()
    assert len(rows) == 1
    assert rows[0]["url"] == USPSTF and rows[0]["monitor_id"] == "mon_test"
    assert len(rows[0]["change_summary"]) == 500
    # Retry of the same change (same id) is not stored twice.
    assert h.post(change_payload(USPSTF)).json() == {"stored": 0}


@pytest.mark.parametrize("kind", ["wrong_secret", "tampered", "missing", "malformed", "stale"])
def test_bad_signature_401(kind):
    h = Harness()
    payload = change_payload(USPSTF)
    if kind == "wrong_secret":
        r = h.post(payload, secret="whsec_other")
    elif kind == "tampered":
        body = json.dumps(payload).encode()
        sig = monitor.sign(SECRET, body + b" ", int(time.time()))
        r = h.client.post(PATH, content=body, headers={"X-Context-Signature": sig})
    elif kind == "missing":
        r = h.client.post(PATH, content=json.dumps(payload).encode())
    elif kind == "malformed":
        r = h.post(payload, header="v1=deadbeef")
    else:
        r = h.post(payload, ts=int(time.time()) - monitor.TOLERANCE_S - 60)
    assert r.status_code == 401
    assert r.json()["error"] == "invalid_signature"
    assert h.store.list_guideline_updates() == []


def test_missing_secret_503():
    h = Harness(context_dev_webhook_secret="")
    r = h.post(change_payload(USPSTF), secret="")
    assert r.status_code == 503
    assert r.json() == {"error": "webhook_not_configured", "detail": "webhook not configured"}
    assert h.store.list_guideline_updates() == []


def test_any_of_several_secrets_verifies():
    h = Harness(context_dev_webhook_secret=f"whsec_first, {SECRET}")
    assert h.post(change_payload(USPSTF)).json() == {"stored": 1}


def test_off_allowlist_url_dropped():
    h = Harness()
    for i, url in enumerate(["https://example.com/guideline", "https://cdc.gov.evil.example/x",
                             "ftp://www.cdc.gov/x"]):
        r = h.post(change_payload(url, change_id=f"chg_off{i}"))
        assert r.status_code == 200 and r.json() == {"stored": 0}
    assert h.store.list_guideline_updates() == []


def test_run_completed_without_change_stores_nothing():
    h = Harness()
    payload = {"event": "run.completed", "id": "evt_run", "created_at": utcnow().isoformat(),
               "data": {"run": {"id": "run_x"}, "change": None}}
    assert h.post(payload).json() == {"stored": 0}


def test_get_guideline_updates_auth():
    h = Harness()
    assert h.client.get("/api/guideline-updates").status_code == 401
    assert h.client.get("/api/guideline-updates", headers={"Authorization": "Bearer nope"}).status_code == 401
    assert h.client.get("/api/guideline-updates", headers=h.patient).status_code == 403


def test_get_guideline_updates_newest_first_max_20():
    h = Harness()
    base = utcnow() - timedelta(days=1)
    for i in range(25):
        h.post(change_payload(CDC, change_id=f"chg_{i:02d}", detected_at=(base + timedelta(minutes=i)).isoformat()))
    r = h.client.get("/api/guideline-updates", headers=h.doctor)
    assert r.status_code == 200
    updates = r.json()["updates"]
    assert len(updates) == 20
    assert set(updates[0]) == {"url", "title", "detected_at", "change_summary"}
    times = [u["detected_at"] for u in updates]
    assert times == sorted(times, reverse=True)


def _seed_brief(store: Store) -> str:
    sid = store.create_session("dev", "S1")
    store.add_evidence(sid, [
        EvidenceItem(query="cervical cancer screening interval age 30-39", url=USPSTF, title="USPSTF",
                     passage="Synthetic passage."),
        EvidenceItem(query="heavy menstrual bleeding evaluation age 40-49", url=CDC, title="CDC",
                     passage="Synthetic passage."),
    ])
    brief = Brief(subjective="Synthetic.", objective="Synthetic.", assessment_considerations="Synthetic.",
                  plan_considerations="Synthetic.")
    store.save_brief(sid, brief, Provenance(generated_by="test (dev)", evidence_urls=[USPSTF, CDC]))
    return sid


def test_brief_includes_recent_guideline_updates():
    h = Harness()
    sid = _seed_brief(h.store)
    r = h.client.get(f"/api/sessions/{sid}/brief", headers=h.doctor)
    assert r.status_code == 200
    assert r.json()["guideline_updates"] == []

    # Recent change to a cited URL (trailing slash, no www) counts; an old one does not.
    h.post(change_payload("https://uspreventiveservicestaskforce.org/uspstf/recommendation/cervical-cancer-screening/",
                          change_id="chg_recent"))
    h.post(change_payload(CDC, change_id="chg_old", detected_at=(utcnow() - timedelta(days=8)).isoformat()))
    h.post(change_payload("https://www.acog.org/not-cited", change_id="chg_uncited"))
    body = h.client.get(f"/api/sessions/{sid}/brief", headers=h.doctor).json()
    assert body["guideline_updates"] == [USPSTF]
    # Existing fields are unchanged.
    assert {"brief_id", "session_id", "brief", "original_brief", "edited", "provenance", "evidence"} <= set(body)


def test_verify_signature_unit():
    body = b'{"event":"change.detected"}'
    now = 1_800_000_000
    monitor.verify_signature(SECRET, body, monitor.sign(SECRET, body, now), now=now)
    with pytest.raises(monitor.InvalidSignature):
        monitor.verify_signature("", body, monitor.sign(SECRET, body, now), now=now)
    with pytest.raises(monitor.InvalidSignature):
        monitor.verify_signature(SECRET, body, monitor.sign(SECRET, body, now), now=now + 301)
