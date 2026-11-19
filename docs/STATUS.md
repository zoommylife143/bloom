# Bloom: STATUS

_Last updated: 2026-11-19 (session 2)_

| Item | Value |
| --- | --- |
| Track | Web (ADR 0001) |
| Product | Both: patient intake + clinic dashboard (ADR 0001) |
| Mode | Hackathon-fast (ADR 0002) |
| Phase | 4 Build: in progress |
| Current step | Server agents 01 (router), 02 (safety), 03 (retrieval + scenarios) done, 262 tests pass, uncommitted on build/scaffold. Next: agent 05 (graph + API); Flutter agents 04/06/07 blocked on SDK. Schedule: Bloom: 30-Hour Build Plan |
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
- Approve the scope cuts in the 30-Hour Build Plan: one Flutter app instead of two (partly reverses ADR 0003), A01 as a role picker, D04/S01 cut.
- Review the post-gate Figma additions (A01, D06, S01, extra states).
- Confirm ADR 0003 (two apps: apps/patient + apps/clinic) or revert to one app.
- Create the Boat VM (docs/sponsor-runbook.md §1) and get the NYTE and Context.dev keys.

## Blockers
- The Very Good CLI hook blocks shell commands that mention Flutter in this workspace. It needs `dart pub global activate very_good_cli` once the Dart SDK is installed.
- Flutter/Dart SDK not installed in the cloud workspace.
- flutter-skills (Riverpod) is disabled for this project in .claude/settings.json. To disable it account-wide, turn it off in claude.ai plugin settings.
- setup-claude-connectors.sh and the app-playbook kit (`docs/templates/`, `approvals/TEMPLATE.md`) are not in this workspace. The Design and Development Plan stands in for them (srinivas, 2026-11-16).

## Session 2 notes (2026-11-19)
- OpenAI SDK 3.x uses httpx2, so respx can't mock it; router tests inject an httpx2 MockTransport client. Agent 05 should fake ModelRouter.
- safety.py precedence R5, R6, R2, R1, R3, R4. Agent 05 must pass the current IntakeRecord as context to every check_text call (S9 spans turns). R1 fires when pregnancy_possible is unknown (plan taken literally). Keyword lists need clinician review.
- retrieve.py uses plain httpx against POST https://api.context.dev/v1/web/search (includeDomains plus a host filter), not the SDK. Cache: scenarios/evidence-cache/ (2 hand-made fixtures: USPSTF, CDC). Deploy must ship scenarios/ into the server container.
- Still unconfirmed: the TrustedRouter 400 body for a confidential refusal, and the tr_negative_test_provider slug. Run server/scripts/hello_trustedrouter.py once a key exists.

## Open questions
- NYTE: confidential model ID, per-request evidence fields, refusal error code, tool/JSON support.
- GLM-5.3 Flash: model ID is `fortanix/glm-5.3-flash` via https://api.trustedrouter.com/v1 (checked 2026-11-19). Its route is ZDR (operator-declared), not confidential: the model page says "provider E2EE not verified". Bloom uses it for every AI call (LetsEncrypt.AI prize) and labels it ZDR in D03. Still open: which TrustedRouter route is tagged `confidential` for private mode, and the link to the OpenCode fork (the link shared points to the model page).
- Boat public HTTPS for IPv4; Context.dev domain filter and retention.
- Crew ownership of workstreams A/B/C; final public name.
