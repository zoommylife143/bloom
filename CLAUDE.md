# Bloom: Private AI Gynecology Copilot

Boat Hackathon SF 2026 (Zoom My Life). The final submission deadline is Fri 2026-11-20, 5:00 PM PT.

## Source of truth
- Plan: "Bloom: Design and Development Plan" (https://claude.ai/artifact/PbomzYRaCBPEhany86q2zN). It stands in for docs 01–12 in hackathon-fast mode (ADR 0002).
- Screens: the Bloom Figma file. Screen ID = Figma frame name = go_router route name. A design change goes into Figma first, then the docs, then code.
- Status: `docs/STATUS.md`. Update it at the end of every session.

## Stack (ADR 0002)
- `apps/patient` (P screens) and `apps/clinic` (D and S screens): Flutter Web, Material 3, flutter_bloc, go_router, feature folders `presentation/domain/data` (ADR 0003). Shared code lives in `packages/bloom_ui`, `core_domain`, `core_data` and `l10n`.
- Screen index and Figma node IDs: `docs/02-app-flow.md`. Sponsor steps: `docs/sponsor-runbook.md`.
- `server/`: Python FastAPI + LangGraph, SQLite, pytest, run with `uv`.
- Deploy: Docker Compose on a Boat.dev VM.

## Rules
- **No application code before compressed Gate 3 is approved** by srinivas in chat (`docs/approvals/`).
- **State management is BLoC only.** Do not use Riverpod or the flutter-skills plugin. Follow the VGV bloc/testing/theming skills.
- **Synthetic data only.** No PHI in code, tests, prompts, logs, URLs or commits.
- **Private demo mode fails closed:** no fallback model after a NYTE refusal.
- **Red-flag rules are deterministic Python on the server.** Every rule has a test.
- **Every AI output is a draft** with Confirm / Edit / Reject and stored provenance.
- **Context.dev gets de-identified queries only,** built from structured fields.
- **Never claim "HIPAA compliant"** or "data never leaves the app".
- **Secrets live only in `.env`.** Never commit them, and never read `.env` files.

## Commands
- Backend: `cd server && uv run pytest`, `uv run uvicorn app.main:app --reload`
- Frontend: in `apps/patient` or `apps/clinic`: `flutter analyze && flutter test && flutter build web`
- Deploy: `docker compose up -d --build` on the Boat VM
