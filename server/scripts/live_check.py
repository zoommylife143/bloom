"""Live check: drive scenarios end to end through a RUNNING Bloom server's HTTP API and
report, per patient turn, the HTTP status, how the model output was obtained
(``parse_path``: first_pass / repair / fallback / rule) and, at the end, whether a brief
with citations was drafted and how (``brief_parse_path``, provenance ``source``).

Scenarios: S1 and S3 (non-urgent, must end ``ready`` with a brief) and S7 (red flag R2,
must end ``urgent``). After a non-urgent scenario's scripted turns run out, the script
answers "No, nothing else." until the intake is done or reaches 12 turns, as a patient
would. Synthetic data only (scenarios/*.json). Tokens are never printed.

Usage:

    # offline rehearsal against the dev-only fake model, every answer garbage
    BLOOM_FAKE_MODEL=1 BLOOM_FAKE_GARBAGE_RATE=1.0 DATABASE_URL=sqlite:///./live-check.db \\
        uv run uvicorn app.main:app --port 8765
    uv run python scripts/live_check.py --base http://127.0.0.1:8765

    # live (real model calls; only after approval): server started by the lead, then
    uv run python scripts/live_check.py --base "$BASE_URL"

``--base`` defaults to the BASE_URL environment variable. Paths are ``<base>/api/...``.
Exit code 0 only if every scenario ended as expected.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import uuid
from collections import Counter
from pathlib import Path

import httpx

ROOT = Path(__file__).resolve().parents[2]
SCENARIOS = ROOT / "scenarios"
MAX_TURNS = 12
FILLER = "No, nothing else."
EXPECT = {"S1": "ready", "S3": "ready", "S7": "urgent"}
MESSAGE_TIMEOUT_S = 170.0


def load(sid: str) -> dict:
    return json.loads((SCENARIOS / f"{sid}.json").read_text(encoding="utf-8"))


def token(client: httpx.Client, role: str) -> dict:
    res = client.post("/api/login", json={"role": role})
    res.raise_for_status()
    return {"Authorization": f"Bearer {res.json()['token']}"}


def send(client: httpx.Client, headers: dict, sid: str, text: str, mid: str) -> tuple[httpx.Response | None, float, str]:
    start = time.monotonic()
    try:
        res = client.post(f"/api/sessions/{sid}/messages", json={"text": text, "client_message_id": mid},
                          headers=headers, timeout=MESSAGE_TIMEOUT_S)
        return res, time.monotonic() - start, ""
    except httpx.HTTPError as exc:
        return None, time.monotonic() - start, type(exc).__name__


def run_scenario(client: httpx.Client, patient: dict, doctor: dict, scenario: str) -> bool:
    s = load(scenario)
    expected = EXPECT[scenario]
    print(f"\n=== {scenario} ({s['summary']}) -> expect {expected}")
    res = client.post("/api/sessions", json={"scenario_id": scenario}, headers=patient)
    res.raise_for_status()
    sid = res.json()["session_id"]
    print(f"session {sid} mode={res.json()['mode']}")
    paths: Counter[str] = Counter()
    final: dict = {}
    for i in range(MAX_TURNS):
        if i >= len(s["turns"]) and expected == "urgent":
            break
        text = s["turns"][i] if i < len(s["turns"]) else FILLER
        mid = f"live-{uuid.uuid4().hex[:12]}"
        r, secs, exc = send(client, patient, sid, text, mid)
        if r is None or r.status_code >= 500:
            label = exc or f"HTTP {r.status_code} {r.json().get('error') if r is not None else ''}"
            print(f"turn {i + 1:2d}: {label} after {secs:5.1f}s -> resending once (same client_message_id)")
            time.sleep(3)
            r, secs, exc = send(client, patient, sid, text, mid)
        if r is None:
            print(f"turn {i + 1:2d}: {exc} after {secs:5.1f}s; giving up on this scenario")
            break
        body = r.json() if r.headers.get("content-type", "").startswith("application/json") else {}
        if r.status_code != 200:
            print(f"turn {i + 1:2d}: HTTP {r.status_code} {body.get('error')} ({body.get('detail')}) after {secs:5.1f}s")
            if r.status_code == 409:
                final = {"status": body.get("status")}
                break
            continue
        paths[str(body.get("parse_path"))] += 1
        extra = f" brief_parse_path={body.get('brief_parse_path')}" if body.get("brief_parse_path") else ""
        print(f"turn {i + 1:2d}: HTTP 200 {secs:5.1f}s parse_path={str(body.get('parse_path')):10s} "
              f"status={body['status']:11s} progress={body['progress']:.2f}{extra}")
        final = body
        if body.get("done"):
            break

    status = final.get("status")
    ok = status == expected
    if expected == "urgent":
        rule = (final.get("urgent") or {}).get("rule_id")
        print(f"result: status={status} rule={rule}")
        ok = ok and rule == s["expected"].get("rule_id")
    else:
        b = client.get(f"/api/sessions/{sid}/brief", headers=doctor)
        if b.status_code != 200:
            print(f"result: status={status}; no brief (HTTP {b.status_code})")
            ok = False
        else:
            brief = b.json()
            urls = {e["url"] for e in brief["evidence"]}
            lines = brief["brief"]["screenings_possibly_due"]
            cited = [x["source_url"] for x in lines if x.get("source_url")]
            bad = [u for u in cited if u not in urls]
            prov = brief["provenance"]
            print(f"result: status={status} brief=yes source={prov.get('source', 'model')} "
                  f"generated_by={prov['generated_by']!r} citations={len(cited)} "
                  f"(evidence passages={len(urls)}, uncited/unknown={len(bad)}) review_status={prov['review_status']}")
            ok = ok and not bad
    trust = client.get(f"/api/sessions/{sid}/trust", headers=doctor)
    if trust.status_code == 200:
        events = trust.json()["events"]
        summary = Counter(
            f"{e['node']}:{e['outcome']}:{e['evidence'].get('parse_path') or e['evidence'].get('error') or '-'}"
            for e in events
        )
        modes = Counter(e["evidence"].get("json_mode") for e in events if e["evidence"].get("json_mode"))
        print("trust events:", dict(sorted(summary.items())))
        if modes:
            print("json_mode:", dict(modes))
    print(f"parse paths: {dict(paths)} -> {'PASS' if ok else 'FAIL'}")
    return ok


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--base", default=os.environ.get("BASE_URL"), help="server base URL (default: $BASE_URL)")
    ap.add_argument("--scenarios", default="S1,S3,S7", help="comma-separated subset of S1,S3,S7")
    args = ap.parse_args()
    if not args.base:
        ap.error("--base or BASE_URL is required")
    with httpx.Client(base_url=args.base.rstrip("/"), timeout=30.0) as client:
        health = client.get("/api/healthz").json()
        print(f"server: mode={health['mode']} fake_model={health.get('fake_model')} "
              f"trustedrouter_configured={health['trustedrouter_configured']}")
        patient, doctor = token(client, "patient"), token(client, "doctor")
        results = {sc: run_scenario(client, patient, doctor, sc) for sc in args.scenarios.split(",")}
    print("\nSUMMARY:", ", ".join(f"{k}={'PASS' if v else 'FAIL'}" for k, v in results.items()))
    return 0 if all(results.values()) else 1


if __name__ == "__main__":
    sys.exit(main())
