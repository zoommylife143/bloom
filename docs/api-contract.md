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
| 409 | `session_locked` | Message to a session that is `urgent`, `ready`, `approved`, `edited` or `rejected` |
| 409 | `already_decided` | Second decision on a brief |
| 422 | `edited_brief_required` | `decision: "edit"` without `edited` (FastAPI's own 422 body is used for schema errors) |
| 502 | `confidential_route_unavailable` | Privacy floor refused (P02 "route refused" state). Status unchanged, nothing sent to any other model. |
| 502 | `model_error` | Any other model failure (P02 "model error" state). Status unchanged; the patient can resend. |

- `SessionStatus`: `in_progress | urgent | ready | approved | edited | rejected`.
- `RedFlagRule`: `R1` ectopic, `R2` heavy bleeding, `R3` pelvic infection, `R4` pregnancy/postpartum warning, `R5` self-harm, `R6` sexual assault disclosure.

## Endpoints

### GET /api/healthz (no auth)

```json
{"ok": true, "mode": "dev", "trustedrouter_configured": true}
```

`mode` is `dev | private`, decided by the server. No key values are returned.

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

Request `{"text": "I'd like a checkup."}` (1–4000 chars). → 200 `MessageResponse`:

| Field | Type | Notes |
| --- | --- | --- |
| `reply` | string | Bloom's next question, the closing line, or the urgent body |
| `status` | SessionStatus | `in_progress`, `urgent` (go to P03) or `ready` (go to P04) |
| `progress` | number 0–1 | 1.0 once `done` |
| `done` | bool | true when the patient flow ends (urgent or intake finished) |
| `urgent` | UrgentMessage or null | set only when `status == "urgent"` |

Normal turn:

```json
{"reply": "How old are you?", "status": "in_progress", "progress": 0.7, "done": false, "urgent": null}
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

Errors: 401, 404 `session_not_found`, 409 `session_locked`, 502 `confidential_route_unavailable` / `model_error`. After a 502 the turn was not saved; the client may resend the same text. If the intake had finished but the brief failed, the next message (any text) resumes at the brief step.

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
- `evidence[].title` is not stored and comes back null.
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

- `events[].node`: `intake | brief | retrieve | negative_test`. `outcome`: `ok | refused | error`. `policy_required`: `zdr` (dev), `confidential` (private), `deidentified_query` (retrieve, route `context.dev`).
- `evidence` may contain `receipt` (decoded TrustedRouter receipt claims; `signature_verified: false`), `headers`, `http_status`, `error_code`, `error`.
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

`actor`: `patient | doctor | system`. `action`: `login`, `session_created`, `message_received`, `reply_filtered`, `red_flag_locked`, `intake_completed`, `brief_generated`, `brief_viewed`, `brief_approved`, `brief_edited`, `brief_rejected`, `route_refused`, `model_error`, `negative_test`, `scenario_run`.

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

`outcome: "error"` with `evidence.error: "expected_refusal_but_served"` means the gateway served it when it should not have; show that loudly. Errors: 401, 403, 404 `session_not_found`.

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
