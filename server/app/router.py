"""Model router: the one entry point every LLM node uses (build step 2).

Every call goes to TrustedRouter (OpenAI-compatible) with a privacy floor taken from
server config, never from the client:

* dev mode     -> ``settings.tr_model_id``, ``min_privacy="zdr"`` (operator-declared
  zero data retention; this is not a confidential route).
* private mode -> ``settings.private_model_id``, ``min_privacy="confidential"``.

Both send ``allow_fallbacks=False``. Private mode fails closed: a refusal raises
``ConfidentialRouteUnavailable`` and nothing is retried or sent to another model.

Each call records one ``TrustEvent`` (metadata only, never prompt or output text) and
hands it to ``on_event``.

json_mode choice: TrustedRouter filters routes on ``response_format`` by default
(provider-routing docs), so sending it could remove the only route and cause a 400
that looks like a privacy refusal. We therefore never send ``response_format``. The
caller's prompt asks for JSON, and this module extracts and validates the JSON object
from the text. A parse failure gets at most one retry, in dev mode only.

Evidence (https://trustedrouter.com/docs/receipts, checked 2026-11-19): we send the
``x-inference-receipt: true`` request header, so TrustedRouter returns a signed receipt
(three-part JWS over the exact request and response bytes) in the
``x-inference-receipt`` response header for non-streaming calls. Its claims include
``rv``, ``iss``, ``iat``, ``jti`` (response ID), ``gen`` (generation ID), ``nonce``,
``route``, ``req`` / ``resp`` (SHA-256 hashes), ``model`` (requested / selected /
provider / endpoint) and ``upstream`` (verification tier). The receipt signature is not
verified here. The public docs name no request-ID or provider response header for chat
completions; we still keep ``x-generation-id``, any ``x-trustedrouter-*`` header and
common request-ID headers if they appear. Documented 400 code for a privacy-floor
failure: ``confidential_privacy_required`` (full body not documented).
"""

from __future__ import annotations

import base64
import json
import re
import time
from collections.abc import Callable
from typing import Any

import openai
from openai import OpenAI

from app.config import Settings
from app.models import TrustEvent, TrustOutcome

RECEIPT_HEADER = "x-inference-receipt"
_REQUEST_ID_HEADERS = ("x-request-id", "request-id", "x-trustedrouter-request-id")
_EVIDENCE_HEADER_PREFIXES = ("x-trustedrouter-",)
_EVIDENCE_HEADER_NAMES = (*_REQUEST_ID_HEADERS, "x-generation-id", "x-provider", "x-route")
# Words that mark a 400 as a routing / privacy-floor rejection. The exact body for
# "no route meets the floor" is not documented, so this is deliberately broad.
_ROUTE_REJECTION_MARKERS = (
    "privacy",
    "min_privacy",
    "confidential",
    "zdr",
    "route",
    "routing",
    "provider",
    "endpoint",
    "fallback",
    "no candidates",
    "confidential_privacy_required",  # error code named in the TrustedRouter docs
)
# Claims per https://trustedrouter.com/docs/receipts (payload type inference-receipt/1).
# req / resp are SHA-256 hashes of the exact bytes, never the text itself.
_RECEIPT_CLAIM_KEYS = (
    "rv", "iss", "iat", "exp", "jti", "gen", "nonce", "route", "model", "upstream",
    "req", "resp", "att_sha256", "policy", "tier",
)
_RECEIPT_ID_CLAIMS = ("rv", "jti", "gen", "iat", "exp", "iss", "req", "resp", "att_sha256")
_TIMEOUT_S = 60.0


class ConfidentialRouteUnavailable(Exception):
    """No route met the privacy floor (or private mode has no model). Fail closed."""

    def __init__(self, event: TrustEvent, message: str = "confidential route unavailable"):
        super().__init__(message)
        self.event = event


class ModelCallError(Exception):
    """Any other failure of a model call. Carries the error TrustEvent."""

    def __init__(self, event: TrustEvent, message: str = "model call failed"):
        super().__init__(message)
        self.event = event


