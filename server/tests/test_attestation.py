"""Gateway attestation tests. HTTP mocked with respx; no real network."""

import base64
import json

import httpx
import pytest
import respx

from app import attestation
from app.attestation import (
    ATTESTATION_URL,
    EXPECTED_AUDIENCE,
    EXPECTED_ISSUER,
    clear_cache,
    fetch_gateway_attestation,
)


def _b64(obj) -> str:
    return base64.urlsafe_b64encode(json.dumps(obj).encode()).decode().rstrip("=")


def _jwt(claims: dict) -> str:
    return f"{_b64({'alg': 'RS256', 'typ': 'JWT'})}.{_b64(claims)}.c2ln"


GOOD_CLAIMS = {
    "iss": EXPECTED_ISSUER,
    "aud": EXPECTED_AUDIENCE,
    "exp": 2000000000,
    "submods": {
        "container": {
            "image_digest": "sha256:" + "ab" * 32,
            "env": {"SOURCE_COMMIT": "0123abcd"},
        }
    },
}


@pytest.fixture(autouse=True)
def _fresh_cache():
    clear_cache()
    yield
    clear_cache()


@respx.mock
def test_good_jwt_claims_parsed():
    respx.get(ATTESTATION_URL).mock(return_value=httpx.Response(200, text=_jwt(GOOD_CLAIMS)))
    result = fetch_gateway_attestation(httpx.Client())
    assert result["status"] == "ok"
    assert result["issuer"] == EXPECTED_ISSUER
    assert result["audience"] == EXPECTED_AUDIENCE
    assert result["verified_claims"] is True
    assert result["signature_verified"] is False
    assert result["image_digest"] == "sha256:" + "ab" * 32
    assert result["source_commit"] == "0123abcd"
    assert result["raw_claims"] == GOOD_CLAIMS
    assert result["fetched_at"]


@respx.mock
def test_json_wrapped_token_with_published_fields():
    body = {"token": _jwt({"iss": EXPECTED_ISSUER, "aud": [EXPECTED_AUDIENCE]}),
            "image_digest": "sha256:ff", "source_commit": "beef"}
    respx.get(ATTESTATION_URL).mock(return_value=httpx.Response(200, json=body))
    result = fetch_gateway_attestation(httpx.Client())
    assert result["verified_claims"] is True
    assert result["image_digest"] == "sha256:ff"
    assert result["source_commit"] == "beef"


@respx.mock
def test_wrong_issuer_is_not_verified():
    claims = {**GOOD_CLAIMS, "iss": "https://evil.example"}
    respx.get(ATTESTATION_URL).mock(return_value=httpx.Response(200, text=_jwt(claims)))
    result = fetch_gateway_attestation(httpx.Client())
    assert result["status"] == "ok"
    assert result["verified_claims"] is False


@respx.mock
def test_wrong_audience_is_not_verified():
    claims = {**GOOD_CLAIMS, "aud": "someone-else"}
    respx.get(ATTESTATION_URL).mock(return_value=httpx.Response(200, text=_jwt(claims)))
    assert fetch_gateway_attestation(httpx.Client())["verified_claims"] is False


@respx.mock
def test_network_error_returns_unavailable_and_never_raises():
    respx.get(ATTESTATION_URL).mock(side_effect=httpx.ConnectError("down"))
    result = fetch_gateway_attestation(httpx.Client())
    assert result["status"] == "unavailable"
    assert result["verified_claims"] is False


@respx.mock
def test_http_error_and_garbage_return_unavailable():
    respx.get(ATTESTATION_URL).mock(side_effect=[
        httpx.Response(500, text="oops"),
        httpx.Response(200, text="not-a-jwt"),
    ])
    assert fetch_gateway_attestation(httpx.Client())["status"] == "unavailable"
    assert fetch_gateway_attestation(httpx.Client())["status"] == "unavailable"


@respx.mock
def test_success_is_cached_for_ten_minutes(monkeypatch):
    route = respx.get(ATTESTATION_URL).mock(return_value=httpx.Response(200, text=_jwt(GOOD_CLAIMS)))
    now = [1000.0]
    monkeypatch.setattr(attestation.time, "monotonic", lambda: now[0])
    first = fetch_gateway_attestation(httpx.Client())
    now[0] += 599
    assert fetch_gateway_attestation(httpx.Client()) is first
    assert route.call_count == 1
    now[0] += 2
    fetch_gateway_attestation(httpx.Client())
    assert route.call_count == 2
