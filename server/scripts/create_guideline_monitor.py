"""Create Context.dev Monitors on the guideline URLs cited by the scenario evidence cache.

Not run automatically. Usage (from server/):

    CONTEXT_DEV_API_KEY=... BLOOM_WEBHOOK_URL=https://<host>/api/webhooks/context-monitor \\
        uv run python scripts/create_guideline_monitor.py [--dry-run]

API (https://docs.context.dev/api-reference/monitors/create.md): ``POST /v1/monitors`` with a
``page`` target watches one URL, so this creates one monitor per guideline URL. Each response
carries ``id`` and ``webhook.secret``. This script prints the monitor ids only. Copy the
secret from the Context.dev dashboard (or rerun with --show-secret on a private terminal)
into CONTEXT_DEV_WEBHOOK_SECRET in .env, comma-separated when the monitors return
different secrets (the server accepts any of them).

Only public guideline URLs on the allowlist are sent. No patient data.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import httpx

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.config import Settings  # noqa: E402
from app.retrieve import DEFAULT_CACHE_DIR, host_allowed  # noqa: E402

MONITORS_URL = "https://api.context.dev/v1/monitors"


def guideline_urls(cache_dir: Path, domains: list[str]) -> list[str]:
    urls: list[str] = []
    for path in sorted(cache_dir.glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        for r in data.get("results", []):
            url = r.get("url")
            if isinstance(url, str) and host_allowed(url, domains) and url not in urls:
                urls.append(url)
    return urls


def monitor_body(url: str, webhook_url: str) -> dict:
    return {
        "mode": "web",
        "name": f"Bloom guideline: {url[:150]}",
        "tags": ["bloom", "guideline"],
        "target": {"type": "page", "url": url},
        "schedule": {"type": "interval", "frequency": 1, "unit": "days"},
        "webhook": {"url": webhook_url, "events": ["change.detected"], "retry": {}},
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--dry-run", action="store_true", help="print request bodies, send nothing")
    ap.add_argument("--show-secret", action="store_true", help="also print webhook secrets")
    args = ap.parse_args()

    settings = Settings()
    urls = guideline_urls(DEFAULT_CACHE_DIR, settings.guideline_domain_list)
    if not urls:
        print("No allowlisted guideline URLs found in", DEFAULT_CACHE_DIR)
        return 1
    webhook_url = os.environ.get("BLOOM_WEBHOOK_URL", "")
    if not webhook_url.startswith("https://"):
        print("Set BLOOM_WEBHOOK_URL to the public https URL of /api/webhooks/context-monitor")
        return 1

    if args.dry_run:
        for url in urls:
            print(json.dumps(monitor_body(url, webhook_url), indent=2))
        return 0

    key = os.environ.get("CONTEXT_DEV_API_KEY", "")
    if not key:
        print("Set CONTEXT_DEV_API_KEY in the environment")
        return 1

    secrets_seen: set[str] = set()
    with httpx.Client(timeout=30.0, headers={"Authorization": f"Bearer {key}"}) as http:
        for url in urls:
            resp = http.post(MONITORS_URL, json=monitor_body(url, webhook_url))
            if resp.status_code != 201:
                err = resp.json() if resp.headers.get("content-type", "").startswith("application/json") else {}
                print(f"FAILED {resp.status_code} {url} error_code={err.get('error_code')} request_id={err.get('request_id')}")
                continue
            data = resp.json()
            secret = (data.get("webhook") or {}).get("secret") or ""
            if secret:
                secrets_seen.add(secret)
            print(f"monitor_id={data['id']} url={url} initial_run_id={data.get('initial_run_id')}")
            if args.show_secret and secret:
                print(f"  webhook.secret={secret}")
    if len(secrets_seen) > 1:
        print(f"Note: {len(secrets_seen)} different webhook secrets; put all of them, comma-separated, "
              "in CONTEXT_DEV_WEBHOOK_SECRET.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
