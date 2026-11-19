# Bloom HTTP API contract

Source: `server/app/main.py` (Pydantic response models; live OpenAPI at `/docs` and `/openapi.json`). Shared types (`Brief`, `Provenance`, `EvidenceItem`, `TrustEvent`, `IntakeRecord`) come from `server/app/models.py`. Synthetic data only; the examples below come from the offline test harness.

## Conventions

- Base path: `/api`. JSON in and out. Timestamps are ISO 8601 UTC.
- Auth (demo only, not production auth): `POST /api/login` returns a token. Send `Authorization: Bearer <token>` on every other call except `/api/healthz`. Tokens last 12 h.
  - **patient or doctor token**: `POST /sessions`, `POST /sessions/{id}/messages`.
  - **doctor token only**: every other endpoint.
  - **no token, HMAC signature instead**: `POST /webhooks/context-monitor` (called by Context.dev, not by the apps).
- Errors always have this shape:

```json
{"error": "session_locked", "detail": "Session status is ready"}
```

| HTTP | `error` | When |
| --- | --- | --- |
| 401 | `unauthorized` | No token, bad signature or expired |
| 403 | `forbidden` | Patient token on a doctor endpoint |
| 404 | `session_not_found`, `brief_not_found`, `flag_not_found`, `scenario_not_found` | Unknown id, or brief not generated yet |
| 409 | `session_locked` | Message to a session that is `urgent`, `ready`, `approved`, `edited` or `rejected`. Body also has `status` and `urgent` (see messages) |
| 409 | `already_decided` | Second decision on a brief |
| 422 | `edited_brief_required` | `decision: "edit"` without `edited`. Schema errors (bad role, empty text) use FastAPI's own body `{"detail": [{"type", "loc", "msg", ...}]}` with no `error` key |
| 502 | `confidential_route_unavailable` | Privacy floor refused (P02 "route refused" state). Status unchanged, nothing sent to any other model. |
| 502 | `model_error` | Any other model failure (P02 "model error" state). Status unchanged; the patient can resend. |

- The server never sends 429 itself. A gateway 429/503/529 is retried once in dev mode and otherwise surfaces as 502 `model_error`.
- `SessionStatus`: `in_progress | urgent | ready | approved | edited | rejected`.
- `RedFlagRule`: `R1` ectopic, `R2` heavy bleeding, `R3` pelvic infection, `R4` pregnancy/postpartum warning, `R5` self-harm, `R6` sexual assault disclosure.

## Endpoints

### GET /api/healthz (no auth)

```json
{"ok": true, "mode": "dev", "trustedrouter_configured": true, "fake_model": false}
```

`mode` is `dev | private`, decided by the server. No key values are returned. `fake_model` is true only when the dev-only offline fake model is on (`BLOOM_FAKE_MODEL=1`, see "Contract check"); never demo with it.

### POST /api/login (no auth) — A01

Request `{"role": "patient" | "doctor"}` → 200:

```json
{"token": "eyJyb2xlIjoicGF0aWVudCIsImV4cCI6MTc5NTExOTU1NX0.8rZ6...", "role": "patient", "expires_at": 1795119555}
```

Errors: 422 for any other role.

### POST /api/sessions — P01 → P02

Request (body optional): `{"scenario_id": "S1"}` or `{}`. → 200:

```json
{
  "session_id": "a2fce7c46d4849b99d64a7df8f83337c",
  "mode": "dev",
  "status": "in_progress",
  "reply": "Hi, I'm Bloom. I'll ask you a few questions to help your care team get ready for your visit. You can skip any question. What brings you in today?",
  "progress": 0.0
}
```

`reply` is Bloom's first question (fixed text, no model call). Errors: 401.

### POST /api/sessions/{session_id}/messages — P02

