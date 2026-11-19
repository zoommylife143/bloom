# Bloom: STATUS

_Last updated: 2026-11-19 (session 3)_

| Item | Value |
| --- | --- |
| Track | Web (ADR 0001) |
| Product | Both: patient intake + clinic dashboard (ADR 0001) |
| Mode | Hackathon-fast (ADR 0002) |
| Phase | 4 Build: deployment-ready; G4 release check next |
| Current step | All screens built in both apps; server graph + API done. 834 tests pass (server 364, patient 191, clinic 116, core_data 108, bloom_ui 35, core_domain 16, l10n 4). Docker stack smoke-tested (25/25) and live-checked (S1, S3 reach a cited brief; S7 goes urgent R2). Next: Boat VM, demo fork, submission form. |
| Live preview | https://box-node-cc202e66068710d1-8080.on.ascii.dev/intake/ and /doctor/ (dev workspace sandbox via `host 8080 --public`; up only while that sandbox runs) |
| Repo | https://github.com/zoommylife143/bloom (private), branch main |

## Figma
- File: https://www.figma.com/design/0lWIv5IY18QemXtzP3YaTE (team: Anitha's team)
- Pages (ADR 0003): Cover · Flows · Foundations · Components · Auth · Patient · Clinic · Settings
- Added 2026-11-16 after Gate 1, pending srinivas's review: A01 Sign in, D06 Red-flag summary, S01 Settings, the loading/generating/edited/rejected/model-error states, tablet layouts, and prototype links. Screen index: docs/02-app-flow.md
- Tokens: Primitives (16), Bloom semantic (19), Dimensions (10); 8 text styles (Fraunces + DM Sans)
- Components: Button, StatusChip (+ Rejected), ChatBubble, QuickReply, Banner, CitationLink, TrustRow, DecisionBar
- Screens and states: see docs/02-app-flow.md (A01, P01–P04, D01–D06, S01)
- Not designed: lo-fi wireframes and research/persona boards (skipped in hackathon-fast mode); tablet layouts for screens other than P02 and D02; the Cover index is stale
- Decision: built a local Bloom library instead of reusing the Material 3 kit (its token model is M3 purple; Flutter will map Bloom tokens into an M3 ColorScheme)

## Gates
| Gate | Status | Evidence |
| --- | --- | --- |
| G1 Design (compressed) | Approved 2026-11-16 by srinivas | docs/approvals/G1-G3-compressed.md |
| G2 Technical design (compressed) | Approved 2026-11-16 by srinivas | docs/approvals/G1-G3-compressed.md |
| G3 Implementation plan (compressed) | Approved 2026-11-16 by srinivas | docs/approvals/G1-G3-compressed.md |
| G4 Release check | Not started | Submission checklist, plan section 12 |

## Source documents
- Bloom: Design and Development Plan: https://claude.ai/artifact/PbomzYRaCBPEhany86q2zN
- Bloom: 30-Hour Build Plan (2026-11-19, compresses plan §10 into Thu–Fri; submit by Fri 3 PM PT): https://claude.ai/artifact/YSY9JPCHe32dBKF8a342UJ
- Boat Hackathon: Gynecology Agent Build Plan: https://claude.ai/artifact/BKnNcJ7WdLwF25KQM7BbMk
- Integration resources request: https://claude.ai/artifact/9ZMvemAWUq5jy21UXU8vLV

## Waiting on srinivas
- Scope cuts in the 30-Hour Build Plan: A01 as a role picker, D04/S01 cut (still to confirm; D04 is built, S01 is a placeholder).
- Review the post-gate Figma additions (A01, D06, S01, extra states).
- Boat VM: `boat new --name bloom --no-auto-stop` (or `boat extend <id> --hours 48`), deploy with `scripts/deploy.sh`, `boat host <id> 80 --public`, then `boat snapshot <id> bloom-demo` and `boat fork <id> --no-auto-stop --wait` (deploy/README.md).
- Test one slow intake through the public `boat host` URL (its proxy timeout is unknown; nginx allows 180 s, 900 s on /api/demo/).
- Submission form: participation, logo, demo video, X post, crew, app URL (docs/submission.md).
- Rotate the TrustedRouter and Context.dev keys after the demo.

