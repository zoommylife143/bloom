# Bloom: Private AI Gynecology Copilot

Bloom is a privacy-first **pre-visit intake and physician-brief agent** for gynecology clinics. A patient answers a short intake chat before the appointment. Bloom turns it into a one-page physician brief with guideline citations, and the gynecologist confirms, edits or rejects every AI draft before it counts.

Built for **Boat Hackathon SF 2026** (Zoom My Life).

> **Synthetic data only. Not a medical device. Not HIPAA compliant.** Do not enter real patient information.

| | |
| --- | --- |
| Live demo (patient) | https://box-node-65cdd7262c0153ea-80.on.boat.dev/intake/ |
| Live demo (clinic) | https://box-node-65cdd7262c0153ea-80.on.boat.dev/doctor/ |
| Design (Figma) | https://www.figma.com/design/0lWIv5IY18QemXtzP3YaTE |
| Demo video | `docs/submission/bloom-demo.mp4` (1:54) |

---

## Contents
1. [What Bloom does](#1-what-bloom-does)
2. [Using the app](#2-using-the-app)
3. [Architecture](#3-architecture)
4. [Partner services](#4-partner-services)
5. [Repository layout](#5-repository-layout)
6. [Run it locally](#6-run-it-locally)
7. [Configuration](#7-configuration)
8. [Deploy to a Boat.dev VM](#8-deploy-to-a-boatdev-vm)
9. [Testing](#9-testing)
10. [API overview](#10-api-overview)
11. [Safety and privacy rules](#11-safety-and-privacy-rules)
12. [Troubleshooting](#12-troubleshooting)
13. [Further documentation](#13-further-documentation)

---

## 1. What Bloom does

Gynecology visits are short. Bloom lets the patient tell their story first, privately, so the doctor walks in prepared.

Three things make it different:

1. **Safety first, without the model.** Six red-flag rules are deterministic Python on the server, each with tests. When one fires, the chat stops and the patient sees urgent-care actions immediately. No model decides this.

   | Rule | Red flag |
   | --- | --- |
   | R1 | Possible ectopic pregnancy |
   | R2 | Heavy bleeding |
   | R3 | Pelvic infection signs |
   | R4 | Pregnancy or postpartum warning signs |
   | R5 | Self-harm |
   | R6 | Sexual assault disclosure |

2. **Private inference that fails closed.** Every model call goes through NY Token Exchange's **TrustedRouter** with a privacy floor set by the server, never by the browser. In private mode, if no confidential route is available, Bloom refuses and does **not** fall back to another model. The Privacy & Trust panel shows the route, policy, gateway receipt and latency of every call.

3. **Cited, de-identified guidelines.** **Context.dev** searches an allowlist of guideline sites (ACOG, USPSTF, CDC) with queries built only from structured fields, never from what the patient typed. The brief may cite only passages that were actually retrieved.

Every AI output is a **draft** with Confirm / Edit / Reject, and its provenance (model, route, prompt version, evidence) is stored.

---

## 2. Using the app

### Patient app (`/intake/`)

| Screen | What happens |
| --- | --- |
| **A01 Sign in** | Demo role picker: choose *Patient*. |
| **P01 Welcome + consent** | Read the privacy notice and start the intake. |
| **P02 Intake chat** | Bloom asks one question at a time (reason for visit, cycle, pregnancy possibility, symptoms, history, screening). Any question can be skipped. A progress bar shows how far along you are. |
| **P03 Urgent care** | Shown immediately if a red-flag rule fires. The chat locks and urgent-care steps are shown. |
| **P04 Done** | The intake is complete and the brief is sent to the clinic queue. |

Try these sample answers (all synthetic):
- *Routine:* "I'd like a checkup and my periods have been irregular." → finishes on P04 with a brief.
- *Red flag:* "I'm soaking a pad every hour and I feel lightheaded." → rule R2 fires and P03 appears.

### Clinic app (`/doctor/`)

| Screen | What happens |
| --- | --- |
| **A01 Sign in** | Choose *Doctor*. |
| **D01 Patient queue** | All sessions, with urgent red flags at the top. |
| **D02 Physician brief** | One-page summary with guideline citations. **Confirm**, **Edit** or **Reject** it. Edits are saved with provenance. |
| **D03 Privacy & Trust panel** | Side sheet in D02: route, privacy policy, gateway receipt, request ID and latency for every AI call. |
| **D04 Audit log** | Every decision and AI call, in order. |
| **D05 Demo scenarios** | Run the 10 built-in synthetic scenarios (S1–S10) and the **negative test**, which asks for a confidential route the provider can't meet and shows **Refused** with no fallback. |
| **D06 Red-flag summary** | What fired, on which message, and the actions shown to the patient. |
| **S01 Settings** | Privacy and data settings (placeholder in this build). |

### Built-in scenarios

| ID | Expected outcome |
| --- | --- |
| S1 | Brief: cervical screening, irregular cycles |
| S2 | Brief: postmenopausal spotting |
| S3 | Brief: dysmenorrhea, contraception |
| S4 | Brief: heavy menstrual bleeding, fatigue, mammogram |
| S5 | Brief: patient declined questions, cervical screening |
| S6 | Urgent R1 (ectopic) |
| S7 | Urgent R2 (heavy bleeding) |
| S8 | Urgent R3 (pelvic infection) |
| S9 | Urgent R4 (pregnancy warning; spans several turns) |
| S10 | Urgent R5 (self-harm) |

---

## 3. Architecture

```
                     Boat.dev VM  (Docker Compose)
 ┌───────────────────────────────────────────────────────────────────┐
 │  web  (nginx, port 80 → 8080)                                     │
 │    /intake/  → Flutter Web patient app                            │
 │    /doctor/  → Flutter Web clinic app                             │
 │    /api/     → proxy to api:8000                                  │
 │                                                                   │
 │  api  (FastAPI + LangGraph, internal only)                        │
 │    safety_pre → intake (LLM) → safety_post → save_turn            │
 │         │                         │             │ done            │
 │         └──────► urgent ◄─────────┘             ▼                 │
 │                                   deidentify → retrieve → brief   │
 │                                                                   │
 │  SQLite  on the bloom-data volume (/data/bloom.db)                │
 └───────────────────────┬─────────────────────────┬─────────────────┘
                         │                         │
              TrustedRouter (NYTE)            Context.dev
           GLM-5.3 Flash, privacy floor    guideline search on
           zdr (dev) / confidential         acog.org, uspstf, cdc.gov
           (private, fails closed)         de-identified queries only
```

**One patient turn:**
1. `safety_pre`: deterministic red-flag rules run on the patient's text (with the whole intake record as context). A hit goes straight to `urgent`, with no model call.
2. `intake`: the model (via TrustedRouter, JSON mode) extracts structured fields and writes the next question. If the JSON is bad, Bloom tries one repair call, then falls back to a fixed question.
3. `safety_post`: the rules run again on the updated record.
4. `save_turn`: the turn, its result and the trust event are stored (resends with the same `client_message_id` are idempotent).
5. When the intake is complete: `deidentify` builds search queries from structured fields only, `retrieve` gets guideline passages from Context.dev (cached in `scenarios/evidence-cache/`), and `brief` writes the draft brief. `sanitize_brief` drops any citation that was not actually retrieved.

**Stack**
- Frontend: Flutter Web, Material 3, `flutter_bloc`, `go_router`; Dart workspace with Melos.
- Backend: Python 3, FastAPI, LangGraph, Pydantic, SQLite; managed with `uv`.
- AI: GLM-5.3 Flash through TrustedRouter (OpenAI-compatible API).
- Deploy: Docker Compose (nginx-unprivileged + API) on a Boat.dev VM.

---

## 4. Partner services

| Partner | Role in Bloom | Where in the code |
| --- | --- | --- |
| **Boat.dev** | The VM that hosts the whole stack; public HTTPS host on port 80; `boat fork` makes a frozen demo copy that doesn't auto-stop. | `docker-compose.yml`, `scripts/deploy.sh`, `deploy/` |
| **NY Token Exchange / TrustedRouter** | Gateway for every AI call, with a server-set privacy floor (`min_privacy=zdr` in dev, confidential in private mode), signed receipts and request IDs. | `server/app/router.py`, `server/app/attestation.py` |
| **LetsEncrypt.AI (GLM-5.3 Flash)** | The model behind every intake turn and brief. | `TR_MODEL_ID` in `server/app/config.py` |
| **Context.dev** | Guideline search restricted to an allowlist of domains; optional Monitor webhook for guideline updates. | `server/app/retrieve.py`, `server/app/deidentify.py`, `server/app/monitor.py` |
| **Figma** | Single source of truth for screens and design tokens; screen ID = frame name = route name. | `docs/design-tokens.json`, `docs/02-app-flow.md`, `packages/bloom_ui` |
| **Teamily** | Team coordination and daily status posts. | n/a |

Step-by-step setup for each partner: `docs/sponsor-runbook.md`.

---

## 5. Repository layout

```
bloom/
├── apps/
│   ├── patient/          Flutter Web patient app (A01, P01–P04), served at /intake/
│   └── clinic/           Flutter Web clinic app (A01, D01–D06, S01), served at /doctor/
├── packages/
│   ├── bloom_ui/         Design system: tokens from Figma, theme, shared widgets
│   ├── core_domain/      Domain models shared by both apps
│   ├── core_data/        API client (BloomApiClient), repositories, fake API
│   └── l10n/             ARB strings and generated localizations
├── server/
│   ├── app/
│   │   ├── main.py         FastAPI routes (/api/...)
│   │   ├── graph.py        LangGraph turn pipeline
│   │   ├── safety.py       Red-flag rules R1–R6 (deterministic)
│   │   ├── router.py       TrustedRouter client, privacy floor, retries, refusal mapping
│   │   ├── attestation.py  Trust events: route, policy, receipt, latency
│   │   ├── deidentify.py   Structured-field query builder
│   │   ├── retrieve.py     Context.dev search + evidence cache
│   │   ├── monitor.py      Context.dev Monitor webhook (HMAC)
│   │   ├── store.py, db.py SQLite persistence
│   │   └── fake_gateway.py Offline fake model (BLOOM_FAKE_MODEL=1, dev only)
│   ├── scripts/            live_check.py, hello_trustedrouter.py, contract_capture.py, …
│   └── tests/              pytest suite
├── scenarios/            S1–S10 synthetic scenarios + evidence cache
├── deploy/               nginx config and web Dockerfile
├── scripts/              deploy.sh, smoke.sh
├── docs/                 Plan, ADRs, API contract, status, Figma map, submission kit
└── docker-compose.yml
```

---

## 6. Run it locally

### Prerequisites
- **Docker** with the Compose plugin (easiest path), or:
- **Python 3.12+** and **[uv](https://docs.astral.sh/uv/)** for the server
- **Flutter 3.50+** (Dart 3.14+) for the apps
- API keys for TrustedRouter and Context.dev (optional: without them the pages load and AI calls return a clear error)

### Option A: everything in Docker (recommended)

```bash
git clone https://github.com/zoommylife143/bloom
cd bloom
cp .env.example .env          # then fill in your keys (see section 7)
docker compose up -d --build  # or: scripts/deploy.sh
```

Open http://localhost/intake/ and http://localhost/doctor/. Check health with `curl localhost/api/healthz`.

To use another port: `BLOOM_HTTP_PORT=8080 docker compose up -d --build`.

### Option B: run the pieces separately (for development)

**Server**

```bash
cd server
uv sync
uv run uvicorn app.main:app --reload --port 8000
# API docs at http://localhost:8000/docs
```

Without any API keys you can run the server with the offline fake model (never use it for a demo):

```bash
BLOOM_FAKE_MODEL=1 uv run uvicorn app.main:app --reload --port 8000
```

**Apps**

```bash
flutter pub get                         # from the repo root (Dart workspace)
cd apps/patient
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api
# or, with no server at all:
flutter run -d chrome --dart-define=BLOOM_FAKE_API=true
```

Do the same in `apps/clinic` for the clinic app.

Workspace commands (Melos): `melos run analyze`, `melos run test`, `melos run gen`, `melos run l10n`, `melos run build:web`.

---

## 7. Configuration

All settings live in `.env` (copy `.env.example`). **Never commit `.env`.**

| Variable | Default | Meaning |
| --- | --- | --- |
| `BLOOM_MODE` | `dev` | `dev`: TrustedRouter route with `min_privacy=zdr`. `private`: only a route tagged confidential; fails closed, never falls back. |
| `TRUSTEDROUTER_API_KEY` | (empty) | TrustedRouter key. |
| `TRUSTEDROUTER_BASE_URL` | `https://api.trustedrouter.com/v1` | OpenAI-compatible endpoint. |
| `TR_MODEL_ID` | `z-ai/glm-5.3-flash` | Model used in dev mode. |
| `PRIVATE_MODEL_ID` | (empty) | Confidential model for private mode. Empty means private mode refuses every AI call. |
| `TR_NEGATIVE_TEST_PROVIDER` | `fortanix` | Provider used by the D05 negative test. |
| `CONTEXT_DEV_API_KEY` | (empty) | Context.dev key. |
| `GUIDELINE_DOMAINS` | `acog.org,uspreventiveservicestaskforce.org,cdc.gov` | Allowlist for guideline search. |
| `CONTEXT_DEV_WEBHOOK_SECRET` | (empty) | HMAC secret for the Monitor webhook. Empty turns the monitor off. |
| `DATABASE_URL` | `sqlite:////data/bloom.db` | SQLite file (on the Docker volume). |
| `DEMO_LOGIN_SECRET` | (random per process) | HMAC secret for demo tokens. Set it (`openssl rand -hex 32`) so tokens survive restarts. |
| `BLOOM_HTTP_PORT` | `80` | Host port for the web container (Compose only). |
| `BLOOM_FAKE_MODEL` | off | `1` = offline fake model for tests. Dev only; refused in private mode. |

---

## 8. Deploy to a Boat.dev VM

```bash
# On your laptop
curl -fsSL https://boat.dev/install | sh
boat new          # create a VM
boat ssh          # connect to it

# On the VM
git clone https://github.com/zoommylife143/bloom && cd bloom
cp .env.example .env && nano .env      # add keys
scripts/deploy.sh                      # builds, waits for healthy, runs smoke tests
```

Then:
1. Make it public: `boat host … --public` on port 80, and open `https://<host>/intake/` in a private window.
2. Check it end to end: `cd server && uv run python scripts/live_check.py --base https://<host>` (S1 should reach a cited brief and S7 should go urgent on R2).
3. Freeze a demo copy: `boat fork` (use `--no-auto-stop` so it stays up for judging).

`scripts/deploy.sh --no-build` restarts with the existing images; `--no-smoke` skips the smoke test.

---

## 9. Testing

```bash
# Server (pytest)
cd server && uv run pytest

# Flutter (all packages and apps)
melos run analyze
melos run test

# Smoke test against a running stack
scripts/smoke.sh

# Live check against a deployed stack (uses real model calls)
cd server && uv run python scripts/live_check.py --base https://<host>
```

The test suite covers every red-flag rule, the no-fallback guarantee in private mode, de-identification (a planted-identifier test), citation sanitizing, idempotent resends, all ten scenarios, and responsive layouts at 390/768/1440 px. Release check: 834 tests pass and analysis is clean (`docs/approvals/G4-release-check.md`).

---

## 10. API overview

Base path `/api`, JSON in and out. Full contract: `docs/api-contract.md`; interactive OpenAPI docs at http://localhost:8000/docs when the server runs locally.

| Method | Path | Who | Purpose |
| --- | --- | --- | --- |
| GET | `/api/healthz` | anyone | Mode and configuration check |
| POST | `/api/login` | anyone | Demo token for `patient` or `doctor` (A01) |
| POST | `/api/sessions` | patient/doctor | Start an intake, optionally from a scenario (P01) |
| POST | `/api/sessions/{id}/messages` | patient/doctor | One patient turn: next question, status, progress (P02) |
| GET | `/api/sessions` | doctor | Patient queue (D01) |
| GET | `/api/sessions/{id}/brief` | doctor | Physician brief (D02) |
| POST | `/api/briefs/{id}/decision` | doctor | Confirm / edit / reject a brief (D02) |
| GET | `/api/sessions/{id}/trust` | doctor | Trust events for every AI call (D03) |
| GET | `/api/sessions/{id}/flag` | doctor | Red-flag summary (D06) |
| GET | `/api/audit` | doctor | Audit log (D04) |
| GET | `/api/guideline-updates` | doctor | Guideline-updated banners |
| POST | `/api/demo/scenarios/{id}/run` | doctor | Run a synthetic scenario (D05) |
| POST | `/api/demo/negative-test` | doctor | Privacy-floor refusal test (D05) |
| POST | `/api/webhooks/context-monitor` | Context.dev (HMAC) | Guideline-updated notifications |

Errors always look like `{"error": "<code>", "detail": "..."}`. Important codes: `502 confidential_route_unavailable` (privacy floor refused; nothing sent elsewhere), `502 model_error`, `409 session_locked`.

---

## 11. Safety and privacy rules

These rules are enforced in code and must stay true in any change:

- **Synthetic data only.** No real patient data in code, tests, prompts, logs, URLs or commits.
- **Red-flag rules are deterministic server code**, and every rule has a test.
- **Private mode fails closed.** No fallback model after a refusal.
- **Every AI output is a draft** with Confirm / Edit / Reject, and its provenance is stored.
- **Context.dev gets de-identified queries only**, built from structured fields.
- **Secrets live only in `.env`.**
- **Wording:** never call Bloom "HIPAA compliant", "encrypted" or "secure" without evidence, and never say "data never leaves the app". The GLM-5.3 Flash route is **zero data retention (operator-declared)**, not confidential.

---

## 12. Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| Every AI turn returns "route refused" | `BLOOM_MODE=private` with an empty `PRIVATE_MODEL_ID`. This is by design; use `dev` mode or set a confidential model ID. |
| AI turns return 502 `model_error` | Missing or invalid `TRUSTEDROUTER_API_KEY`, or the provider is overloaded (dev mode retries once on 429/503/529). |
| Brief says "No guideline retrieved" | No Context.dev key, or no passage matched. Cached evidence for scenarios lives in `scenarios/evidence-cache/`. |
| Demo logins stop working after a restart | Set `DEMO_LOGIN_SECRET` in `.env`. |
| Data disappears after redeploy | `DATABASE_URL` must point to `/data/...` on the `bloom-data` volume. |
| `healthz` shows `fake_model: true` | Unset `BLOOM_FAKE_MODEL` before demoing. |

---

## 13. Further documentation

| Document | Contents |
| --- | --- |
| `docs/STATUS.md` | Current state, gates, open questions |
| `docs/02-app-flow.md` | Screen index with Figma node IDs |
| `docs/api-contract.md` | Full HTTP API contract |
| `docs/adr/` | Architecture decisions (build track, stack, structure) |
| `docs/sponsor-runbook.md` | Partner setup steps |
| `docs/agent-prompts/` | Prompts used to build each part with Claude Code |
| `docs/submission/` | Logo, form answers, demo video, recording plan |
| `CLAUDE.md` | Rules for AI-assisted development in this repo |

---

*Bloom is a hackathon prototype. It is not a medical device and must not be used for real clinical decisions.*