Request `{"text": "I'd like a checkup.", "client_message_id": "c-3f2a..."}`. `text` is 1–4000 chars. `client_message_id` (optional, 1–64 chars) makes a resend safe: when a turn with the same id on the same session already succeeded, the server returns that stored response (HTTP 200, same body) without running the turn again or appending the message twice. A resend that arrives while the first request is still running waits for it. Reuse the id only for a resend of the same turn. → 200 `MessageResponse`:

| Field | Type | Notes |
| --- | --- | --- |
| `reply` | string | Bloom's next question, the closing line, or the urgent body |
| `status` | SessionStatus | `in_progress`, `urgent` (go to P03) or `ready` (go to P04) |
| `progress` | number 0–1 | 1.0 once `done` |
| `done` | bool | true when the patient flow ends (urgent or intake finished) |
| `urgent` | UrgentMessage or null | set only when `status == "urgent"` |
| `parse_path` | string or null | Optional diagnostics (new 2026-11-19; clients may ignore). How this turn's intake output was obtained: `first_pass` (model JSON), `repair` (model JSON after one repair call), `fallback` (fixed question, no model), `rule` (red flag, no model). Null when no intake ran (brief resume) |
| `brief_parse_path` | string or null | Optional diagnostics (new). Set only on the turn that drafted the brief: `first_pass`, `repair` or `fallback` (deterministic DRAFT, see GET brief) |

Normal turn:

```json
{"reply": "How old are you?", "status": "in_progress", "progress": 0.7, "done": false, "urgent": null, "parse_path": "first_pass", "brief_parse_path": null}
```

Last turn (brief drafted synchronously in the same request, target < 20 s):

```json
{"reply": "Thank you. That's everything I need. Your care team will read your answers before your visit.", "status": "ready", "progress": 1.0, "done": true, "urgent": null}
```

Red flag (P03). Show `urgent.title`, `urgent.body`, `urgent.support` if present, and one button per action (`tel:` link):

```json
{
  "reply": "Thank you for telling me. A fever together with pain low in your belly needs to be checked by a doctor soon. ...",
  "status": "urgent",
  "progress": 1.0,
  "done": true,
  "urgent": {
    "rule_id": "R3",
    "title": "Please get care today",
    "body": "Thank you for telling me. A fever together with pain low in your belly needs to be checked by a doctor soon. ...",
    "actions": [{"label": "Call 911", "tel": "tel:911"}, {"label": "Call or text 988", "tel": "tel:988"}],
    "support": null
  }
}
```

Errors: 401, 404 `session_not_found`, 409 `session_locked`, 422 (schema), 502 `confidential_route_unavailable` / `model_error`. After a 502 the turn was not saved; the client may resend the same text. If the intake had finished but the brief failed, the next message (any text) resumes at the brief step.

409 `session_locked` tells the client where the session ended, so a client whose earlier request timed out can still show the right screen (P03 for `urgent`, P04 otherwise):

```json
{"error": "session_locked", "detail": "Session status is urgent", "status": "urgent",
 "urgent": {"rule_id": "R2", "title": "Please get care now", "body": "...", "actions": [{"label": "Call 911", "tel": "tel:911"}], "support": null}}
```

`urgent` is null unless `status` is `urgent`.

Timing: one message makes at most a few model calls (intake, then on the last turn retrieval and the brief). All model calls of one turn share a wall-clock budget (`TURN_BUDGET_S`, default 110 s; one call at most `TR_TIMEOUT_S`, default 60 s). Guideline retrieval adds up to 10 s per query. Worst case for one request is about 150 s, under the nginx `/api/` read timeout (180 s). The Dart client waits 160 s for messages, session creation, the negative test and scenario runs, 30 s for everything else. `POST /demo/scenarios/{id}/run` replays several turns and can exceed the proxy timeout with a slow model.

Unusable model output (changed 2026-11-19). The server asks for a JSON object (`response_format: json_object` in dev mode when `TR_JSON_MODE` is on, default; a 400 to it is retried once without it and then no longer sent by that process), shows earlier Bloom turns to the model as the JSON object of that turn, sends `temperature` 0.2 by default (`TR_TEMPERATURE`), and in dev mode makes one *repair* call (the bad output plus "JSON only") if at least 15 s of the turn budget are left. If the intake output is still unusable, the turn still returns 200 with `parse_path: "fallback"`:

