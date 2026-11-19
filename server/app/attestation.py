"""Gateway attestation for the Privacy & Trust panel (D03).

Fetches TrustedRouter's published attestation (a Google Confidential Space JWT) and
reports its claims. The JWT signature is NOT verified here: ``verified_claims`` only
means ``iss`` and ``aud`` match the expected values. The panel must say so.

Never raises: on any failure it returns ``{"status": "unavailable", ...}``.
"""

from __future__ import annotations

import base64
import json
import threading
import time
from datetime import datetime, timezone
from typing import Any

import httpx

ATTESTATION_URL = "https://api.trustedrouter.com/attestation"
EXPECTED_ISSUER = "https://confidentialcomputing.googleapis.com"
EXPECTED_AUDIENCE = "quill-cloud"
CACHE_TTL_S = 600.0
_TIMEOUT_S = 10.0

_cache: dict[str, Any] = {"value": None, "at": 0.0}
_lock = threading.Lock()


def clear_cache() -> None:
    with _lock:
        _cache["value"] = None
        _cache["at"] = 0.0


def fetch_gateway_attestation(http: httpx.Client | None = None) -> dict:
    """Return the gateway attestation summary, cached for 10 minutes on success."""
    with _lock:
        cached = _cache["value"]
        if cached is not None and time.monotonic() - _cache["at"] < CACHE_TTL_S:
            return cached
    try:
        result = _fetch(http)
    except Exception as exc:  # never raise to the UI
        return {
            "status": "unavailable",
            "error": type(exc).__name__,
            "issuer": None,
            "audience": None,
            "verified_claims": False,
            "fetched_at": _now(),
        }
    with _lock:
        _cache["value"] = result
        _cache["at"] = time.monotonic()
    return result


def _fetch(http: httpx.Client | None) -> dict:
    own = http is None
    client = http or httpx.Client(timeout=_TIMEOUT_S)
    try:
        res = client.get(ATTESTATION_URL)
        res.raise_for_status()
    finally:
        if own:
            client.close()

    token, extra = _token_from_response(res)
    claims = decode_jwt_claims(token)
    issuer = claims.get("iss")
    audience = claims.get("aud")
    aud_ok = audience == EXPECTED_AUDIENCE or (isinstance(audience, list) and EXPECTED_AUDIENCE in audience)
    container = (claims.get("submods") or {}).get("container") or {}

    result: dict[str, Any] = {
        "status": "ok",
        "issuer": issuer,
        "audience": audience,
        "verified_claims": issuer == EXPECTED_ISSUER and aud_ok,
        "signature_verified": False,
        "verification_note": "Issuer and audience checked; JWT signature not verified by Bloom.",
        "fetched_at": _now(),
        "raw_claims": claims,
    }
    image_digest = extra.get("image_digest") or container.get("image_digest")
    source_commit = extra.get("source_commit") or _source_commit_from_claims(container)
    if image_digest:
        result["image_digest"] = image_digest
    if source_commit:
        result["source_commit"] = source_commit
    if isinstance(claims.get("exp"), (int, float)):
        result["expires_at"] = datetime.fromtimestamp(claims["exp"], timezone.utc).isoformat()
    return result


def _token_from_response(res: httpx.Response) -> tuple[str, dict]:
    """The endpoint returns a JWT. Accept a bare token or a JSON wrapper around it."""
    text = res.text.strip()
    if text.startswith("{"):
        body = res.json()
        token = next(
            (body[k] for k in ("token", "jwt", "attestation", "attestation_token") if isinstance(body.get(k), str)),
            None,
        )
        if token is None:
            raise ValueError("no token in attestation response")
        extra = {k: body[k] for k in ("image_digest", "source_commit") if isinstance(body.get(k), str)}
        return token.strip(), extra
    return text.strip('"'), {}


def decode_jwt_claims(token: str) -> dict:
    """Decode a JWT payload without verifying its signature."""
    parts = token.split(".")
    if len(parts) != 3:
        raise ValueError("not a JWT")
    payload = parts[1] + "=" * (-len(parts[1]) % 4)
    claims = json.loads(base64.urlsafe_b64decode(payload.encode()))
    if not isinstance(claims, dict):
        raise ValueError("JWT payload is not an object")
    return claims


def _source_commit_from_claims(container: dict) -> str | None:
    for source in (container.get("env") or {}, container.get("image_reference_labels") or {}, container):
        if not isinstance(source, dict):
            continue
        for key in ("SOURCE_COMMIT", "source_commit", "org.opencontainers.image.revision"):
            if isinstance(source.get(key), str):
                return source[key]
    return None


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()
