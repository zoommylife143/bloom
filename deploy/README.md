# Deploying Bloom on a Boat.dev VM

One command serves everything on one port:

| Path | What |
| --- | --- |
| `/` | 302 to `/intake/` |
| `/intake/` | Patient app (P screens), Flutter Web |
| `/doctor/` | Clinic app (D and S screens), Flutter Web |
| `/api/` | FastAPI server (proxied by nginx to the `api` container) |

Files: `docker-compose.yml`, `server/Dockerfile`, `deploy/web.Dockerfile`, `deploy/nginx.conf`,
`deploy/nginx-security-headers.conf`, `.dockerignore`, `.env.example`, `scripts/deploy.sh`,
`scripts/smoke.sh`. SQLite lives on the `bloom-data` volume (`/data/bloom.db` in the `api`
container); `docker-compose.yml` sets `DATABASE_URL=sqlite:////data/bloom.db` unless `.env`
overrides it, and `scripts/deploy.sh` fails if the path is not under `/data`. `.env` is read at
run time only and never copied into an image.

Both containers run as non-root users (api uid 10001, nginx uid 101). nginx listens on 8080
inside the container on IPv4 and IPv6; compose publishes it on host port
`${BLOOM_HTTP_PORT:-80}` on all IPv4 and IPv6 addresses. Redirects are relative and the apps
call the relative path `/api`, so no hostname, port or scheme is baked into anything: the same
images work on `localhost:8080`, the VM's IPv6 address and an HTTPS tunnel URL.

Web and API share one origin, so the browser makes same-origin calls to `/api/` and no CORS
preflight happens. The server's CORS allow-list (localhost only) matters only for local dev,
when `flutter run` serves the app on another port.

## Boat steps (the crew runs these; see also `docs/sponsor-runbook.md` §1)

1. On your laptop, create and enter the VM (no auto-stop, so it stays up through the demo):
   ```sh
   boat new --name bloom --no-auto-stop
   boat list                         # note the sandbox id
   boat ssh
   ```
2. On the VM, clone and configure. Fill in the keys in `.env` by hand; the names come from
   `server/app/config.py` (`Settings`). Do not commit `.env`.
   ```sh
   git clone https://github.com/zoommylife143/bloom && cd bloom
   cp .env.example .env
   nano .env        # TRUSTEDROUTER_API_KEY, CONTEXT_DEV_API_KEY, DEMO_LOGIN_SECRET, BLOOM_MODE
   ```
   Leave `DATABASE_URL` unset (compose defaults it to `sqlite:////data/bloom.db`, on the volume)
   or set exactly that value; anything outside `/data` is lost on recreate. Set
   `DEMO_LOGIN_SECRET` (for example `openssl rand -hex 32`) so demo tokens survive an api restart.
3. Build, start, wait for healthy and smoke-test in one command (the first web build
   downloads Flutter 3.50.0 and compiles both apps; see build times below):
   ```sh
   scripts/deploy.sh                 # or: BLOOM_HTTP_PORT=8080 scripts/deploy.sh
   ```
   It runs `docker compose build`, `docker compose up -d --wait` (both containers must be
   "healthy"), checks that `DATABASE_URL` points into the `/data` volume, runs
   `scripts/smoke.sh` against the published port, then checks the database file exists.
   It never prints `.env`. Options: `--no-build`, `--no-smoke`. By hand:
   ```sh
   docker compose up -d --build --wait
   docker compose ps                 # api and web should both be "healthy"
   curl localhost/api/healthz        # {"ok":true,"mode":"dev","trustedrouter_configured":true}
   scripts/smoke.sh                  # healthz, login, session, message, both apps, headers
   ```
   Port 80 busy? Put `BLOOM_HTTP_PORT=8080` in `.env` (or export it) and use
   `BASE_URL=http://localhost:8080 scripts/smoke.sh`.
