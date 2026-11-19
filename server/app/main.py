"""FastAPI entry point. Endpoints from plan section 6 are added by the graph/API step."""

from fastapi import FastAPI

from app.config import get_settings

app = FastAPI(title="Bloom API", version="0.1.0")


@app.get("/api/healthz")
def healthz() -> dict:
    settings = get_settings()
    return {"ok": True, "mode": settings.bloom_mode}
