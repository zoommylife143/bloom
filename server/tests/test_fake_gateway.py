"""The dev-only offline fake model (BLOOM_FAKE_MODEL=1). Synthetic data only."""

from __future__ import annotations

import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.fake_gateway import FAKE_MODEL_ID
from app.main import build_services, create_app, make_token
from app.prompts import INTAKE_JSON_REMINDER, intake_messages
from app.models import IntakeRecord

SCENARIOS = Path(__file__).resolve().parents[2] / "scenarios"


def _settings(**kw) -> Settings:
    base = dict(bloom_mode="dev", trustedrouter_api_key="", demo_login_secret="s",
                database_url="sqlite:///:memory:", context_dev_api_key="")
    return Settings(**{**base, **kw})


def test_fake_model_is_off_by_default():
    assert Settings().bloom_fake_model is False


def test_fake_model_is_refused_in_private_mode():
    with pytest.raises(RuntimeError, match="private"):
        build_services(_settings(bloom_mode="private", bloom_fake_model=True))


def test_fake_model_runs_intake_to_brief_and_refuses_negative_test():
    services = build_services(_settings(bloom_fake_model=True))
    client = TestClient(create_app(services))
    patient = {"Authorization": f"Bearer {make_token(services.secret, 'patient')[0]}"}
    doctor = {"Authorization": f"Bearer {make_token(services.secret, 'doctor')[0]}"}
    assert client.get("/api/healthz").json()["fake_model"] is True
    sid = client.post("/api/sessions", json={}, headers=patient).json()["session_id"]
    turns = json.loads((SCENARIOS / "S1.json").read_text())["turns"]
    body = {}
    for text in turns[:3]:
        body = client.post(f"/api/sessions/{sid}/messages", json={"text": text}, headers=patient).json()
    assert body["status"] == "ready" and body["done"] is True
    brief = client.get(f"/api/sessions/{sid}/brief", headers=doctor).json()
    assert brief["provenance"]["generated_by"] == f"{FAKE_MODEL_ID} (dev)"
    neg = client.post("/api/demo/negative-test", json={}, headers=doctor).json()
    assert neg["outcome"] == "refused"
    assert neg["evidence"]["error_code"] == "confidential_privacy_required"


def test_intake_history_is_shown_as_json_with_a_trailing_reminder():
    msgs = intake_messages(
        [{"role": "bloom", "text": "What brings you in?"}, {"role": "patient", "text": "A checkup."}],
        IntakeRecord(), 1,
    )
    # Earlier Bloom turns are shown as the intake JSON object, so the model does not
    # imitate plain-text answers (root cause of the live format failures, 2026-11-19).
    assert msgs[2] == {"role": "assistant",
                       "content": '{"reply": "What brings you in?", "extracted": {}, "done": false}'}
    assert msgs[3] == {"role": "user", "content": "A checkup."}
    assert msgs[-1] == {"role": "system", "content": INTAKE_JSON_REMINDER}
