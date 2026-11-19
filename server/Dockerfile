# Bloom API image. Build context is the REPO ROOT (see docker-compose.yml) so the
# image can carry scenarios/ at the path app/main.py and app/retrieve.py expect:
#   /app/server/app/main.py  -> parents[2] = /app  -> /app/scenarios
# Secrets are never baked in: configuration comes from the environment at runtime
# (docker compose env_file .env). Synthetic data only.
FROM python:3.12.12-slim-bookworm

COPY --from=ghcr.io/astral-sh/uv:0.12.0 /uv /usr/local/bin/uv

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    PATH="/app/server/.venv/bin:$PATH" \
    DATABASE_URL="sqlite:////data/bloom.db"

RUN groupadd --system --gid 10001 bloom \
 && useradd --system --uid 10001 --gid bloom --home-dir /app --shell /usr/sbin/nologin bloom

WORKDIR /app/server

# Dependencies first (cached layer), exactly as locked.
COPY server/pyproject.toml server/uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY server/app ./app
COPY scenarios /app/scenarios

# /data is the SQLite volume; evidence-cache must be writable (retriever caches there).
RUN mkdir -p /data \
 && chown -R bloom:bloom /data /app/scenarios/evidence-cache

USER bloom
VOLUME ["/data"]
EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=5 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/api/healthz', timeout=2).status == 200 else 1)"

# --no-access-log: request lines can carry query strings; nginx logs a path-only line.
# --timeout-keep-alive 75: longer than nginx's upstream keepalive_timeout (60s), so nginx
# never reuses a connection uvicorn has already closed (that shows up as random 502s).
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-access-log", "--timeout-keep-alive", "75"]
