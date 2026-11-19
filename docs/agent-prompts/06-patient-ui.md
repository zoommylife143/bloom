# Agent 06: patient screens P01–P04 (build step 7)

## Goal
Build the patient intake in `apps/patient`: A01 role entry, P01 Welcome + consent, P02 Intake chat, P03 Urgent care, P04 Done, wired to the API through `core_data` repositories. Match the Figma frames (node IDs in `docs/02-app-flow.md`).

## Read first
- `CLAUDE.md`, `docs/agent-prompts/README.md`, `docs/02-app-flow.md`, `docs/api-contract.md`
- `packages/bloom_ui`, `packages/core_domain`, `packages/core_data` (use them; don't duplicate)
- Plan §3 tone of voice: warm, short, 6th-grade, no jargon, no certainty claims. Error copy: "Something went wrong on our side. Your answers are saved. Please try again."

## Build (feature folders `presentation/{bloc,pages,widgets}`, `domain`, `data`)
- `auth`: A01 as a simple role entry (patient), calling `POST /api/login`. No codes or phone states.
- `welcome` (P01): demo banner "Do not enter real health information", purpose, privacy summary in literal terms (zero-data-retention AI route, de-identified guideline search, physician review; never "HIPAA" or "secure"), Start button → creates the session.
- `intake` (P02): `IntakeBloc` (Bloc, freezed sealed states: idle, sending, waiting, error, routeRefused, urgent, done). Message list with ChatBubble, quick replies, optional-question marker, progress bar from `progress`. States from Figma: waiting (10:23), route refused (6:87), model error (23:71).
- `urgent` (P03): full screen, from the server's `UrgentMessage`: actions in the given order (988 first for R5), "I understand" → P04. Locked: back navigation doesn't return to the chat. Screen-reader first (semantics order: title, body, actions).
- `done` (P04): thank-you, "Your doctor will review this", no clinical content.
- go_router with routes named P01–P04 and redirects (no session → P01; urgent → P03).

## Tests
- bloc_test for IntakeBloc: send → waiting → reply; 502 → routeRefused; 409 → urgent/locked; urgent payload → navigates to P03.
- Widget tests: P02 states (waiting, error, refused), P03 action order for R5 vs R1, P04 has no clinical text.

## Done when
In `apps/patient`: `flutter analyze` clean, `flutter test` passes, `flutter build web --base-href /intake/` succeeds. S1 and S6 run end to end against a local `uvicorn` in dev mode (describe how you checked). Report per the README format.
