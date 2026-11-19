#!/usr/bin/env bash
# Bloom smoke test against a running stack (docker compose up -d).
#   scripts/smoke.sh                 # http://localhost
#   BASE_URL=https://x.example scripts/smoke.sh
# Checks: /api/healthz, login, create session, one message, /intake/, /doctor/,
# SPA deep-link fallback, cache headers (index no-cache, hashed JS immutable), gzip,
# CanvasKit served locally (no CDN), security headers and the / landing page.
# Exits non-zero on any failure.
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
  local args=(-sS -o "$TMP/body" -D "$TMP/headers" -w '%{http_code}' -X "$method" --max-time 200)
  [[ -n "$data" ]] && args+=(-H 'Content-Type: application/json' --data "$data")
  [[ -n "$token" ]] && args+=(-H "Authorization: Bearer $token")
  code="$(curl "${args[@]}" "$BASE_URL$path" || echo 000)"
}

# hdr NAME -> value of response header NAME from the last req (case-insensitive)
hdr() { tr -d '\r' < "$TMP/headers" | grep -i "^$1:" | sed 's/^[^:]*:[[:space:]]*//' | tail -n1 || true; }

# get_gz PATH -> like req GET but asks for gzip and keeps the compressed body
get_gz() {
  code="$(curl -sS -o "$TMP/body" -D "$TMP/headers" -w '%{http_code}' --max-time 60 \
    -H 'Accept-Encoding: gzip' "$BASE_URL$1" || echo 000)"
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
  cc="$(hdr Cache-Control)"
  if [[ "$cc" == *no-cache* ]]; then pass "/$app/ index.html Cache-Control: $cc"; else bad "/$app/ index.html Cache-Control is '$cc' (want no-cache)"; fi
  if [[ "$(hdr X-Content-Type-Options)" == nosniff ]]; then pass "/$app/ security headers"; else bad "/$app/ X-Content-Type-Options missing"; fi

  deep="/$app/some/deep/link"
  [[ "$app" == doctor ]] && deep="/doctor/brief/x"
  req GET "$deep"
  if [[ "$code" == 200 ]] && grep -q "<base href=\"/$app/\">" "$TMP/body" && [[ "$(hdr Cache-Control)" == *no-cache* ]]; then
    pass "GET $deep (SPA fallback, no-cache)"
  else
    bad "GET $deep -> $code (cache: $(hdr Cache-Control))"
  fi

  req GET "/$app/flutter_bootstrap.js"
  main_js=""
  if [[ "$code" == 200 ]]; then
    pass "GET /$app/flutter_bootstrap.js (Cache-Control: $(hdr Cache-Control))"
    [[ "$(hdr Cache-Control)" == *no-cache* ]] || bad "/$app/flutter_bootstrap.js must be no-cache"
    if grep -q '"useLocalCanvasKit":true' "$TMP/body"; then
      pass "/$app/ uses the bundled CanvasKit (no CDN)"
    else
      note "/$app/flutter_bootstrap.js does not set useLocalCanvasKit: CanvasKit comes from gstatic.com (build with --no-web-resources-cdn)"
    fi
    # The real entrypoint is the build config's mainJsPath (content-hashed with --web-content-hash).
    main_js="$(grep -oE '"mainJsPath":"[^"]+"' "$TMP/body" | head -n1 | sed 's/.*:"\(.*\)"/\1/' || true)"
  else
    bad "GET /$app/flutter_bootstrap.js -> $code"
  fi
  main_js="${main_js:-main.dart.js}"

  get_gz "/$app/$main_js"
  if [[ "$code" == 200 ]]; then
    pass "GET /$app/$main_js"
    if [[ "$(hdr Content-Encoding)" == gzip ]]; then pass "/$app/$main_js gzip"; else note "/$app/$main_js not gzip-encoded"; fi
    cc="$(hdr Cache-Control)"
    if [[ "$main_js" =~ \.[0-9a-f]{8,}\.js$ ]]; then
      if [[ "$cc" == *immutable* ]]; then pass "/$app/$main_js Cache-Control: $cc"; else bad "/$app/$main_js is hashed but Cache-Control is '$cc'"; fi
    else
      note "/$app/main.dart.js is not content-hashed (build with --web-content-hash); Cache-Control: $cc"
    fi
  else
    bad "GET /$app/$main_js -> $code"
  fi

  code="$(curl -sS -o /dev/null -w '%{http_code}' -I --max-time 30 "$BASE_URL/$app/canvaskit/canvaskit.wasm" || echo 000)"
  if [[ "$code" == 200 ]]; then pass "GET /$app/canvaskit/canvaskit.wasm (served locally)"; else note "/$app/canvaskit/canvaskit.wasm -> $code (CanvasKit not bundled; the app needs the gstatic CDN)"; fi
done

# 6. landing page at / with relative links to both apps (works behind any host, port or HTTPS tunnel)
status="$(curl -sS -o "$TMP/landing" -w '%{http_code}' "$BASE_URL/" || true)"
if [[ "$status" == 200 ]] && grep -q 'href="/intake/"' "$TMP/landing" && grep -q 'href="/doctor/"' "$TMP/landing"; then
  pass "GET / -> 200 landing page linking /intake/ and /doctor/"
else
  bad "GET / -> $status (want 200 landing page with links to /intake/ and /doctor/)"
fi
for asset in bloom-logo.svg zoom-my-life-logo.png; do
  code="$(curl -sS -o /dev/null -w '%{http_code}' "$BASE_URL/$asset" || echo 000)"
  if [[ "$code" == 200 ]]; then pass "GET /$asset"; else bad "GET /$asset -> $code"; fi
done

echo
if [[ "$fail" != 0 ]]; then echo "SMOKE: FAILED"; exit 1; fi
if [[ "$warn" != 0 ]]; then echo "SMOKE: PASSED WITH WARNINGS"; exit 0; fi
echo "SMOKE: PASSED"