class ModelRouter:
    def __init__(
        self,
        settings: Settings,
        client: OpenAI | None = None,
        on_event: Callable[[TrustEvent], None] | None = None,
    ):
        self.settings = settings
        base = client or OpenAI(
            api_key=settings.trustedrouter_api_key or "missing-key",
            base_url=settings.trustedrouter_base_url,
            timeout=_TIMEOUT_S,
        )
        # The SDK retries 429/5xx/connection errors by default. A retry is a second
        # model call, so it is switched off: every call here is exactly one request.
        self._client = base.with_options(max_retries=0)
        self._on_event = on_event

    # ------------------------------------------------------------------ public

    def complete(
        self,
        messages: list[dict],
        *,
        node: str,
        session_id: str | None = None,
        json_mode: bool = True,
    ) -> tuple[str, TrustEvent]:
        """Send one chat completion. Returns (text, ok TrustEvent).

        With ``json_mode`` the returned text is the extracted JSON object (validated).
        Raises ``ConfidentialRouteUnavailable`` on a refusal, ``ModelCallError`` otherwise.
        """
        mode = self.settings.bloom_mode
        if mode == "private":
            model, floor = self.settings.private_model_id, "confidential"
            if not model:
                event = self._event(
                    node=node, session_id=session_id, mode=mode, model_id=None,
                    policy=floor, outcome=TrustOutcome.REFUSED,
                    evidence={"reason": "private_model_id not configured; no call made"},
                )
                self._emit(event)
                raise ConfidentialRouteUnavailable(event, "private mode has no confidential model configured")
        else:
            model, floor = self.settings.tr_model_id, "zdr"

        provider = {"min_privacy": floor, "allow_fallbacks": False}
        # Dev mode only: one retry for a JSON parse failure (plan section 13).
        attempts = 2 if (json_mode and mode == "dev") else 1
        for attempt in range(1, attempts + 1):
            text, event = self._call(
                messages, model=model, provider=provider, node=node,
                session_id=session_id, mode=mode,
            )
            if not json_mode:
                self._emit(event)
                return text, event
            parsed = extract_json(text)
            if parsed is not None:
                self._emit(event)
                return parsed, event
            bad = event.model_copy(update={
                "outcome": TrustOutcome.ERROR,
                "evidence": {**event.evidence, "error": "json_parse_failed", "attempt": attempt},
            })
            self._emit(bad)
            if attempt == attempts:
                raise ModelCallError(bad, "model output was not valid JSON")
        raise AssertionError("unreachable")  # pragma: no cover

    def negative_test(self, session_id: str | None = None) -> TrustEvent:
        """D05 demo: ask for a confidential route on a provider that is only ZDR.

        Exactly one HTTP call. Expected result: TrustedRouter's 400, returned as a
        refused TrustEvent. Never raises; never returns model text.
        """
        provider = {
            "min_privacy": "confidential",
            "allow_fallbacks": False,
            "only": [self.settings.tr_negative_test_provider],
        }
        try:
            _, event = self._call(
                [{"role": "user", "content": "ping"}],
                model=self.settings.tr_model_id, provider=provider, node="negative_test",
                session_id=session_id, mode="private", max_tokens=1,
                any_400_is_refusal=True,
            )
        except ConfidentialRouteUnavailable as exc:
            return exc.event  # already emitted
        except ModelCallError as exc:
            return exc.event  # already emitted
        # Served even though it should not have been: report it loudly, as an error.
        event = event.model_copy(update={
            "outcome": TrustOutcome.ERROR,
            "evidence": {**event.evidence, "error": "expected_refusal_but_served"},
        })
        self._emit(event)
        return event

    # ----------------------------------------------------------------- private

    def _call(
        self,
        messages: list[dict],
        *,
        model: str,
        provider: dict,
        node: str,
        session_id: str | None,
        mode: str,
        max_tokens: int | None = None,
        any_400_is_refusal: bool = False,
    ) -> tuple[str, TrustEvent]:
        """One HTTP request. Returns (text, ok event, not yet emitted). Errors are
        emitted here and raised."""
        floor = provider["min_privacy"]
        kwargs: dict[str, Any] = {
            "model": model,
            "messages": messages,
            "extra_body": {"provider": provider},
            "extra_headers": {RECEIPT_HEADER: "true"},
        }
        if max_tokens is not None:
            kwargs["max_tokens"] = max_tokens

        start = time.perf_counter()
        try:
            raw = self._client.chat.completions.with_raw_response.create(**kwargs)
        except openai.BadRequestError as exc:
            latency = _ms(start)
            body_text = _error_text(exc)
            evidence = {
                "http_status": 400,
                **_error_evidence(exc, _message_texts(messages)),
                **_header_evidence(exc.response.headers),
            }
            refusal = any_400_is_refusal or floor == "confidential" or _is_route_rejection(body_text)
            event = self._event(
                node=node, session_id=session_id, mode=mode, model_id=model, policy=floor,
                outcome=TrustOutcome.REFUSED if refusal else TrustOutcome.ERROR,
                evidence=evidence, latency_ms=latency,
                request_id=_request_id(exc.response.headers),
            )
            self._emit(event)
            if refusal:
                raise ConfidentialRouteUnavailable(event, "gateway refused: no route meets the privacy floor") from None
            raise ModelCallError(event, "gateway rejected the request (400)") from None
        except openai.APIStatusError as exc:
            event = self._event(
                node=node, session_id=session_id, mode=mode, model_id=model, policy=floor,
                outcome=TrustOutcome.ERROR, latency_ms=_ms(start),
                evidence={
                    "http_status": exc.status_code,
                    **_error_evidence(exc, _message_texts(messages)),
                    **_header_evidence(exc.response.headers),
                },
                request_id=_request_id(exc.response.headers),
            )
            self._emit(event)
            raise ModelCallError(event, f"gateway returned HTTP {exc.status_code}") from None
        except openai.APIError as exc:  # connection, timeout, ...
            event = self._event(
                node=node, session_id=session_id, mode=mode, model_id=model, policy=floor,
                outcome=TrustOutcome.ERROR, latency_ms=_ms(start),
                evidence={"error": type(exc).__name__},
            )
            self._emit(event)
            raise ModelCallError(event, f"model call failed: {type(exc).__name__}") from None

        latency = _ms(start)
        headers = raw.headers
        try:
            completion = raw.parse()
            text = completion.choices[0].message.content or ""
        except Exception as exc:  # malformed success body
            event = self._event(
                node=node, session_id=session_id, mode=mode, model_id=model, policy=floor,
                outcome=TrustOutcome.ERROR, latency_ms=latency,
                evidence={"error": f"unparseable_response:{type(exc).__name__}", **_header_evidence(headers)},
                request_id=_request_id(headers),
            )
            self._emit(event)
            raise ModelCallError(event, "gateway returned an unparseable response") from None

        forbidden = _message_texts(messages) + [text]
        evidence = _header_evidence(headers)
        receipt = _receipt_evidence(headers.get(RECEIPT_HEADER), forbidden)
        if receipt:
            evidence["receipt"] = receipt
        if getattr(completion, "id", None):
            evidence["response_id"] = completion.id
        served_model = getattr(completion, "model", None)
        if served_model:
            evidence["served_model"] = served_model
        body_provider = (completion.model_extra or {}).get("provider") if hasattr(completion, "model_extra") else None
        if isinstance(body_provider, str):
            evidence["body_provider"] = body_provider

        event = self._event(
            node=node, session_id=session_id, mode=mode, model_id=model, policy=floor,
            outcome=TrustOutcome.OK, evidence=evidence, latency_ms=latency,
            request_id=_request_id(headers) or (receipt or {}).get("claims", {}).get("jti") or getattr(completion, "id", None),
            route=_route(receipt, body_provider, headers),
        )
        return text, event

    def _event(
        self, *, node: str, session_id: str | None, mode: str, model_id: str | None,
        policy: str, outcome: TrustOutcome, evidence: dict | None = None,
        latency_ms: int | None = None, request_id: str | None = None, route: str | None = None,
    ) -> TrustEvent:
        return TrustEvent(
            session_id=session_id, node=node, mode=mode, model_id=model_id, route=route,
            policy_required=policy, evidence=evidence or {}, request_id=request_id,
            latency_ms=latency_ms, outcome=outcome,
        )

    def _emit(self, event: TrustEvent) -> None:
        if self._on_event is not None:
            self._on_event(event)