- The three required fields (reason for visit, age group, pregnancy possible) are read from the patient's answers with fixed rules.
- The reply is the fixed question for the NEXT required field that is still missing and was never asked. A question is never repeated.
- The intake ends (`status: "ready"`, brief drafted in the same request) as soon as the three fields are known, or when every missing one was asked once, or after 4 fallback turns; the 12-turn cap still applies. So an intake always finishes, even if every model answer is unusable.
- The audit log gets `intake_fallback_question`; the trust panel gets an `intake_fallback` event.

If the brief output is unusable after the repair call, or the turn budget ran out / the brief call timed out, the server stores a deterministic DRAFT built from the intake answers (`brief_parse_path: "fallback"`, see GET brief). Refusals and other HTTP errors never fall back: they still give 502 (`confidential_route_unavailable` / `model_error`), and an intake HTTP error or timeout still gives 502. The fallbacks call no model, so private mode stays fail-closed; they apply in both modes and can be switched off with `BLOOM_DETERMINISTIC_FALLBACK=0`.

### GET /api/sessions — D01 (doctor)

Red-flag sessions first, then newest first. → 200:

```json
{
  "sessions": [
    {
      "session_id": "a2fce7c46d4849b99d64a7df8f83337c",
      "scenario_id": null,
      "mode": "dev",
      "status": "ready",
      "created_at": "2026-11-19T08:19:15.726007Z",
      "updated_at": "2026-11-19T08:19:15.828223Z",
      "red_flag_rule": null,
      "brief_id": "e2c1795a18074c108438bb3ca524f095",
      "review_status": "draft",
      "age_band": "30-39",
      "reason_for_visit": "routine gynecology visit"
    }
  ]
}
```

`review_status`: `draft | approved | edited | rejected | null` (null = no brief yet). `reason_for_visit` is truncated to 120 chars.

### GET /api/sessions/{session_id}/brief — D02 (doctor)

→ 200 `BriefResponse`:

```json
{
  "brief_id": "e2c1795a18074c108438bb3ca524f095",
  "session_id": "a2fce7c46d4849b99d64a7df8f83337c",
  "brief": {
    "subjective": "Patient reports a routine visit request.",
    "objective": "Patient-reported data only; no exam yet.",
    "assessment_considerations": "Physician to consider cervical screening interval and irregular cycles.",
    "plan_considerations": "Consider screening per guideline.",
    "flags": [],
    "screenings_possibly_due": [
      {"text": "Cervical screening may be due", "source_url": "https://www.acog.org/guidance/8e2575ff"},
      {"text": "Uncited screening line (No guideline retrieved)", "source_url": null}
    ],
    "suggested_questions": ["When was your last screening?"]
  },
  "original_brief": { "...": "same shape; the AI draft, never overwritten" },
  "edited": false,
  "provenance": {
    "generated_by": "fortanix/glm-5.3-flash (dev)",
    "evidence_urls": ["https://www.acog.org/guidance/8e2575ff"],
    "source": "model",
    "created_at": "2026-11-19T08:19:15.828151Z",
    "review_status": "draft",
    "reviewed_by": null,
    "reviewed_at": null
  },
  "evidence": [
    {"query": "cervical cancer screening interval age 30-39 ...", "url": "https://www.acog.org/guidance/8e2575ff",
     "title": null, "passage": "...", "retrieved_at": "2026-11-19T08:19:15.8Z"}
  ],
  "guideline_updates": []
}
```

