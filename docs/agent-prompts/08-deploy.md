# Agent 08: Docker Compose and Boat deploy (build step 11)

## Goal
One `docker compose up -d --build` on the Boat VM serves the patient app at `/intake/`, the clinic app at `/doctor/` and the API at `/api/`, over one port, with SQLite on a volume.

## Read first
- `CLAUDE.md`, `docs/agent-prompts/README.md`, `docs/sponsor-runbook.md` §1, plan §9

## Build
- `server/Dockerfile`: python 3.12-slim, uv, `uv sync --frozen --no-dev`, non-root user, `uvicorn app.main:app --host 0.0.0.0 --port 8000`.
- `deploy/web.Dockerfile`: multi-stage; stage 1 uses a Flutter image pinned to 3.50.0 to run `flutter build web --release` for both apps with `--base-href /intake/` and `/doctor/` and `--dart-define=API_BASE_URL=/api`; stage 2 nginx serving them.
- `deploy/nginx.conf`: `/intake/` and `/doctor/` with SPA fallback to each app's index.html; `/api/` proxied to the server; gzip; no access logging of query strings; `/` redirects to `/intake/`.
- `docker-compose.yml`: services `api` (env_file `.env`, volume `bloom-data:/data`, healthcheck on `/api/healthz`) and `web` (depends on api healthy, port `80:80`). Never bake `.env` into an image; add `.dockerignore` files that exclude `.env*` (except `.env.example`), `.venv`, `build/`, `.dart_tool/`.
- `deploy/README.md`: the exact Boat steps (`boat new`, `boat ssh`, clone, create `.env` from the variable names in `server/app/config.py`, `docker compose up -d --build`, `curl localhost/api/healthz`), a Cloudflare quick-tunnel command for a public HTTPS URL if Boat has no IPv4 hostname, raising auto-stop, and `boat fork` for the demo snapshot.
- `scripts/smoke.sh`: hits `/api/healthz`, creates a session, sends one message, fetches `/intake/` and `/doctor/`; exits non-zero on failure.

## Done when
Locally: `docker compose build` succeeds and `docker compose up -d` serves `/api/healthz`, `/intake/` and `/doctor/` (run `scripts/smoke.sh`). Report per the README format. Don't create a Boat VM yourself; the crew runs the Boat steps.
