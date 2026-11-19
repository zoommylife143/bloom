#!/usr/bin/env bash
# Bloom one-shot deploy: build, start, wait for healthy, verify the DB is on the volume, smoke.
#   scripts/deploy.sh                    # build + up + smoke on BLOOM_HTTP_PORT (default 80)
#   BLOOM_HTTP_PORT=8080 scripts/deploy.sh
#   scripts/deploy.sh --no-build         # restart/recreate with the existing images
#   scripts/deploy.sh --no-smoke         # skip scripts/smoke.sh
# Never prints .env (compose reads it; this script does not).
set -euo pipefail

cd "$(dirname "$0")/.."

build=1
smoke=1
for arg in "$@"; do
  case "$arg" in
    --no-build) build=0 ;;
    --no-smoke) smoke=0 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

step() { printf '\n==> %s\n' "$1"; }
die()  { printf 'DEPLOY FAILED: %s\n' "$1" >&2; exit 1; }

command -v docker >/dev/null || die "docker is not installed"
docker compose version >/dev/null 2>&1 || die "docker compose plugin is missing"

if [[ -f .env ]]; then
  echo ".env found (not printed)"
else
  echo "WARN: no .env; starting in dev mode without model keys (cp .env.example .env to configure)"
fi

if [[ "$build" == 1 ]]; then
  step "Building images (first web build downloads Flutter, ~10 min; later builds are cached)"
  start=$SECONDS
  docker compose build
  echo "build took $((SECONDS - start)) s"
fi

step "Starting the stack and waiting for healthy containers"
docker compose up -d --remove-orphans --wait --wait-timeout 240 \
  || { docker compose ps; docker compose logs --tail 50 api web; die "containers did not become healthy"; }
docker compose ps

step "Checking the SQLite database is on the bloom-data volume"
# Only test, never print: DATABASE_URL may come from .env.
docker compose exec -T api sh -c 'case "$DATABASE_URL" in sqlite:////data/*) exit 0;; *) exit 1;; esac' \
  || die "DATABASE_URL in the api container is not under /data (the volume); data would be lost on recreate"
echo "DATABASE_URL points into /data (bloom-data volume)"

# Host port as Docker actually published it (works whether BLOOM_HTTP_PORT came from env or .env).
port="$(docker compose port web 8080 | head -n1 | sed 's/.*://')"
[[ -n "$port" ]] || die "could not find the published web port"
base="${BASE_URL:-http://localhost:$port}"

if [[ "$smoke" == 1 ]]; then
  step "Smoke test against $base"
  BASE_URL="$base" scripts/smoke.sh || die "smoke test failed (docker compose logs api web)"

  # The smoke run created a session, so the database file must now exist on the volume.
  db_path="$(docker compose exec -T api sh -c 'printf %s "${DATABASE_URL#sqlite:///}"')"
  docker compose exec -T api test -s "$db_path" \
    || die "database file $db_path does not exist after the smoke run"
  echo "database file $db_path exists on the volume"
fi

step "Bloom is up"
echo "  Patient app: $base/intake/"
echo "  Clinic app:  $base/doctor/"
echo "  API health:  $base/api/healthz"
echo "Public HTTPS: boat host <sandbox-id> $port --public --title \"Bloom\" (deploy/README.md step 4)."
