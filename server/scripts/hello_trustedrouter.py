"""Dev script: one real TrustedRouter call, saved as a redacted sample.

Usage (from server/, with TRUSTEDROUTER_API_KEY exported in the shell environment):

    uv run python scripts/hello_trustedrouter.py

Makes exactly one non-streaming chat completion to ``settings.tr_model_id`` with the
dev privacy floor (``min_privacy="zdr"``, ``allow_fallbacks=False``) and an inference
receipt requested, then writes the request (minus auth), response status, headers and
body to ``docs/trustedrouter-response-sample.json``. The API key and any auth or cookie
headers are redacted. The prompt is a fixed synthetic string, never patient data.

Use the saved headers to confirm which request-ID / provider / receipt headers the
gateway really returns, and the provider slug for ``TR_NEGATIVE_TEST_PROVIDER``.
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import httpx

SERVER_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SERVER_DIR))

from app.config import Settings  # noqa: E402

OUT_PATH = SERVER_DIR.parent / "docs" / "trustedrouter-response-sample.json"
REDACTED = "[REDACTED]"
_SENSITIVE_HEADERS = {
    "authorization",
    "proxy-authorization",
    "cookie",
    "set-cookie",
    "x-api-key",
    "api-key",
}


def redact_headers(headers: httpx.Headers | dict, secret: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for name, value in headers.items():
        lname = name.lower()
        if lname in _SENSITIVE_HEADERS:
            out[lname] = REDACTED
        else:
            out[lname] = redact_text(value, secret)
    return out


def redact_text(text: str, secret: str) -> str:
    return text.replace(secret, REDACTED) if secret else text


def main() -> int:
    settings = Settings()
    key = settings.trustedrouter_api_key
    if not key:
        print("TRUSTEDROUTER_API_KEY is not set in the environment; nothing sent.", file=sys.stderr)
        return 1

    url = settings.trustedrouter_base_url.rstrip("/") + "/chat/completions"
    request_headers = {
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "x-inference-receipt": "true",
    }
    payload = {
        "model": settings.tr_model_id,
        "messages": [
            {"role": "user", "content": 'Reply with the JSON object {"hello": "bloom"} and nothing else.'}
        ],
        "max_tokens": 32,
        "provider": {"min_privacy": "zdr", "allow_fallbacks": False},
    }

    with httpx.Client(timeout=60.0) as client:
        res = client.post(url, headers=request_headers, json=payload)

    try:
        body: object = res.json()
    except ValueError:
        body = res.text
    body_json = redact_text(json.dumps(body, indent=2), key)

    sample = {
        "captured_at": datetime.now(timezone.utc).isoformat(),
        "note": "Synthetic prompt. API key and auth/cookie headers redacted.",
        "request": {
            "method": "POST",
            "url": url,
            "headers": redact_headers(request_headers, key),
            "body": payload,
        },
        "response": {
            "status_code": res.status_code,
            "headers": redact_headers(res.headers, key),
            "body": json.loads(body_json),
        },
    }

    out = json.dumps(sample, indent=2)
    assert key not in out, "refusing to write: API key still present"
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(out + "\n")
    print(f"HTTP {res.status_code}; wrote {OUT_PATH}")
    return 0 if res.is_success else 2


if __name__ == "__main__":
    raise SystemExit(main())
