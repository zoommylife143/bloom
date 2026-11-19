# Bloom agent prompts

Each file here is a self-contained brief for one coding agent (a Claude Code subagent, `boat prompt` on the VM, or a teammate). They map to the build steps in "Bloom: 30-Hour Build Plan" (https://claude.ai/artifact/YSY9JPCHe32dBKF8a342UJ).

| Prompt | Build step | Owns | Can start when |
| --- | --- | --- | --- |
| `01-router.md` | 2 | `server/app/router.py`, `server/app/attestation.py`, their tests | Scaffold merged |
| `02-safety.md` | 5 | `server/app/safety.py`, its tests | Scaffold merged |
| `03-retrieval.md` | 4, 8 | `server/app/deidentify.py`, `server/app/retrieve.py`, `scenarios/`, their tests | Scaffold merged |
| `04-flutter-foundation.md` | 1, 3 | `apps/`, `packages/`, `melos.yaml` / root `pubspec.yaml` | Flutter SDK installed |
| `05-graph-api.md` | 6, 9 | `server/app/graph.py`, `server/app/prompts.py`, `server/app/store.py`, `server/app/main.py` | 01, 02, 03 done |
| `06-patient-ui.md` | 7 | `apps/*/lib/features/{auth,welcome,intake,urgent,done}` | 04 done, API contract in 05 |
| `07-clinic-ui.md` | 10 | `apps/*/lib/features/{queue,brief,trust,red_flag,demo}` | 04 done, API contract in 05 |
| `08-deploy.md` | 11 | `docker-compose.yml`, `server/Dockerfile`, `deploy/` | 05 done |

## Rules every agent follows (from CLAUDE.md)

- Synthetic data only. No real names, dates of birth, phone numbers or other PHI anywhere, including tests and fixtures.
- Never read, print or edit `.env` files. Configuration comes from `server/app/config.py` (`Settings`).
- Private mode fails closed: after a refusal, no second model call, ever.
- Red-flag rules are deterministic Python on the server, and every rule has a test.
- Every AI output is a draft with Confirm / Edit / Reject and stored provenance.
- Context.dev gets de-identified queries only, built from structured fields.
- Never write "HIPAA compliant", "secure" without evidence, or "data never leaves the app" in code, copy or comments. The GLM route is zero-data-retention (operator-declared), not confidential.
- Flutter: BLoC only (flutter_bloc), no Riverpod, go_router, Material 3, feature folders `presentation/domain/data`. Widgets never call HTTP.
- Shared contracts live in `server/app/models.py`. Don't change them. If you need a change, stop and report it.
- Touch only the files you own. Don't edit `pyproject.toml`; if you need a dependency, report it.
- Don't commit or push. The orchestrator reviews and commits.
- Tests run offline: mock every network call (respx for httpx, a fake client for the OpenAI SDK).

## Report format (last message of every agent)

1. Files created or changed.
2. Test command and its exact result (pass/fail counts).
3. Public interface (signatures) other modules will call.
4. Anything left open, assumptions made, and any contract change you need.
