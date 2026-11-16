# Bloom: STATUS

_Last updated: 2026-11-16 (session 1)_

| Item | Value |
| --- | --- |
| Track | Web (ADR 0001) |
| Product | Both: patient intake + clinic dashboard (ADR 0001) |
| Mode | Hackathon-fast (ADR 0002) |
| Phase | 4 Build: ready to start |
| Current step | Plan step 2: repo scaffold (Flutter Web + FastAPI/LangGraph + Docker Compose) |
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
- Boat Hackathon: Gynecology Agent Build Plan: https://claude.ai/artifact/BKnNcJ7WdLwF25KQM7BbMk
- Integration resources request: https://claude.ai/artifact/9ZMvemAWUq5jy21UXU8vLV

## Waiting on srinivas
- Review the post-gate Figma additions (A01, D06, S01, extra states).
- Confirm ADR 0003 (two apps: apps/patient + apps/clinic) or revert to one app.
- Create the Boat VM (docs/sponsor-runbook.md §1) and get the NYTE and Context.dev keys.

## Blockers
- The Very Good CLI hook blocks shell commands that mention Flutter in this workspace. It needs `dart pub global activate very_good_cli` once the Dart SDK is installed.
- Flutter/Dart SDK not installed in the cloud workspace.
- flutter-skills (Riverpod) is disabled for this project in .claude/settings.json. To disable it account-wide, turn it off in claude.ai plugin settings.
- setup-claude-connectors.sh and the app-playbook kit (`docs/templates/`, `approvals/TEMPLATE.md`) are not in this workspace. The Design and Development Plan stands in for them (srinivas, 2026-11-16).

## Open questions
- NYTE: confidential model ID, per-request evidence fields, refusal error code, tool/JSON support.
- GLM-5.3 Flash model ID; Boat public HTTPS for IPv4; Context.dev domain filter and retention.
- Crew ownership of workstreams A/B/C; final public name.
