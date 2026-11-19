"""Contract check: drive a RUNNING Bloom server over real HTTP and save every response
as a JSON fixture that the Dart client tests parse with the real fromJson code
(packages/core_data/test/contract_fixtures_test.dart).

Synthetic data only: the patient text comes from scenarios/S1.json and S7.json.
Tokens, receipts and header values are redacted before anything is written, and the
script refuses to write a fixture that contains a configured API key.

Usage (see docs/api-contract.md, "Contract check"):

    # offline, no keys: dev-only fake model
    BLOOM_FAKE_MODEL=1 DATABASE_URL=sqlite:///./contract.db uv run uvicorn app.main:app --port 8765
    uv run python scripts/contract_capture.py --base http://127.0.0.1:8765 --out ../packages/core_data/test/fixtures/contract/fake

    # private mode with no confidential model: the 502 refusal (no outbound call is made)
    BLOOM_MODE=private DATABASE_URL=sqlite:///./contract-private.db uv run uvicorn app.main:app --port 8766
    uv run python scripts/contract_capture.py --base http://127.0.0.1:8766 --out ... --private-only

    # live (real model calls, ~12-15): one S1 brief, one S7 red flag, the negative test
    uv run --env-file ../.env uvicorn app.main:app --port 8765
    uv run --env-file ../.env python scripts/contract_capture.py --base http://127.0.0.1:8765 --out ... --live
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any

import httpx

ROOT = Path(__file__).resolve().parents[2]
SCENARIOS = ROOT / "scenarios"
REDACTED = "<redacted>"
_SECRET_ENV = ("TRUSTEDROUTER_API_KEY", "CONTEXT_DEV_API_KEY", "DEMO_LOGIN_SECRET", "CONTEXT_DEV_WEBHOOK_SECRET")


def turns(sid: str) -> list[str]:
    return json.loads((SCENARIOS / f"{sid}.json").read_text(encoding="utf-8"))["turns"]


def scrub(value: Any, key: str = "") -> Any:
    if key == "token":
        return REDACTED
    if key == "receipt" and isinstance(value, dict):
        claims = value.get("claims") if isinstance(value.get("claims"), dict) else {}
        return {"redacted": True, "claim_keys": sorted(claims), "signature_verified": value.get("signature_verified")}
    if key == "headers" and isinstance(value, dict):
        return {k: REDACTED for k in value}
    if isinstance(value, dict):
        return {k: scrub(v, k) for k, v in value.items()}
    if isinstance(value, list):
        return [scrub(v) for v in value]
    return value


class Capture:
    def __init__(self, base: str, out: Path):
        self.http = httpx.Client(base_url=base.rstrip("/"), timeout=120)
        self.out = out
        self.out.mkdir(parents=True, exist_ok=True)
        self.secrets = [v for k in _SECRET_ENV if len(v := os.environ.get(k, "")) >= 8]
        self.failures: list[str] = []

    def call(self, name: str | None, method: str, path: str, *, token: str | None = None,
             body: Any = None, expect: int = 200) -> Any:
        headers = {"Accept": "application/json"}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        res = self.http.request(method, "/api" + path, headers=headers,
                                json=body if body is not None else None)
        data = res.json() if res.content else None
        ok = res.status_code == expect
        print(f"{'ok  ' if ok else 'FAIL'} {res.status_code} {method} /api{path}" + (f" -> {name}" if name else ""))
        if not ok:
            self.failures.append(f"{method} {path}: expected {expect}, got {res.status_code} {data}")
        if name:
            fixture = {"method": method, "path": "/api" + path, "status": res.status_code, "body": scrub(data)}
            text = json.dumps(fixture, indent=2, ensure_ascii=False) + "\n"
            if any(s in text for s in self.secrets):
                raise SystemExit(f"refusing to write {name}: it contains a configured secret")
            (self.out / f"{name}.json").write_text(text, encoding="utf-8")
        return data

    def run_intake(self, token: str, sid: str, texts: list[str], prefix: str) -> dict:
        last: dict = {}
        for i, text in enumerate(texts):
            last = self.call(f"{prefix}_turn_{i + 1}", "POST", f"/sessions/{sid}/messages", token=token,
                             body={"text": text})
            if not isinstance(last, dict) or last.get("done"):
                break
        return last


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="http://127.0.0.1:8765")
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--live", action="store_true", help="real model: one brief only, no scenario run")
    ap.add_argument("--private-only", action="store_true", help="server in private mode: capture the 502 refusal")
    ap.add_argument("--skip-s1", action="store_true", help="skip the S1 intake (saves ~10 live model calls)")
    args = ap.parse_args()
    c = Capture(args.base, args.out)

    c.call("healthz", "GET", "/healthz")
    patient = c.call("login_patient", "POST", "/login", body={"role": "patient"})["token"]
    doctor = c.call("login_doctor", "POST", "/login", body={"role": "doctor"})["token"]

    if args.private_only:
        sid = c.call("create_session", "POST", "/sessions", token=patient, body={})["session_id"]
        c.call("error_502_confidential_route_unavailable", "POST", f"/sessions/{sid}/messages", token=patient,
               body={"text": turns("S1")[0]}, expect=502)
        c.call("trust_refused", "GET", f"/sessions/{sid}/trust", token=doctor)
        return _done(c)

    # --- errors that need no model call
    c.call("error_422_login_role", "POST", "/login", body={"role": "admin"}, expect=422)
    c.call("error_401_no_token", "POST", "/sessions", body={}, expect=401)
    c.call(None, "POST", "/sessions", token="not-a-token", body={}, expect=401)
    c.call("error_403_patient_on_doctor", "GET", "/sessions", token=patient, expect=403)
    c.call("error_404_session_not_found", "POST", "/sessions/does-not-exist/messages", token=patient,
           body={"text": "hello"}, expect=404)
    c.call("error_422_empty_text", "POST", "/sessions/does-not-exist/messages", token=patient,
           body={"text": ""}, expect=422)
    c.call("error_404_scenario_not_found", "POST", "/demo/scenarios/S99/run", token=doctor, expect=404)
    c.call(None, "POST", "/briefs/does-not-exist/decision", token=doctor,
           body={"decision": "approve", "reviewer": "Dr. Demo"}, expect=404)

    empty = c.call(None, "POST", "/sessions", token=patient, body={})["session_id"]
    c.call("error_404_brief_not_found", "GET", f"/sessions/{empty}/brief", token=doctor, expect=404)
    c.call("error_404_flag_not_found", "GET", f"/sessions/{empty}/flag", token=doctor, expect=404)
    s1 = None if args.skip_s1 else s1_flow(c, args, patient, doctor)
    if not args.live:  # idempotent resend: same client_message_id -> same stored response, no new turn
        sid = c.call(None, "POST", "/sessions", token=patient, body={})["session_id"]
        msg = {"text": turns("S1")[0], "client_message_id": "contract-check-1"}
        c.call("resend_first", "POST", f"/sessions/{sid}/messages", token=patient, body=msg)
        c.call("resend_again", "POST", f"/sessions/{sid}/messages", token=patient, body=msg)

    # --- S7 red flag
    s7 = c.call(None, "POST", "/sessions", token=patient, body={"scenario_id": "S7"})["session_id"]
    last = c.run_intake(patient, s7, turns("S7"), "s7")
    if last.get("status") != "urgent":
        c.failures.append(f"S7 did not reach urgent: {last.get('status')}")
    else:
        c.call("flag", "GET", f"/sessions/{s7}/flag", token=doctor)
        c.call("error_409_session_locked_urgent", "POST", f"/sessions/{s7}/messages", token=patient,
               body={"text": "hello"}, expect=409)

    if not args.live:
        c.call("scenario_run", "POST", "/demo/scenarios/S8/run", token=doctor)

    c.call("negative_test", "POST", "/demo/negative-test", token=doctor, body={"session_id": s1 or s7})
    if not args.live:
        c.call("negative_test_no_session", "POST", "/demo/negative-test", token=doctor, body={})
    c.call("sessions_list", "GET", "/sessions", token=doctor)
    c.call("audit", "GET", "/audit", token=doctor)
    c.call("guideline_updates", "GET", "/guideline-updates", token=doctor)
    return _done(c)


def s1_flow(c: Capture, args, patient: str, doctor: str) -> str | None:
    """S1 intake to a brief, then the decision calls. Returns the session id."""
    started = c.call("create_session", "POST", "/sessions", token=patient, body={"scenario_id": "S1"})
    s1 = started["session_id"]
    last = c.run_intake(patient, s1, turns("S1"), "s1")
    if last.get("status") != "ready":
        c.failures.append(f"S1 did not reach ready: {last.get('status')}")
        return s1
    c.call("error_409_session_locked", "POST", f"/sessions/{s1}/messages", token=patient,
           body={"text": "one more thing"}, expect=409)
    brief = c.call("brief_draft", "GET", f"/sessions/{s1}/brief", token=doctor)
    bid = brief["brief_id"]
    c.call("error_422_edited_brief_required", "POST", f"/briefs/{bid}/decision", token=doctor,
           body={"decision": "edit", "reviewer": "Dr. Demo"}, expect=422)
    if args.live:
        c.call("decision_approve", "POST", f"/briefs/{bid}/decision", token=doctor,
               body={"decision": "approve", "reviewer": "Dr. Demo"})
    else:
        edited = {**brief["brief"], "plan_considerations": "Edited by the synthetic reviewer."}
        c.call("decision_edit", "POST", f"/briefs/{bid}/decision", token=doctor,
               body={"decision": "edit", "reviewer": "Dr. Demo", "edited": edited})
    c.call("error_409_already_decided", "POST", f"/briefs/{bid}/decision", token=doctor,
           body={"decision": "reject", "reviewer": "Dr. Demo"}, expect=409)
    c.call("trust_s1", "GET", f"/sessions/{s1}/trust", token=doctor)

    if not args.live:  # two more cheap fake briefs for approve and reject
        for decision in ("approve", "reject"):
            sid = c.call(None, "POST", "/sessions", token=patient, body={})["session_id"]
            c.run_intake(patient, sid, turns("S1")[:3], f"s1_{decision}")
            b = c.call(None, "GET", f"/sessions/{sid}/brief", token=doctor)
            c.call(f"decision_{decision}", "POST", f"/briefs/{b['brief_id']}/decision", token=doctor,
                   body={"decision": decision, "reviewer": "Dr. Demo"})
    return s1


def _done(c: Capture) -> int:
    for f in c.failures:
        print("FAIL", f, file=sys.stderr)
    print(f"{len(c.failures)} failure(s); fixtures in {c.out}")
    return 1 if c.failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