- `brief` is what to display: the edited version after an edit, else the draft.
- Every `screenings_possibly_due[].source_url` is one of `evidence[].url` or null. Null means show "No guideline retrieved" (D02 "no guideline" state). With no evidence at all there is one line `{"text": "No guideline retrieved", "source_url": null}`.
- `evidence[].title` is the page title from Context.dev and may be null.
- `provenance.source` (new 2026-11-19, default `"model"`): `"fallback"` means the model's brief output was unusable and the server built the draft deterministically from the intake answers, with no AI. Then `generated_by` is `"deterministic-fallback (<mode>)"`, `subjective`, `assessment_considerations` and `plan_considerations` start with `DRAFT (automatic fallback, written without AI: the model's answer was unusable).`, no assessment or plan is drafted, `flags` lists fields not recorded, and `screenings_possibly_due` lists only the retrieved passages (`"Retrieved guideline passage for physician review: <title>"`, `source_url` = an `evidence[].url`) or the single "No guideline retrieved" line. It is still a draft: Confirm / Edit / Reject work as usual. D02 should show a visible "fallback draft (no AI)" label when `source == "fallback"`.
- `guideline_updates` (optional, new; default `[]`): the `evidence[].url` values whose page a Context.dev Monitor reported as changed in the last 7 days. Non-empty means show the "guideline updated" banner on D02. Clients that ignore the field keep working. Also present on the decision response.

Errors: 401, 403, 404 `brief_not_found` (also while the intake is still running).

### POST /api/briefs/{brief_id}/decision — D02 Confirm / Edit / Reject (doctor)

Request:

```json
{"decision": "approve", "reviewer": "Dr. Demo"}
{"decision": "reject", "reviewer": "Dr. Demo"}
{"decision": "edit", "reviewer": "Dr. Demo", "edited": { "...": "full Brief object" }}
```

→ 200 `BriefResponse` (same shape as GET brief) with `provenance.review_status` = `approved | edited | rejected`, `reviewed_by`, `reviewed_at` set, and session `status` moved to the same value. On edit, `original_brief` keeps the AI draft and `brief` is the edited version.

Errors: 401, 403, 404 `brief_not_found`, 409 `already_decided`, 422 `edited_brief_required`.

### GET /api/sessions/{session_id}/trust — D03 (doctor)

→ 200:

```json
{
  "session_id": "a2fce7c46d4849b99d64a7df8f83337c",
  "mode": "dev",
  "events": [
    {
      "session_id": "a2fce7c46d4849b99d64a7df8f83337c",
      "node": "intake",
      "mode": "dev",
      "model_id": "fortanix/glm-5.3-flash",
      "route": null,
      "policy_required": "zdr",
      "evidence": {"response_id": "gen-test", "served_model": "fortanix/glm-5.3-flash"},
      "request_id": "gen-test",
      "latency_ms": 15,
      "outcome": "ok",
      "created_at": "2026-11-19T08:19:15.753883Z"
    }
  ],
  "attestation": {"status": "unavailable", "issuer": null, "audience": null, "verified_claims": false, "fetched_at": "..."}
}
```

- `events[].node`: `intake | brief | retrieve | negative_test | intake_fallback | brief_fallback`. The two `*_fallback` nodes (new) are not model calls: `model_id` null, `policy_required` `no_model_call`, `outcome` `ok`, `evidence.parse_path` `fallback`, `evidence.after_error` the format error that caused it. `outcome`: `ok | refused | error`. `policy_required`: `zdr` (dev), `confidential` (private), `deidentified_query` (retrieve, route `context.dev`).
- `evidence` may contain `receipt` (decoded TrustedRouter receipt claims; `signature_verified: false`), `headers`, `http_status`, `error_code`, `error`, `finish_reason`, `content_chars` (length of an unparseable answer, never its text). `error` values include `json_parse_failed`, `schema_validation_failed` and `turn_deadline_exceeded` (no call made: the turn budget was used up). New: ok model events carry `parse_path` (`first_pass` or `repair`) and `json_mode` (`json_object`, `off`, or `dropped_after_400`); a 400 to json_object mode is an `error` event with `json_mode: "rejected"`; a failed format event carries `attempt` (1 or 2) and may carry `repair_skipped: "turn_budget_low"`.
- `attestation` comes from `app/attestation.py`. `verified_claims` only means issuer and audience match; the JWT signature is not verified. Say so in the panel.

Errors: 401, 403, 404 `session_not_found`.

### GET /api/sessions/{session_id}/flag — D06 (doctor)

→ 200:

```json
{
  "session_id": "1b108d0c68484d419629ea53fdcf9e9d",
  "rule_id": "R3",
  "matched": ["fever", "pelvic pain"],
  "source": "text",
  "created_at": "2026-11-19T08:19:15.883855Z",
  "title": "Please get care today",
  "body": "Thank you for telling me. A fever together with pain low in your belly ..."
}
```

`matched` holds keyword labels or field names, never copied patient text. `source`: `text | fields`. Errors: 401, 403, 404 `flag_not_found`.

### GET /api/audit — D04 (doctor)

→ 200, newest first, up to 500 rows. Metadata only (actor, action, session id, time):

```json
{"rows": [{"id": 14, "actor": "doctor", "action": "brief_approved", "session_id": "a2fc...", "created_at": "2026-11-19T08:19:15.838482Z"}]}
```

`actor`: `patient | doctor | system | context.dev`. `action`: `login`, `session_created`, `message_received`, `reply_filtered`, `intake_fallback_question`, `red_flag_locked`, `intake_completed`, `brief_generated`, `brief_viewed`, `brief_approved`, `brief_edited`, `brief_rejected`, `route_refused`, `model_error`, `negative_test`, `scenario_run`, `guideline_monitor_webhook`.

### POST /api/demo/negative-test — D05 (doctor)

Request (optional) `{"session_id": "<id>"}` to attach the event to that session's D03 panel, or `{}`. → **200** with the refused `TrustEvent` (this is the expected failure):

```json
{
  "session_id": null,
  "node": "negative_test",
  "mode": "private",
  "model_id": "fortanix/glm-5.3-flash",
  "route": null,
  "policy_required": "confidential",
  "evidence": {"http_status": 400, "error_code": "confidential_privacy_required", "error_type": "bad_request",
               "error_message": "No route meets min_privacy=confidential"},
  "request_id": null,
  "latency_ms": 0,
  "outcome": "refused",
  "created_at": "2026-11-19T08:19:15.900975Z"
}
```

Any HTTP 400 from the gateway on this call is `outcome: "refused"`, whatever its code. Live result on 2026-11-19 with `TR_NEGATIVE_TEST_PROVIDER=fortanix`: HTTP 400 `{"error_code": "invalid_request", "error_message": "No route candidates match the requested provider filters"}` in about 150 ms, so `refused`. A provider 5xx would be `outcome: "error"` with `evidence.http_status`. `outcome: "error"` with `evidence.error: "expected_refusal_but_served"` means the gateway served it when it should not have; show that loudly. Errors: 401, 403, 404 `session_not_found`.

### POST /api/demo/scenarios/{scenario_id}/run — D05 (doctor)

`scenario_id` is `S1`–`S10`. Replays the scenario's turns through the graph (real model calls) and stops at urgent or ready. → 200:

```json
{"session_id": "1b108d0c68484d419629ea53fdcf9e9d", "scenario_id": "S8", "status": "urgent", "turns_run": 3, "brief_id": null}
```

Errors: 401, 403, 404 `scenario_not_found`, 502 as for messages (the partial session stays in the queue).

### GET /api/guideline-updates — D02 "guideline updated" banner (doctor)

Recent changes to monitored guideline pages, newest first (`detected_at` descending), at most 20. → 200:

```json
{
  "updates": [
    {
      "url": "https://www.uspreventiveservicestaskforce.org/uspstf/recommendation/cervical-cancer-screening",
      "title": "Guideline page changed",
      "detected_at": "2026-11-19T08:00:00Z",
      "change_summary": "Synthetic: the recommendation text changed."
    }
  ]
}
```

`change_summary` is Context.dev's change summary, truncated to 500 chars. Errors: 401, 403.

### POST /api/webhooks/context-monitor (Context.dev only, no demo token)

Receiver for Context.dev Monitor webhooks (`change.detected`, `run.completed`). Auth is the `X-Context-Signature: t=<unix>,v1=<hex>` header: HMAC-SHA256 of `"<t>." + raw body` keyed with the monitor's `webhook.secret` (config `CONTEXT_DEV_WEBHOOK_SECRET`, comma-separated when there are several monitors), within 300 s. Only changes whose URL host is on the guideline allowlist (`GUIDELINE_DOMAINS`) are stored; retries of the same change id are not stored twice. → 200:

```json
{"stored": 1}
```

| HTTP | `error` | When |
| --- | --- | --- |
| 400 | `invalid_payload` | Signature valid but body is not JSON |
| 401 | `invalid_signature` | Missing, malformed, stale or wrong signature. Nothing stored. |
| 503 | `webhook_not_configured` | No secret configured (fails closed; nothing parsed or stored) |

Monitors are created with `server/scripts/create_guideline_monitor.py` (one `page` monitor per guideline URL in `scenarios/evidence-cache`).

## Contract check

`server/scripts/contract_capture.py` drives a running server over real HTTP and saves every response as a fixture under `packages/core_data/test/fixtures/contract/`. `packages/core_data/test/contract_fixtures_test.dart` replays each fixture through the real `BloomApiClient` (it also checks the method and the exact `/api/...` URL the client builds) and decodes it with the real `fromJson` code. Tokens, receipts and header values are redacted; the script refuses to write a fixture that contains a configured key.

```bash
cd server
# 1. Offline, no keys. BLOOM_FAKE_MODEL=1 is a dev-only scripted model (app/fake_gateway.py):
#    off by default, refused at startup in private mode, reported by /api/healthz.
BLOOM_FAKE_MODEL=1 DATABASE_URL=sqlite:////tmp/contract.db uv run uvicorn app.main:app --port 8765 &
uv run python scripts/contract_capture.py --out ../packages/core_data/test/fixtures/contract/fake
# 2. Private mode with no confidential model: the 502 refusal (no outbound model call).
BLOOM_MODE=private DATABASE_URL=sqlite:////tmp/contract-private.db uv run uvicorn app.main:app --port 8766 &
uv run python scripts/contract_capture.py --base http://127.0.0.1:8766 --private-only \
  --out ../packages/core_data/test/fixtures/contract/private
