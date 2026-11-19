"""SQLite schema (plan section 6). Synthetic data only.

audit_log and trust_events hold metadata only: no clinical free text.
"""

import sqlite3
from pathlib import Path

SCHEMA = """
CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    scenario_id TEXT,
    mode TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id),
    role TEXT NOT NULL,
    text TEXT NOT NULL,
    created_at TEXT NOT NULL,
    -- Bloom turns only: JSON {"extracted", "done", "parse_path", "asked_field"} so later
    -- intake prompts can show the turn as JSON and the fallback never repeats a question.
    meta TEXT
);
CREATE TABLE IF NOT EXISTS intake_records (
    session_id TEXT PRIMARY KEY REFERENCES sessions(id),
    json TEXT NOT NULL,
    completed_at TEXT
);
CREATE TABLE IF NOT EXISTS red_flags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id),
    rule_id TEXT NOT NULL,
    matched_fields TEXT NOT NULL,
    created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS evidence (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id),
    query TEXT NOT NULL,
    url TEXT NOT NULL,
    title TEXT,
    passage TEXT NOT NULL,
    retrieved_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS briefs (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES sessions(id),
    json TEXT NOT NULL,
    generated_by TEXT NOT NULL,
    evidence_urls TEXT NOT NULL,
    review_status TEXT NOT NULL DEFAULT 'draft',
    reviewed_by TEXT,
    reviewed_at TEXT,
    edited_json TEXT
);
CREATE TABLE IF NOT EXISTS trust_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    node TEXT NOT NULL,
    mode TEXT NOT NULL,
    model_id TEXT,
    route TEXT,
    policy_required TEXT NOT NULL,
    evidence_json TEXT NOT NULL,
    request_id TEXT,
    latency_ms INTEGER,
    outcome TEXT NOT NULL,
    created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    actor TEXT NOT NULL,
    action TEXT NOT NULL,
    session_id TEXT,
    created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS guideline_updates (
    id TEXT PRIMARY KEY,
    url TEXT NOT NULL,
    title TEXT,
    detected_at TEXT NOT NULL,
    change_summary TEXT NOT NULL,
    monitor_id TEXT
);
-- Idempotent resends: the response to a patient turn, keyed by the client's message id.
-- Holds the same reply text Bloom already stored in messages; no new patient text.
CREATE TABLE IF NOT EXISTS turn_results (
    session_id TEXT NOT NULL REFERENCES sessions(id),
    client_message_id TEXT NOT NULL,
    response_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    PRIMARY KEY (session_id, client_message_id)
);
CREATE INDEX IF NOT EXISTS guideline_updates_detected ON guideline_updates (detected_at);
"""

TABLES = (
    "sessions",
    "messages",
    "intake_records",
    "red_flags",
    "evidence",
    "briefs",
    "trust_events",
    "audit_log",
    "guideline_updates",
    "turn_results",
)


def connect(path: str | Path) -> sqlite3.Connection:
    conn = sqlite3.connect(str(path), check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db(conn: sqlite3.Connection) -> None:
    conn.executescript(SCHEMA)
    cols = {r[1] for r in conn.execute("PRAGMA table_info(evidence)")}
    if "title" not in cols:  # databases created before the title column
        conn.execute("ALTER TABLE evidence ADD COLUMN title TEXT")
    cols = {r[1] for r in conn.execute("PRAGMA table_info(messages)")}
    if "meta" not in cols:  # databases created before the meta column
        conn.execute("ALTER TABLE messages ADD COLUMN meta TEXT")
    conn.commit()
