# ADR 0003: Continuum-style repo and Figma structure

- **Status:** Accepted (requested by srinivas in chat, 2026-11-16)
- **Supersedes:** the single `apps/bloom_web` app in ADR 0002. The rest of ADR 0002 stands.

## Decision
Bloom mirrors the Continuum (clinic web) and NurturePath (patient app) layout: two Flutter apps over shared packages, and one Figma page per area.

```
bloom/
  melos.yaml
  apps/
    clinic/                 # doctor dashboard (web, tablet layouts): D01-D06, S01
      lib/features/<feature>/
        presentation/{bloc,pages,widgets}
        domain/             # entities, repository interfaces (pure Dart)
        data/               # repository implementations, DTOs, API client calls
      # features: auth, queue, brief, trust, red_flag, audit, demo, settings
    patient/                # pre-visit intake (web, phone + tablet): P01-P04
      # features: auth, welcome, intake, urgent, done
  packages/
    bloom_ui/               # tokens + ThemeData + widgets, 1:1 with Figma components
    core_domain/            # shared entities, AppFailure
    core_data/              # FastAPI client, repositories, AI draft repository
    l10n/                   # ARB files (en; es is a stretch goal)
  server/                   # FastAPI + LangGraph (stands in for Functions + ai_service)
    app/{main,graph,safety,deidentify,router,retrieve,db}.py
    tests/
  scenarios/                # 10 synthetic patients
  docs/
  docker-compose.yml        # nginx serves /intake (patient) and /doctor (clinic); api at /api
```

Rules carried over from continuum-flutter:
- Cubit for simple state, Bloc for intake chat, brief decision and AI requests.
- Freezed sealed states.
- Widgets never call HTTP.
- AI output is always a draft with Confirm / Edit / Reject and provenance.
- Clinical thresholds (red flags) live only on the server.

## Figma pages
Cover · Flows · Foundations · Components · Auth (A) · Patient (P) · Clinic (D) · Settings (S).
Frame name = `<ScreenID> <Name>`. States are `<ScreenID> <Name> / <state>`.

## Consequences
- Two web builds instead of one, at roughly +2 hours. If time runs short, ship `apps/patient` first and keep the clinic app to D01, D02 and D03.
