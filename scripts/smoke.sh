#!/usr/bin/env bash
# Bloom smoke test against a running stack (docker compose up -d).
#   scripts/smoke.sh                 # http://localhost
#   BASE_URL=https://x.example scripts/smoke.sh
# Checks: /api/healthz, login, create session, one message, /intake/, /doctor/,
# SPA deep-link fallback and the / redirect. Exits non-zero on any failure.
# The message step may return 502 ONLY when healthz says TrustedRouter is not
# configured (no keys in .env); that is reported as a warning, not a pass.
# Synthetic data only.
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost}"
BASE_URL="${BASE_URL%/}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail=0
warn=0
pass() { printf 'PASS  %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; fail=1; }
note() { printf 'WARN  %s\n' "$1"; warn=1; }

# req METHOD PATH [JSON] [TOKEN] -> sets $code, body in $TMP/body
req() {
  local method="$1" path="$2" data="${3:-}" token="${4:-}"
  local args=(-sS -o "$TMP/body" -w '%{http_code}' -X "$method" --max-time 150)
  [[ -n "$data" ]] && args+=(-H 'Content-Type: application/json' --data "$data")
  [[ -n "$token" ]] && args+=(-H "Authorization: Bearer $token")
  code="$(curl "${args[@]}" "$BASE_URL$path" || echo 000)"
}

# json_str KEY -> first string value of "KEY" in $TMP/body
json_str() { sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$TMP/body" | head -n1; }

echo "Bloom smoke test: $BASE_URL"

# 1. health
req GET /api/healthz
tr_configured=unknown
if [[ "$code" == 200 ]] && grep -q '"ok"[[:space:]]*:[[:space:]]*true' "$TMP/body"; then
  if grep -q '"trustedrouter_configured"[[:space:]]*:[[:space:]]*true' "$TMP/body"; then tr_configured=yes; else tr_configured=no; fi
  pass "GET /api/healthz ($(tr -d '\n' < "$TMP/body"))"
else
  bad "GET /api/healthz -> $code"
fi

# 2. login (demo token, not production auth)
req POST /api/login '{"role":"patient"}'
token="$(json_str token)"
if [[ "$code" == 200 && -n "$token" ]]; then pass "POST /api/login (patient)"; else bad "POST /api/login -> $code"; fi

# 3. session
session_id=""
if [[ -n "$token" ]]; then
  req POST /api/sessions '{}' "$token"
  session_id="$(json_str session_id)"
  if [[ "$code" == 200 && -n "$session_id" ]]; then pass "POST /api/sessions"; else bad "POST /api/sessions -> $code"; fi
fi

# 4. one message (synthetic text)
if [[ -n "$session_id" ]]; then
  req POST "/api/sessions/$session_id/messages" '{"text":"Synthetic test: mild cramps for two days, no other symptoms."}' "$token"
  if [[ "$code" == 200 ]]; then
    pass "POST /api/sessions/{id}/messages"
  elif [[ "$code" == 502 && "$tr_configured" == no ]]; then
    note "POST /api/sessions/{id}/messages -> 502 ($(json_str error)): TRUSTEDROUTER_API_KEY is not set in .env, so the model call cannot run. Set the keys and re-run for a full pass."
  else
    bad "POST /api/sessions/{id}/messages -> $code ($(tr -d '\n' < "$TMP/body" | head -c 200))"
  fi
fi

# 5. web apps
for app in intake doctor; do
  req GET "/$app/"
  if [[ "$code" == 200 ]] && grep -q "<base href=\"/$app/\">" "$TMP/body"; then
    pass "GET /$app/"
  else
    bad "GET /$app/ -> $code (or base href /$app/ missing)"
  fi
  req GET "/$app/some/deep/link"
  if [[ "$code" == 200 ]] && grep -q "<base href=\"/$app/\">" "$TMP/body"; then
    pass "GET /$app/some/deep/link (SPA fallback)"
  else
    bad "GET /$app/some/deep/link -> $code"
  fi
  req GET "/$app/main.dart.js"
  if [[ "$code" == 200 ]]; then pass "GET /$app/main.dart.js"; else bad "GET /$app/main.dart.js -> $code"; fi
done

# 6. root redirect
loc="$(curl -sS -o /dev/null -w '%{http_code} %{redirect_url}' "$BASE_URL/" || true)"
if [[ "$loc" == 302*"/intake/" ]]; then pass "GET / -> /intake/"; else bad "GET / -> $loc"; fi

echo
if [[ "$fail" != 0 ]]; then echo "SMOKE: FAILED"; exit 1; fi
if [[ "$warn" != 0 ]]; then echo "SMOKE: PASSED WITH WARNINGS (model keys missing)"; exit 0; fi
echo "SMOKE: PASSED"