# 3. Live (real model calls, about 12-20): S1, S7 and the negative test.
uv run --env-file ../.env uvicorn app.main:app --port 8765 &
uv run --env-file ../.env python scripts/contract_capture.py --live \
  --out ../packages/core_data/test/fixtures/contract/live
# Then run the core_data tests (very_good test in packages/core_data).
```

### Bad-model check (`server/scripts/live_check.py`)

Drives S1, S3 (must end `ready` with a brief) and S7 (must end `urgent`, R2) over HTTP and prints, per turn, the HTTP status, `parse_path` and status, then the brief's `source`, `generated_by` and citation count, and a trust-event summary. After a scenario's scripted turns it answers "No, nothing else." until done (at most 12 turns). Exit code 0 only if all pass.

```bash
cd server
# Offline rehearsal: the fake model answers garbage (prose / truncated JSON / wrong shape) at a
# given rate (BLOOM_FAKE_GARBAGE_RATE, 0..1) and can reject json_object mode with a 400.
BLOOM_FAKE_MODEL=1 BLOOM_FAKE_GARBAGE_RATE=1.0 BLOOM_FAKE_REJECT_JSON_MODE=1 \
  DATABASE_URL=sqlite:////tmp/live-check.db uv run uvicorn app.main:app --port 8765 &
uv run python scripts/live_check.py --base http://127.0.0.1:8765
# Live (real model calls, roughly 10-30): against a server the lead started.
uv run python scripts/live_check.py --base "$BASE_URL"
```
