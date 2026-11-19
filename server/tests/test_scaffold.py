from fastapi.testclient import TestClient

from app.db import TABLES, connect, init_db
from app.main import app


def test_healthz():
    res = TestClient(app).get("/api/healthz")
    assert res.status_code == 200
    assert res.json()["ok"] is True


def test_db_init_creates_all_tables(tmp_path):
    conn = connect(tmp_path / "t.db")
    init_db(conn)
    names = {r["name"] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    assert set(TABLES) <= names