# ---------------------------------------------------------------------- helpers

def extract_json(text: str) -> str | None:
    """Return the JSON object in ``text`` (bare, fenced or embedded), or None."""
    candidates = [text.strip()]
    fence = re.search(r"```(?:json)?\s*(.*?)```", text, re.DOTALL | re.IGNORECASE)
    if fence:
        candidates.append(fence.group(1).strip())
    first, last = text.find("{"), text.rfind("}")
    if 0 <= first < last:
        candidates.append(text[first : last + 1])
    for c in candidates:
        try:
            value = json.loads(c)
        except (ValueError, TypeError):
            continue
        if isinstance(value, dict):
            return c
    return None


def _ms(start: float) -> int:
    return int((time.perf_counter() - start) * 1000)


def _error_text(exc: openai.APIStatusError) -> str:
    body = exc.body
    try:
        return json.dumps(body).lower() if body is not None else str(exc).lower()
    except (TypeError, ValueError):
        return str(exc).lower()


def _is_route_rejection(body_text: str) -> bool:
    return any(marker in body_text for marker in _ROUTE_REJECTION_MARKERS)


def _message_texts(messages: list[dict]) -> list[str]:
    return [m["content"] for m in messages if isinstance(m.get("content"), str) and m["content"].strip()]


def _contains_any(haystack: str, needles: list[str]) -> bool:
    return any(n.strip() and n.strip() in haystack for n in needles)


