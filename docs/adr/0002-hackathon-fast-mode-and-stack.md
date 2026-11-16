# ADR 0002: Hackathon-fast mode and stack deviation

- **Status:** Accepted (chosen by srinivas in chat, 2026-11-16)
- **Date:** 2026-11-16

## Context
The full app playbook needs four human gates, high-fidelity Figma frames for every state, and Firebase dev/staging/prod projects. That doesn't fit a five-day hackathon ending Fri 2026-11-20, 5:00 PM PT. The hackathon sponsors also supply the compute (Boat.dev VMs), the inference (NY Token Exchange / TrustedRouter) and the web data API (Context.dev).

## Decision
1. **Hackathon-fast mode.**
   - Gates 1–3 are compressed into one review of the existing plan documents: the "Bloom: Design and Development Plan" and the "Boat Hackathon: Gynecology Agent Build Plan".
   - Each gate is still approved only by srinivas, in chat, and recorded in `docs/approvals/`.
   - Gate 4 is a release check before submission.
2. **Stack for this week (replaces the Firebase default):**
   - Frontend: Flutter Web, Material 3, flutter_bloc, go_router, from the existing Bloom Figma design.
   - Backend: Python FastAPI + LangGraph, run in Docker Compose on one Boat.dev VM (EU regions).
   - Data: SQLite with synthetic data only.
   - Inference: NYTE confidential route in private demo mode, which fails closed. GLM-5.3 Flash via TrustedRouter is for dev mode only.
   - Knowledge: Context.dev, domain-restricted search, de-identified queries only.
   - Out this week: Firebase, Cloud Functions, payments, FHIR/ABHA/ABDM.
3. **Playbook rules that still hold:**
   - Synthetic data only.
   - Every AI output is a draft with Confirm / Edit / Reject and stored provenance.
   - Clinical thresholds (red-flag rules) are decided server-side.
   - No PHI in logs or URLs.
   - STATUS.md is updated every session.
   - No app code before the compressed Gate 3 is approved.
   - The rule that the clinic reaches AI only through Cloud Functions becomes: the clinic reaches AI only through the FastAPI backend.

## Consequences
- After Demo Day, rerun the full playbook (Phases 1–3) to move to Firebase. Production use would need BAAs, US-region hosting and a clinician-reviewed eval set.
- The playbook kit templates (`docs/templates/`) aren't present. Docs 08–12 and the AI workflow cards are covered by sections of the Design and Development Plan until the kit is supplied.
