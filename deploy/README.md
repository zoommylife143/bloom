# Deploying Bloom on a Boat.dev VM

One command serves everything on one port:

| Path | What |
| --- | --- |
| `/` | 302 to `/intake/` |
| `/intake/` | Patient app (P screens), Flutter Web |
| `/doctor/` | Clinic app (D and S screens), Flutter Web |
| `/api/` | FastAPI server (proxied by nginx to the `api` container) |

Files: `docker-compose.yml`, `server/Dockerfile`, `deploy/web.Dockerfile`, `deploy/nginx.conf`,
`.dockerignore`, `.env.example`, `scripts/smoke.sh`. SQLite lives on the `bloom-data` volume
(`/data/bloom.db` in the `api` container). `.env` is read at run time only and never copied into an image.

Web and API share one origin, so the browser makes same-origin calls to `/api/` and no CORS
preflight happens. The server's CORS allow-list (localhost only) matters only for local dev,
when `flutter run` serves the app on another port.

## Boat steps (the crew runs these; see also `docs/sponsor-runbook.md` §1)

1. On your laptop, create and enter the VM:
   ```sh
   boat new
   boat list
   boat ssh
   ```
2. On the VM, clone and configure. Fill in the keys in `.env` by hand; the names come from
   `server/app/config.py` (`Settings`). Do not commit `.env`.
   ```sh
   git clone https://github.com/zoommylife143/bloom && cd bloom
   cp .env.example .env
   nano .env        # TRUSTEDROUTER_API_KEY, CONTEXT_DEV_API_KEY, DEMO_LOGIN_SECRET, BLOOM_MODE
   ```
   `DATABASE_URL=sqlite:////data/bloom.db` keeps the database on the volume. Set
   `DEMO_LOGIN_SECRET` (for example `openssl rand -hex 32`) so demo tokens survive an api restart.
3. Build and start (the first web build downloads Flutter 3.50.0 and takes a few minutes):
   ```sh
   docker compose up -d --build
   docker compose ps                 # api should be "healthy", web "Up"
   curl localhost/api/healthz        # {"ok":true,"mode":"dev","trustedrouter_configured":true}
   scripts/smoke.sh                  # full check: healthz, login, session, message, /intake/, /doctor/
   ```
   Port 80 busy? Put `BLOOM_HTTP_PORT=8080` in `.env` and use `BASE_URL=http://localhost:8080 scripts/smoke.sh`.
4. Public HTTPS URL. Boat VMs have public IPv6 only, and the IP changes on resume. Ask Boat for
   the recommended HTTPS hostname first. If there is none, run a Cloudflare quick tunnel on the VM
   (no account needed; the URL changes every time the tunnel restarts):
   ```sh
   docker run -d --name bloom-tunnel --restart unless-stopped --network host \
     cloudflare/cloudflared:2025.11.1 tunnel --no-autoupdate --url http://localhost:80
   docker logs bloom-tunnel 2>&1 | grep -o 'https://[a-z0-9-]*\.trycloudflare\.com'
   ```
   Open `<url>/intake/` and `<url>/doctor/` from a phone on cellular, and run
   `BASE_URL=<url> scripts/smoke.sh` from your laptop.
5. Raise auto-stop so the VM stays up across Nov 18–21 (the default is 1 hour). Check
   `boat --help` for the exact auto-stop flag on your CLI version. Containers use
   `restart: unless-stopped`, so they come back after a resume; a quick tunnel prints a new URL.
6. Once every scenario passes (Thu), snapshot the demo: `boat fork`, and demo from the fork.

## Updating

```sh
git pull && docker compose up -d --build && scripts/smoke.sh
```

## Useful commands

```sh
docker compose logs -f api        # server logs (uvicorn access log is off; nginx logs path only, no query strings)
docker compose logs -f web
docker compose down               # stop; keeps the bloom-data volume
docker compose down -v            # stop AND delete the database volume
```

## Notes

- With no `.env` the stack still starts in dev mode: healthz and both apps work, and the
  message step fails with 502 `model_error`. `scripts/smoke.sh` reports that as a warning only
  when healthz says `trustedrouter_configured: false`.
- `scenarios/` (S1–S10 and `evidence-cache/`) is baked into the api image at `/app/scenarios`,
  the path `app/main.py` and `app/retrieve.py` resolve. Evidence fetched at run time is cached
  inside the container and is lost when the container is recreated; commit cache files from a
  dev machine if they must persist.
- The web image pins Flutter 3.50.0 by tarball and sha256 (there is no official 3.50.0 Docker
  image). Both apps are built with `--dart-define=API_BASE_URL=/api`.