def _error_evidence(exc: openai.APIStatusError, forbidden_texts: list[str]) -> dict:
    """Error code/type/message from the gateway, truncated. The message is dropped if
    it echoes any prompt text, so an event never carries clinical text."""
    out: dict[str, Any] = {}
    body = exc.body if isinstance(exc.body, dict) else {}
    err = body.get("error", body) if isinstance(body, dict) else {}
    if isinstance(err, dict):
        for key in ("code", "type"):
            if isinstance(err.get(key), (str, int)):
                out[f"error_{key}"] = err[key]
        if isinstance(err.get("message"), str):
            if _contains_any(err["message"], forbidden_texts):
                out["error_message_dropped"] = "message echoed request text"
            else:
                out["error_message"] = err["message"][:300]
    return out


def _header_evidence(headers: Any) -> dict:
    out: dict[str, str] = {}
    for name, value in headers.items():
        lname = name.lower()
        if lname == RECEIPT_HEADER:
            continue  # handled separately (decoded, checked)
        if lname in _EVIDENCE_HEADER_NAMES or lname.startswith(_EVIDENCE_HEADER_PREFIXES):
            out[lname] = value[:500]
    return {"headers": out} if out else {}


def _request_id(headers: Any) -> str | None:
    for name in _REQUEST_ID_HEADERS:
        if headers.get(name):
            return headers.get(name)
    return None


def _b64url_json(segment: str) -> Any:
    padded = segment + "=" * (-len(segment) % 4)
    return json.loads(base64.urlsafe_b64decode(padded.encode()))


def _receipt_evidence(token: str | None, forbidden_texts: list[str]) -> dict | None:
    """Decode the receipt JWS (no signature verification) and keep selected claims.

    The raw token is kept only when its decoded payload contains none of the prompt or
    output text, so an event can never carry clinical text even inside a receipt.
    """
    if not token:
        return None
    out: dict[str, Any] = {"signature_verified": False}
    parts = token.split(".")
    if len(parts) != 3:
        out["error"] = "malformed_receipt"
        return out
    try:
        header = _b64url_json(parts[0])
        payload_raw = base64.urlsafe_b64decode((parts[1] + "=" * (-len(parts[1]) % 4)).encode()).decode("utf-8", "replace")
        claims = json.loads(payload_raw) if payload_raw else {}
    except (ValueError, TypeError):
        out["error"] = "undecodable_receipt"
        return out
    if isinstance(header, dict) and isinstance(header.get("alg"), str):
        out["alg"] = header["alg"]
    if isinstance(claims, dict):
        out["claims"] = {k: claims[k] for k in _RECEIPT_CLAIM_KEYS if k in claims}
    leaks = _contains_any(payload_raw, forbidden_texts)
    if not leaks and len(token) <= 8192:
        out["jws"] = token
    elif leaks:
        out["jws_dropped"] = "payload contained message text"
    else:
        out["jws_dropped"] = "receipt too large"
    if leaks:
        # Selected claims could still carry text; keep only scalar identifiers.
        out["claims"] = {k: v for k, v in out.get("claims", {}).items() if k in _RECEIPT_ID_CLAIMS}
    return out


def _route(receipt: dict | None, body_provider: str | None, headers: Any) -> str | None:
    claims = (receipt or {}).get("claims") or {}
    model_claim = claims.get("model")
    if isinstance(model_claim, dict):
        for key in ("provider", "endpoint", "selected"):
            value = model_claim.get(key)
            if isinstance(value, str) and value:
                return value
    if isinstance(claims.get("route"), str) and claims["route"]:
        return claims["route"]
    if body_provider:
        return body_provider
    for name in ("x-trustedrouter-provider", "x-provider", "x-route"):
        if headers.get(name):
            return headers.get(name)
    return None
