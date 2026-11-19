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

json_mode (changed 2026-11-19 after 60-80 % of live intake answers came back as prose):

* Dev mode sends ``response_format={"type": "json_object"}`` when ``TR_JSON_MODE`` is on
  (default). TrustedRouter filters routes on ``response_format``, so the gateway may
  answer 400. A 400 that is not the documented privacy refusal is then retried once
  without it; when that retry is served, the router stops sending it for the rest of
  the process. Private mode never sends it (a 400 there must stay an unambiguous,
  fail-closed refusal).
* The text is still parsed defensively (``json_candidates``: bare, fenced or embedded,
  last valid object wins) and checked with the caller's ``validate``.
* A parse / schema failure gets at most one *repair* call, in dev mode only, and only if
  the turn budget has at least ``REPAIR_MIN_BUDGET_S`` left: the same model gets its bad
  output back plus "reply with the JSON object only". Same model, same privacy floor.
* Every ok event carries ``evidence.parse_path`` = ``first_pass`` or ``repair`` and
  ``evidence.json_mode`` = ``json_object`` / ``off`` / ``dropped_after_400``.

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
import contextlib
import json
import re
import threading
import time
from collections.abc import Callable, Iterator
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


JSON_OBJECT = {"type": "json_object"}
REPAIR_INSTRUCTION = (
    "Your last answer was not one valid JSON object with the required keys. Reply again with "
    "ONE JSON object only: no prose, no markdown fences, no text before or after it."
)
_REPAIR_MAX_CHARS = 4000
# A repair call is skipped when less than this is left of the turn budget, so the
# deterministic fallback (and on a final turn, the brief) still has time.
REPAIR_MIN_BUDGET_S = 15.0
# Words in a 400 body that suggest the gateway rejected response_format itself (or found
# no route that supports it), as opposed to e.g. a context-length error.
_JSON_MODE_MARKERS = ("response_format", "json")


# Temporary provider overloads that dev mode retries once (same model, after a pause).
OVERLOAD_STATUSES = frozenset({429, 503, 529})


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


