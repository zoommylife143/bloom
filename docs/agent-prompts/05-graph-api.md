# Agent 05: LangGraph agent, store and API (build steps 6 and 9)

## Goal
Wire the agent from plan §4–§6: a LangGraph state machine that runs safety → intake → safety → (urgent | more intake | de-identify → retrieve → brief), a SQLite store, and the FastAPI endpoints both Flutter apps call.

## Read first
- `CLAUDE.md`, `docs/agent-prompts/README.md`
- `server/app/models.py`, `config.py`, `db.py`, and the finished modules: `router.py` (ModelRouter, ConfidentialRouteUnavailable), `attestation.py`, `safety.py`, `deidentify.py`, `retrieve.py`. Use their public interfaces as they are; report mismatches rather than rewriting them.
- `scenarios/S1–S10.json`

## Build
1. `store.py`: a thin repository over `db.py` (sessions, messages, intake_records, red_flags, evidence, briefs, trust_events, audit_log). The server owns every status transition. `audit_log` gets actor + action + session_id only. A `record_trust_event(TrustEvent)` used as the router's `on_event`.
2. `prompts.py`:
   - Intake system prompt: one question per turn, warm 6th-grade wording, sexual-health questions marked optional and "declined" accepted, never diagnose or reassure, at most 12 turns, output JSON only: `{"reply": str, "extracted": {partial IntakeRecord}, "done": bool}`. List the IntakeRecord fields and enums.
   - Brief system prompt: input = the filled IntakeRecord JSON + numbered evidence passages with URLs. Output JSON matching `Brief`. SOAP sections are considerations for the physician, never a diagnosis. Every `screenings_possibly_due` line cites exactly one URL **from the given passages** or has `source_url: null` with text "No guideline retrieved". No claims beyond the passages.
3. `graph.py` (LangGraph `StateGraph` over a `BloomState` TypedDict: session_id, messages, intake, red_flag, evidence_queries, evidence, brief, status, error):
   - `safety_pre` (safety.check_text with intake context) → `urgent` on hit
   - `intake` (router.complete, node="intake"; parse JSON with one retry on parse failure; merge `extracted` into IntakeRecord; pass `reply` through `safety.filter_patient_reply`)
   - `safety_post` (safety.check_fields) → `urgent` on hit
   - not done → END of turn (reply to patient); done or 12 turns → `deidentify` → `retrieve` → `brief` (router.complete, node="brief"; validate against `Brief`; drop any citation URL not in the evidence; status=ready)
   - `urgent`: lock the session, store the red flag, return the fixed `URGENT_MESSAGES[rule]`. No model call happens on the urgent path.
   - `ConfidentialRouteUnavailable` anywhere: status unchanged, the API returns 502 `{"error": "confidential_route_unavailable"}`, and no other model is called.
   - The brief step runs synchronously at the end of the final turn for the demo (target < 20 s); expose `status="generating"` while it runs if you make it a background task.
4. `main.py` endpoints (plan §6), all under `/api`:
   - `POST /sessions {scenario_id?}` → `{session_id, mode}`; first Bloom question returned as `reply` too.
   - `POST /sessions/{id}/messages {text}` → `{reply, status, progress (0-1), urgent?: UrgentMessage}`; 409 if urgent/done; 502 on refusal.
   - `GET /sessions` → list with status chips (D01), newest first, red flags first.
   - `GET /sessions/{id}/brief` → `{brief, provenance, evidence[]}`; 404 until generated.
   - `POST /briefs/{id}/decision {decision: approve|edit|reject, edited?: Brief, reviewer}` → updated brief; 409 if already decided; stores reviewer + time; edit keeps the original JSON and stores `edited_json`.
   - `GET /sessions/{id}/trust` → TrustEvents + gateway attestation summary (D03).
   - `GET /sessions/{id}/flag` → red flag rule, matched fields and time (D06).
   - `GET /audit` → audit rows.
   - `POST /demo/negative-test` → runs `router.negative_test`, stores the refused TrustEvent, returns it (the expected failure, HTTP 200 with outcome=refused).
   - `POST /demo/scenarios/{scenario_id}/run` → replays a scenario's turns through the graph and returns the session id (D05).
   - `GET /healthz` → `{ok, mode, trustedrouter_configured: bool}` (no key values).
   - Demo login: `POST /login {role: patient|doctor}` returns a signed role token (HMAC with `demo_login_secret`); doctor endpoints require the doctor role. Not production auth; say so in a comment.
   - CORS for local dev (`localhost:*`).
   - Pydantic response models for every endpoint so `/docs` documents the contract the Flutter agents use.
5. Write `docs/api-contract.md` from the OpenAPI schema: each endpoint, request, response, errors, with one example each.

## Tests (offline; fake ModelRouter that returns scripted JSON)
- Scenario harness: S1–S5 reach a brief in ≤ 12 turns; S6–S10 hit the expected rule and lock (409 on the next message); no model call on the urgent path.
- Refusal: private mode + refusal → 502, exactly one router call, TrustEvent outcome=refused stored.
- Brief: citation URLs not in the evidence are dropped; no evidence → "No guideline retrieved".
- Decision: approve/edit/reject transitions; a second decision → 409; reviewer and time stored.
- Audit grep (plan §11): after S1, a planted clinical phrase appears in messages/intake_records but **not** in audit_log or trust_events.
- Doctor endpoints reject a patient token.

## Done when
`cd server && uv run pytest -q` passes in full and `uv run uvicorn app.main:app` starts. Report per the README format, with the endpoint list.
