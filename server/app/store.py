"""Thin repository over the SQLite schema in ``db.py`` (plan section 6).

The server owns every status transition; clients never set a status directly.
``audit_log`` rows carry actor + action + session_id only, and ``trust_events`` rows
carry call metadata only. Neither ever receives clinical free text. Synthetic data only.
"""

from __future__ import annotations

import json
import sqlite3
import threading
import uuid
from datetime import datetime
from typing import Any

from app.db import connect, init_db
from app.models import (
    Brief,
    EvidenceItem,
    IntakeRecord,
    Provenance,
    RedFlagHit,
    SessionStatus,
    TrustEvent,
    utcnow,
)


class BriefAlreadyDecided(Exception):
    """A physician decision was already recorded for this brief."""


class NotFound(Exception):
    pass


def _now() -> str:
    return utcnow().isoformat()


def _dt(value: str | None) -> datetime | None:
    return datetime.fromisoformat(value) if value else None


class Store:
    def __init__(self, path: str = ":memory:"):
        self.conn: sqlite3.Connection = connect(path)
        init_db(self.conn)
        self._lock = threading.RLock()

    # ------------------------------------------------------------------ helpers

    def _exec(self, sql: str, params: tuple = ()) -> sqlite3.Cursor:
        with self._lock:
            cur = self.conn.execute(sql, params)
            self.conn.commit()
            return cur

    def _all(self, sql: str, params: tuple = ()) -> list[sqlite3.Row]:
        with self._lock:
            return self.conn.execute(sql, params).fetchall()

    def _one(self, sql: str, params: tuple = ()) -> sqlite3.Row | None:
        with self._lock:
            return self.conn.execute(sql, params).fetchone()

    # ----------------------------------------------------------------- sessions

    def create_session(self, mode: str, scenario_id: str | None = None) -> str:
        sid = uuid.uuid4().hex
        now = _now()
        with self._lock:
            self.conn.execute(
                "INSERT INTO sessions (id, scenario_id, mode, status, created_at, updated_at) VALUES (?,?,?,?,?,?)",
                (sid, scenario_id, mode, SessionStatus.IN_PROGRESS.value, now, now),
            )
            self.conn.execute(
                "INSERT INTO intake_records (session_id, json, completed_at) VALUES (?,?,NULL)",
                (sid, IntakeRecord().model_dump_json()),
            )
            self.conn.commit()
        return sid

    def get_session(self, session_id: str) -> dict | None:
        row = self._one("SELECT * FROM sessions WHERE id = ?", (session_id,))
        return dict(row) if row else None

    def set_status(self, session_id: str, status: SessionStatus) -> None:
        self._exec(
            "UPDATE sessions SET status = ?, updated_at = ? WHERE id = ?",
            (SessionStatus(status).value, _now(), session_id),
        )

    def touch(self, session_id: str) -> None:
        self._exec("UPDATE sessions SET updated_at = ? WHERE id = ?", (_now(), session_id))

    def list_sessions(self) -> list[dict]:
        """D01 queue rows: red-flag sessions first, then newest first."""
        rows = self._all(
            """
            SELECT s.*, i.json AS intake_json, i.completed_at,
                   (SELECT rule_id FROM red_flags r WHERE r.session_id = s.id ORDER BY r.id DESC LIMIT 1) AS red_flag_rule,
                   (SELECT id FROM briefs b WHERE b.session_id = s.id LIMIT 1) AS brief_id,
                   (SELECT review_status FROM briefs b WHERE b.session_id = s.id LIMIT 1) AS review_status
            FROM sessions s LEFT JOIN intake_records i ON i.session_id = s.id
            ORDER BY (red_flag_rule IS NULL) ASC, s.created_at DESC, s.rowid DESC
            """
        )
        return [dict(r) for r in rows]

    # ----------------------------------------------------------------- messages

    def add_message(self, session_id: str, role: str, text: str) -> None:
        self._exec(
            "INSERT INTO messages (session_id, role, text, created_at) VALUES (?,?,?,?)",
            (session_id, role, text, _now()),
        )
        self.touch(session_id)

    def get_messages(self, session_id: str) -> list[dict]:
        rows = self._all(
            "SELECT role, text, created_at FROM messages WHERE session_id = ? ORDER BY id", (session_id,)
        )
        return [dict(r) for r in rows]

    # ------------------------------------------------------------------- intake

    def get_intake(self, session_id: str) -> tuple[IntakeRecord, str | None]:
        row = self._one("SELECT json, completed_at FROM intake_records WHERE session_id = ?", (session_id,))
        if row is None:
            return IntakeRecord(), None
        return IntakeRecord.model_validate_json(row["json"]), row["completed_at"]

    def save_intake(self, session_id: str, rec: IntakeRecord, *, completed: bool = False) -> None:
        with self._lock:
            self.conn.execute(
                """INSERT INTO intake_records (session_id, json, completed_at) VALUES (?,?,?)
                   ON CONFLICT(session_id) DO UPDATE SET json = excluded.json,
                   completed_at = COALESCE(intake_records.completed_at, excluded.completed_at)""",
                (session_id, rec.model_dump_json(), _now() if completed else None),
            )
            self.conn.commit()

    # ---------------------------------------------------------------- red flags

    def add_red_flag(self, session_id: str, hit: RedFlagHit) -> None:
        self._exec(
            "INSERT INTO red_flags (session_id, rule_id, matched_fields, created_at) VALUES (?,?,?,?)",
            (session_id, hit.rule_id.value, json.dumps({"matched": hit.matched, "source": hit.source}), _now()),
        )

    def get_red_flag(self, session_id: str) -> dict | None:
        row = self._one(
            "SELECT * FROM red_flags WHERE session_id = ? ORDER BY id DESC LIMIT 1", (session_id,)
        )
        if row is None:
            return None
        data = json.loads(row["matched_fields"])
        return {
            "session_id": session_id,
            "rule_id": row["rule_id"],
            "matched": data.get("matched", []),
            "source": data.get("source"),
            "created_at": _dt(row["created_at"]),
        }

    # ----------------------------------------------------------------- evidence

    def add_evidence(self, session_id: str, items: list[EvidenceItem]) -> None:
        with self._lock:
            self.conn.executemany(
                "INSERT INTO evidence (session_id, query, url, title, passage, retrieved_at) VALUES (?,?,?,?,?,?)",
                [(session_id, i.query, i.url, i.title, i.passage, i.retrieved_at.isoformat()) for i in items],
            )
            self.conn.commit()

    def get_evidence(self, session_id: str) -> list[EvidenceItem]:
        rows = self._all("SELECT * FROM evidence WHERE session_id = ? ORDER BY id", (session_id,))
        return [
            EvidenceItem(
                query=r["query"], url=r["url"], title=r["title"], passage=r["passage"],
                retrieved_at=_dt(r["retrieved_at"]),
            )
            for r in rows
        ]

    # ------------------------------------------------------------------- briefs

    def save_brief(self, session_id: str, brief: Brief, provenance: Provenance) -> str:
        bid = uuid.uuid4().hex
        self._exec(
            """INSERT INTO briefs (id, session_id, json, generated_by, evidence_urls, review_status)
               VALUES (?,?,?,?,?,?)""",
            (bid, session_id, brief.model_dump_json(), provenance.generated_by,
             json.dumps({"urls": provenance.evidence_urls, "created_at": provenance.created_at.isoformat()}),
             "draft"),
        )
        return bid

    def _brief_row(self, row: sqlite3.Row | None) -> dict | None:
        if row is None:
            return None
        ev = json.loads(row["evidence_urls"])
        original = Brief.model_validate_json(row["json"])
        edited = Brief.model_validate_json(row["edited_json"]) if row["edited_json"] else None
        provenance = Provenance(
            generated_by=row["generated_by"],
            evidence_urls=ev.get("urls", []),
            created_at=_dt(ev.get("created_at")) or utcnow(),
            review_status=row["review_status"],
            reviewed_by=row["reviewed_by"],
            reviewed_at=_dt(row["reviewed_at"]),
        )
        return {
            "brief_id": row["id"],
            "session_id": row["session_id"],
            "original": original,
            "edited": edited,
            "provenance": provenance,
        }

    def get_brief(self, brief_id: str) -> dict | None:
        return self._brief_row(self._one("SELECT * FROM briefs WHERE id = ?", (brief_id,)))

    def get_brief_for_session(self, session_id: str) -> dict | None:
        return self._brief_row(self._one("SELECT * FROM briefs WHERE session_id = ? LIMIT 1", (session_id,)))

    def decide_brief(
        self, brief_id: str, decision: str, reviewer: str, edited: Brief | None = None
    ) -> dict:
        """Record approve / edit / reject once. The original JSON is never overwritten."""
        status_for = {"approve": "approved", "edit": "edited", "reject": "rejected"}
        review_status = status_for[decision]
        with self._lock:
            row = self.conn.execute("SELECT * FROM briefs WHERE id = ?", (brief_id,)).fetchone()
            if row is None:
                raise NotFound(brief_id)
            if row["review_status"] != "draft":
                raise BriefAlreadyDecided(brief_id)
            now = _now()
            self.conn.execute(
                "UPDATE briefs SET review_status = ?, reviewed_by = ?, reviewed_at = ?, edited_json = ? WHERE id = ?",
                (review_status, reviewer, now,
                 edited.model_dump_json() if (decision == "edit" and edited is not None) else None, brief_id),
            )
            self.conn.execute(
                "UPDATE sessions SET status = ?, updated_at = ? WHERE id = ?",
                (SessionStatus(review_status).value, now, row["session_id"]),
            )
            self.conn.commit()
        return self.get_brief(brief_id)  # type: ignore[return-value]

    # ------------------------------------------------------------- trust events

    def record_trust_event(self, event: TrustEvent) -> None:
        """Router ``on_event`` sink. Metadata only."""
        self._exec(
            """INSERT INTO trust_events (session_id, node, mode, model_id, route, policy_required,
               evidence_json, request_id, latency_ms, outcome, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)""",
            (event.session_id, event.node, event.mode, event.model_id, event.route, event.policy_required,
             json.dumps(event.evidence, default=str), event.request_id, event.latency_ms,
             event.outcome.value, event.created_at.isoformat()),
        )

    def list_trust_events(self, session_id: str | None = None) -> list[TrustEvent]:
        if session_id is None:
            rows = self._all("SELECT * FROM trust_events ORDER BY id")
        else:
            rows = self._all("SELECT * FROM trust_events WHERE session_id = ? ORDER BY id", (session_id,))
        return [
            TrustEvent(
                session_id=r["session_id"], node=r["node"], mode=r["mode"], model_id=r["model_id"],
                route=r["route"], policy_required=r["policy_required"], evidence=json.loads(r["evidence_json"]),
                request_id=r["request_id"], latency_ms=r["latency_ms"], outcome=r["outcome"],
                created_at=_dt(r["created_at"]),
            )
            for r in rows
        ]

    # -------------------------------------------------------- guideline updates

    def add_guideline_updates(self, updates: list) -> int:
        """Store Context.dev Monitor changes (``app.monitor.GuidelineUpdate``). Dedupes on change id.

        Returns how many rows were new. Public guideline pages only; no patient data.
        """
        new = 0
        with self._lock:
            for u in updates:
                cur = self.conn.execute(
                    """INSERT OR IGNORE INTO guideline_updates (id, url, title, detected_at, change_summary, monitor_id)
                       VALUES (?,?,?,?,?,?)""",
                    (u.id, u.url, u.title, u.detected_at.isoformat(), u.change_summary[:500], u.monitor_id),
                )
                new += cur.rowcount
            self.conn.commit()
        return new

    def list_guideline_updates(self, limit: int = 20, since: datetime | None = None) -> list[dict[str, Any]]:
        """Newest first. ``since`` keeps only rows detected at or after that time."""
        if since is None:
            rows = self._all("SELECT * FROM guideline_updates ORDER BY detected_at DESC, rowid DESC LIMIT ?", (limit,))
        else:
            rows = self._all(
                "SELECT * FROM guideline_updates WHERE detected_at >= ? ORDER BY detected_at DESC, rowid DESC LIMIT ?",
                (since.isoformat(), limit),
            )
        return [{**dict(r), "detected_at": _dt(r["detected_at"])} for r in rows]

    # -------------------------------------------------------------------- audit

    def audit(self, actor: str, action: str, session_id: str | None = None) -> None:
        self._exec(
            "INSERT INTO audit_log (actor, action, session_id, created_at) VALUES (?,?,?,?)",
            (actor, action, session_id, _now()),
        )

    def list_audit(self, limit: int = 500) -> list[dict[str, Any]]:
        rows = self._all("SELECT * FROM audit_log ORDER BY id DESC LIMIT ?", (limit,))
        return [{**dict(r), "created_at": _dt(r["created_at"])} for r in rows]