## Blockers
- None for deploy. Flutter 3.50 is installed; tests run through the very_good_cli MCP tool (a hook blocks `flutter test` in Bash).
- flutter-skills (Riverpod) is disabled for this project in .claude/settings.json.
- `PRIVATE_MODEL_ID` is empty, so private mode refuses every AI call (fails closed by design). Demo in dev mode (ZDR route) unless NYTE provides a confidential model ID.
- `CONTEXT_DEV_WEBHOOK_SECRET` empty: guideline monitor (stretch) is off.

## Session 2 notes (2026-11-19)
- Decision (srinivas, 2026-11-19): keep two apps, apps/patient + apps/clinic (ADR 0003 confirmed; the one-app scope cut is rejected).
- OpenAI SDK 3.x uses httpx2, so respx can't mock it; router tests inject an httpx2 MockTransport client. Agent 05 should fake ModelRouter.
- safety.py precedence R5, R6, R2, R1, R3, R4. Agent 05 must pass the current IntakeRecord as context to every check_text call (S9 spans turns). R1 fires when pregnancy_possible is unknown (plan taken literally). Keyword lists need clinician review.
- retrieve.py uses plain httpx against POST https://api.context.dev/v1/web/search (includeDomains plus a host filter), not the SDK. Cache: scenarios/evidence-cache/ (2 hand-made fixtures: USPSTF, CDC). Deploy must ship scenarios/ into the server container.
- Still unconfirmed: the TrustedRouter 400 body for a confidential refusal, and the tr_negative_test_provider slug. Run server/scripts/hello_trustedrouter.py once a key exists.

- Live check (2026-11-19): route `fortanix/glm-5.3-flash` returns 502 provider_error even without a privacy floor. The default is now `z-ai/glm-5.3-flash` (works with min_privacy=zdr, returns a signed x-inference-receipt and x-request-id), with `reasoning.effort=low` (config `tr_reasoning_effort`). Override with TR_MODEL_ID in .env if fortanix recovers.
- Deviation from plan §13: dev mode now retries once, on the same model after 2 s, on HTTP 429/503/529 (the provider returned 529 "System is overloaded" mid-scenario). Private mode never retries, and refusals are never retried. Tests cover all three.
- `.env` created by srinivas (keys pasted in chat on 2026-11-19: rotate after the demo).

## Session 3 notes (2026-11-19)
- Clinic: fixed layout crashes on every signed-in screen under 1100 px (nav labels in Expanded inside a horizontal scroll) and five overflows; responsive tests at 390/768/1440 for every route.
- Patient: 200% text and keyboard layouts fixed; stale replies after reset dropped; slow-reply notice after 12 s; one client_message_id per turn, reused on Try again.
- Server: idempotent resends (`client_message_id`, `turn_results` table); 409 session_locked carries status + urgent payload so a retried urgent turn shows P03; 110 s turn budget (TURN_BUDGET_S), 60 s per call.
- Live intake JSON: before, 6 of 8 S1 turns were 502 (model answered in prose). Fixed with response_format json_object (TR_JSON_MODE, on), prior turns sent as JSON, temperature 0.2, one repair retry, non-repeating deterministic fallback question, and a deterministic DRAFT brief (provenance source=fallback, labelled "written without AI" in D02). Live after: 100% first-pass JSON on S1/S3/S7.
- D05 negative test live: fortanix filter gives HTTP 400 "No route candidates match", shown as Refused; a provider 5xx is shown as an error, not a refusal.
- Contract check: docs/api-contract.md "Contract check" (fake model BLOOM_FAKE_MODEL=1, never in private mode); live check: `server/scripts/live_check.py --base <url>`.
- Deploy: nginx-unprivileged on 8080 (host port BLOOM_HTTP_PORT, default 80), IPv4+IPv6, bundled CanvasKit (no CDN), content-hashed assets, DATABASE_URL defaults to /data/bloom.db on the volume; `scripts/deploy.sh` builds, waits for healthy and smoke-tests.

## Open questions
- NYTE: confidential model ID, per-request evidence fields, refusal error code, tool/JSON support.
- GLM-5.3 Flash: model ID is `fortanix/glm-5.3-flash` via https://api.trustedrouter.com/v1 (checked 2026-11-19). Its route is ZDR (operator-declared), not confidential: the model page says "provider E2EE not verified". Bloom uses it for every AI call (LetsEncrypt.AI prize) and labels it ZDR in D03. Still open: which TrustedRouter route is tagged `confidential` for private mode, and the link to the OpenCode fork (the link shared points to the model page).
- Boat `host` proxy request timeout; Context.dev retention.
- Crew ownership of workstreams A/B/C; final public name.
