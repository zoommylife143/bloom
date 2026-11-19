# Agent 01: model router and attestation (build step 2)

## Goal
Build `server/app/router.py`: the one function every LLM node uses. It sends chat completions to TrustedRouter, enforces the privacy floor from server config, records a TrustEvent for every call, and fails closed. Also build `server/app/attestation.py`, which fetches the gateway's published attestation for the Privacy & Trust panel (D03).

## Read first
- `CLAUDE.md`, `docs/agent-prompts/README.md` (shared rules)
- `server/app/config.py`, `server/app/models.py` (TrustEvent, TrustOutcome)
- Facts checked on 2026-11-19:
  - Base URL `https://api.trustedrouter.com/v1`, OpenAI-compatible; bearer key `TRUSTEDROUTER_API_KEY`.
  - Model `fortanix/glm-5.3-flash`. Its route is ZDR (operator-declared), not confidential.
  - Privacy floor goes in the request body: `extra_body={"provider": {"min_privacy": "zdr" | "confidential", "allow_fallbacks": False}}`. Pin a provider with `"only": ["<slug>"]`.
  - If no route meets the floor, TrustedRouter returns HTTP **400 before inference** ("never a downgrade"). The exact error body for this case isn't documented.
  - Attestation: `GET https://api.trustedrouter.com/attestation` returns a JWT; issuer `https://confidentialcomputing.googleapis.com`, audience `quill-cloud`. The trust page also publishes `image_digest` and `source_commit`.
  - Docs: https://trustedrouter.com/docs/provider-routing, https://trustedrouter.com/trust, https://trustedrouter.com/api/reference (fetch the API reference to find request-ID, receipt or route headers; record what you find).

## Build
1. `class ConfidentialRouteUnavailable(Exception)`, carrying the TrustEvent.
2. `class ModelRouter`:
   - `__init__(self, settings: Settings, client: OpenAI | None = None, on_event: Callable[[TrustEvent], None] | None = None)`
   - `complete(self, messages: list[dict], *, node: str, session_id: str | None = None, json_mode: bool = True) -> tuple[str, TrustEvent]`
   - dev mode: `model=settings.tr_model_id`, `min_privacy="zdr"`, `allow_fallbacks=False`.
   - private mode: `model=settings.private_model_id`, `min_privacy="confidential"`, `allow_fallbacks=False`. If `private_model_id` is empty, raise `ConfidentialRouteUnavailable` **without** any network call.
   - On HTTP 400 that is a privacy/route rejection (or any 400 while min_privacy is confidential): record outcome=refused, call `on_event`, raise `ConfidentialRouteUnavailable`. **Never** retry or call another model.
   - Other errors: outcome=error, raise a `ModelCallError`. At most one retry, and only for JSON parse failure in dev mode (plan §13), never after a refusal.
   - Use `with_raw_response` to capture headers. Put any receipt, request-ID, provider or route headers into `TrustEvent.evidence` / `request_id` / `route`. Never store prompt or output text in the event.
   - `latency_ms` measured around the call.
   - `json_mode`: send `response_format={"type": "json_object"}` only if the route supports it; if TrustedRouter filters routes on it and that could cause a 400, prefer plain JSON-in-text and parse it yourself. Document what you chose.
3. `negative_test(self, session_id: str | None) -> TrustEvent`: the D05 demo. Calls `tr_model_id` pinned with `only=[settings.tr_negative_test_provider]` and `min_privacy="confidential"`, expects the 400, returns the refused TrustEvent. Exactly one HTTP call.
4. `attestation.py`: `fetch_gateway_attestation(http: httpx.Client | None = None) -> dict` returning `{issuer, audience, image_digest?, source_commit?, fetched_at, verified_claims: bool, raw_claims}`. Decode the JWT payload without signature verification, but check `iss` and `aud` and say so in the result (`verified_claims` means the claims match, not that the signature was verified). Cache it for 10 minutes. On failure return `{"status": "unavailable", ...}` and never raise to the UI.
5. A dev script `server/scripts/hello_trustedrouter.py` that makes one real call and writes the headers and body to `docs/trustedrouter-response-sample.json` with the key and any auth headers redacted. Don't run it (there may be no key); just make it correct.

## Tests (`server/tests/test_router.py`, `test_attestation.py`)
- dev mode sends `min_privacy="zdr"` and `allow_fallbacks=False` with the right model.
- private mode with empty `private_model_id` raises with **zero** HTTP calls.
- private mode and a 400 refusal: raises `ConfidentialRouteUnavailable`, outcome=refused, `on_event` called once, and **exactly one** HTTP call was made (the F8 test).
- negative_test makes exactly one call and returns outcome=refused.
- TrustEvent never contains message text (assert a planted phrase is absent from `event.model_dump_json()`).
- attestation: good JWT → claims parsed; wrong issuer → `verified_claims` false; network error → status unavailable.
Mock with respx (httpx under the OpenAI SDK) or an injected fake client. No real network in tests.

## Done when
`cd server && uv run pytest -q` passes, including the existing tests. Report per the README format, including which TrustedRouter headers you found in the API reference.