4. Public HTTPS URL. Boat VMs have public IPv6 only and the IP changes on resume, so do not
   use the IP. Use Boat's built-in host URL, which is stable across resume:
   ```sh
   boat host <sandbox-id> 80 --public --title "Bloom"   # from the laptop
   host 80 --public                                     # or from inside the VM
   ```
   The port is the host port (`BLOOM_HTTP_PORT`, default 80). Open `<url>/intake/` and
   `<url>/doctor/` from a phone on cellular, and run `BASE_URL=<url> scripts/smoke.sh` from your
   laptop.

   Fallback only, if `boat host` is unavailable: a Cloudflare quick tunnel on the VM (no account
   needed; the URL changes every time the tunnel restarts, including after a resume):
   ```sh
   docker run -d --name bloom-tunnel --restart unless-stopped --network host \
     cloudflare/cloudflared:2025.11.1 tunnel --no-autoupdate --url http://localhost:80
   # with BLOOM_HTTP_PORT=8080 use --url http://localhost:8080
   docker logs bloom-tunnel 2>&1 | grep -o 'https://[a-z0-9-]*\.trycloudflare\.com'
   ```
   A quick tunnel cuts any request at about 100 s; nginx allows 180 s for `/api/`, so a slow
   model call would fail at the tunnel first.
5. Keep the VM up across Nov 18–21. If it was created without `--no-auto-stop`:
   ```sh
   boat extend <sandbox-id> --hours 48      # or: boat extend <sandbox-id> --no-auto-stop
   ```
   Containers use `restart: unless-stopped`, so they come back after a resume.
6. Once every scenario passes (Thu), snapshot the demo and demo from a fork:
   ```sh
   boat snapshot <sandbox-id> bloom-demo
   boat fork <sandbox-id> --no-auto-stop --wait
   boat host <fork-id> 80 --public --title "Bloom"     # the fork needs its own public URL
   ```
   Forks default to a 1-hour TTL and do not inherit `--no-auto-stop`, so pass it on the fork.
   On the fork, run `scripts/deploy.sh --no-build` once to confirm everything is healthy.

## Updating

```sh
git pull && scripts/deploy.sh
```
Rebuilds are layer-cached: the Flutter SDK and `pub get` layers are reused unless a
`pubspec.yaml`/`pubspec.lock` changes, a `packages/` change rebuilds both apps, and an
`apps/clinic` change rebuilds only the clinic app.

## Useful commands

```sh
scripts/deploy.sh --no-build     # recreate/restart with existing images, then smoke
docker compose logs -f api        # server logs (uvicorn access log is off; nginx logs path only, no query strings)
docker compose logs -f web
docker compose down               # stop; keeps the bloom-data volume
docker compose down -v            # stop AND delete the database volume
```

## Notes

- With no `.env` the stack still starts in dev mode: healthz and both apps work, and the
  message step fails with 502 `model_error`. `scripts/smoke.sh` reports that as a warning only
  when healthz says `trustedrouter_configured: false`; with keys configured a 502 is a FAIL.
- `scenarios/` (S1–S10 and `evidence-cache/`) is baked into the api image at `/app/scenarios`,
  the path `app/main.py` and `app/retrieve.py` resolve. Evidence fetched at run time is cached
  inside the container and is lost when the container is recreated; commit cache files from a
  dev machine if they must persist.
- The web image pins Flutter 3.50.0 by tarball and sha256 (there is no official 3.50.0 Docker
  image). Both apps are built with `--dart-define=API_BASE_URL=/api`,
  `--no-web-resources-cdn` (CanvasKit is served from `/intake/canvaskit/` and
  `/doctor/canvaskit/`, so the demo does not depend on gstatic.com) and `--web-content-hash`.
- Cache policy: `index.html` (also served for every SPA deep link such as `/doctor/brief/x`),
  `flutter_bootstrap.js`, `flutter.js` and `*.json` are `no-cache`; content-hashed files
  (`main.dart.<hash>.js`, hashed assets) are `max-age=1y, immutable`; `canvaskit/` is 1 day;
  other static files 1 hour; `/api/` is `no-store`. gzip is on.
- Security headers: `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`,
  `X-Frame-Options: SAMEORIGIN`, a minimal `Permissions-Policy`. There is deliberately no CSP;
  a wrong one silently breaks Flutter (wasm, blob workers, inline bootstrap).
- nginx re-resolves the `api` hostname every 10 s, so recreating only the api container
  (`docker compose up -d api`) does not leave nginx proxying to a stale IP.
- Logs are capped at 3 x 10 MB per container.
- Build times measured on a 4-vCPU / 8 GB machine: first build from nothing about 5.5 min
  (Flutter download and precache about 1.5 min, each app compile about 1 min); after an app or
  package edit about 1.5 min; no change about 15 s. Images: `bloom-web` about 190 MB,
  `bloom-api` about 550 MB.