class JsonModeRejected(ModelCallError):
    """Internal: a 400 to a request that carried ``response_format``. Retried without it."""


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
        self._overload_backoff_s = 2.0
        self._timeout_s = settings.tr_timeout_s
        self._local = threading.local()  # per-request deadline (FastAPI runs sync routes in threads)
        # Set once a json_object request was rejected (400) and the same request without it
        # was served. Process-wide: the router is built once per server process.
        self.json_mode_rejected = False

    @contextlib.contextmanager
    def deadline(self, seconds: float) -> Iterator[None]:
        """Bound every model call made inside the block (this thread) to ``seconds`` of wall
        time in total. A call that would start with less than 1 s left fails fast with a
        ``turn_deadline_exceeded`` error event instead of being sent."""
        previous = getattr(self._local, "deadline", None)
        self._local.deadline = time.monotonic() + seconds
        try:
            yield
        finally:
            self._local.deadline = previous

    def _remaining(self) -> float | None:
        deadline = getattr(self._local, "deadline", None)
        return None if deadline is None else deadline - time.monotonic()

    # ------------------------------------------------------------------ public

    def complete(
        self,
        messages: list[dict],
        *,
        node: str,
        session_id: str | None = None,
        json_mode: bool = True,
        validate: Callable[[str], Any] | None = None,
    ) -> tuple[str, TrustEvent]:
        """Send one chat completion (plus, in dev mode, at most one repair call).
        Returns (text, ok TrustEvent).

        With ``json_mode`` the returned text is the extracted JSON object; with
        ``validate`` (raises ``ValueError`` / ``ValidationError`` on a bad shape) it is
        the last object in the answer that passes it. The ok event's evidence says
        ``parse_path``: ``first_pass`` or ``repair``. Raises
        ``ConfidentialRouteUnavailable`` on a refusal, ``ModelCallError`` otherwise; a
        format failure has ``evidence.error`` ``json_parse_failed`` or
        ``schema_validation_failed``.
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
        kw = dict(model=model, provider=provider, node=node, session_id=session_id, mode=mode)
        if not json_mode:
            text, event = self._call_dev_overload_retry(messages, **kw)
            self._emit(event)
            return text, event

        send_json_mode = mode == "dev" and self.settings.tr_json_mode
        text, event = self._json_call(messages, send_json_mode, **kw)
        found, error = _first_valid(text, validate)
        if found is not None:
            event = _with_evidence(event, parse_path="first_pass")
            self._emit(event)
            return found, event
        bad = self._format_error(event, error, attempt=1, text=text)
        remaining = self._remaining()
        # Dev mode only: one repair call (plan section 13). Private mode: no retry at all.
        if mode != "dev" or (remaining is not None and remaining < REPAIR_MIN_BUDGET_S):
            if mode == "dev":
                bad = _with_evidence(bad, repair_skipped="turn_budget_low")
            self._emit(bad)
            raise ModelCallError(bad, "model output was not valid JSON")
        self._emit(bad)
        repair = [
            *messages,
            {"role": "assistant", "content": text[:_REPAIR_MAX_CHARS] if text.strip() else "(empty answer)"},
            {"role": "user", "content": REPAIR_INSTRUCTION},
        ]
        text2, event2 = self._json_call(repair, send_json_mode, **kw)
        found, error = _first_valid(text2, validate)
        if found is not None:
            event2 = _with_evidence(event2, parse_path="repair")
            self._emit(event2)
            return found, event2
        bad2 = self._format_error(event2, error, attempt=2, text=text2)
        self._emit(bad2)
        raise ModelCallError(bad2, "model output was not valid JSON")

    def _format_error(self, event: TrustEvent, error: str, *, attempt: int, text: str) -> TrustEvent:
        # Lengths only, never the text: tells "empty" from "prose" in the D03 panel.
        return event.model_copy(update={
            "outcome": TrustOutcome.ERROR,
            "evidence": {**event.evidence, "error": error, "attempt": attempt, "content_chars": len(text)},
        })

    def _json_call(self, messages: list[dict], send_json_mode: bool, **kw: Any) -> tuple[str, TrustEvent]:
        """One logical call that asks for a JSON object. Sends ``response_format`` unless it
        is off or was rejected earlier in this process; a 400 to it is retried once
        without it (dev mode only; callers pass ``send_json_mode=False`` in private mode)."""
        if not send_json_mode:
            text, event = self._call_dev_overload_retry(messages, **kw)
            return text, _with_evidence(event, json_mode="off")
        if self.json_mode_rejected:
            text, event = self._call_dev_overload_retry(messages, **kw)
            return text, _with_evidence(event, json_mode="dropped_after_400")
        try:
            text, event = self._call_dev_overload_retry(messages, response_format=JSON_OBJECT, **kw)
            return text, _with_evidence(event, json_mode="json_object")
        except JsonModeRejected:
            pass  # error event already emitted
        text, event = self._call_dev_overload_retry(messages, **kw)
        self.json_mode_rejected = True  # served without it: stop sending it in this process
        return text, _with_evidence(event, json_mode="dropped_after_400")

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

    def _call_dev_overload_retry(self, messages: list[dict], **kw: Any) -> tuple[str, TrustEvent]:
        """``_call`` plus, in dev mode only, one retry of the same model after a
        temporary overload (HTTP 429/503/529). Private mode never retries, and a
        refusal (ConfidentialRouteUnavailable) is never caught here."""
        try:
            return self._call(messages, **kw)
        except ModelCallError as exc:
            status = exc.event.evidence.get("http_status")
            if kw["mode"] != "dev" or status not in OVERLOAD_STATUSES:
                raise
            exc_saved = exc
        remaining = self._remaining()
        if remaining is not None and remaining < self._overload_backoff_s + 1.0:
            raise exc_saved
        time.sleep(self._overload_backoff_s)
        return self._call(messages, **kw)

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
        response_format: dict | None = None,
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
        if self.settings.tr_reasoning_effort:
            kwargs["extra_body"]["reasoning"] = {"effort": self.settings.tr_reasoning_effort}
        if max_tokens is not None:
            kwargs["max_tokens"] = max_tokens
        if response_format is not None:
            kwargs["response_format"] = response_format
        if self.settings.tr_temperature is not None:
            kwargs["temperature"] = self.settings.tr_temperature
        timeout = self._timeout_s
        remaining = self._remaining()
        if remaining is not None:
            if remaining < 1.0:
                event = self._event(
                    node=node, session_id=session_id, mode=mode, model_id=model, policy=floor,
                    outcome=TrustOutcome.ERROR, evidence={"error": "turn_deadline_exceeded"}, latency_ms=0,
                )
                self._emit(event)
                raise ModelCallError(event, "turn time budget used up; no call made")
            timeout = min(timeout, remaining)
        kwargs["timeout"] = timeout

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
            if (
                response_format is not None and mode == "dev" and not any_400_is_refusal
                and evidence.get("error_code") != "confidential_privacy_required"
                and (_is_route_rejection(body_text) or any(m in body_text for m in _JSON_MODE_MARKERS))
            ):
                # Likely the json_object request itself (TrustedRouter filters routes on
                # response_format). The caller retries once without it, same model and floor.
                event = self._event(
                    node=node, session_id=session_id, mode=mode, model_id=model, policy=floor,
                    outcome=TrustOutcome.ERROR, evidence={**evidence, "json_mode": "rejected"},
                    latency_ms=latency, request_id=_request_id(exc.response.headers),
                )
                self._emit(event)
                raise JsonModeRejected(event, "gateway rejected response_format=json_object") from None
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
            choice = completion.choices[0]
            text = choice.message.content or ""
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
        if getattr(choice, "finish_reason", None):
            evidence["finish_reason"] = choice.finish_reason
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

def json_candidates(text: str) -> list[str]:
    """Every top-level JSON object in ``text`` (bare, fenced or embedded), in order."""
    stripped = text.strip()
    try:
        if isinstance(json.loads(stripped), dict):
            return [stripped]
    except (ValueError, TypeError):
        pass
    decoder = json.JSONDecoder()
    found: list[str] = []
    i = text.find("{")
    while i != -1:
        try:
            value, end = decoder.raw_decode(text, i)
        except ValueError:
            i = text.find("{", i + 1)
            continue
        if isinstance(value, dict):
            found.append(text[i:end])
            i = text.find("{", end)
        else:  # pragma: no cover - raw_decode at "{" always yields a dict
            i = text.find("{", i + 1)
    return found


def extract_json(text: str) -> str | None:
    """Return the JSON object in ``text`` (bare, fenced or embedded), or None.

    When the text holds several objects (prose plus a draft and a final object, seen
    live), the last complete top-level object wins.
    """
    found = json_candidates(text)
    return found[-1] if found else None


def _first_valid(text: str, validate: Callable[[str], Any] | None) -> tuple[str | None, str]:
    """(object text, "") for the last object that passes ``validate``, else (None, error)."""
    found = json_candidates(text)
    if not found:
        return None, "json_parse_failed"
    if validate is None:
        return found[-1], ""
    for candidate in reversed(found):
        try:
            validate(candidate)
        except ValueError:  # pydantic's ValidationError is a ValueError
            continue
        return candidate, ""
    return None, "schema_validation_failed"


def _with_evidence(event: TrustEvent, **extra: Any) -> TrustEvent:
    return event.model_copy(update={"evidence": {**event.evidence, **extra}})


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
