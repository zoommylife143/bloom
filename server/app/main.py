"""FastAPI entry point: the HTTP API both Flutter apps call (plan section 6).

All routes live under ``/api``. The contract is documented in ``docs/api-contract.md``
and at ``/docs`` (OpenAPI). Synthetic data only.

DEMO LOGIN ONLY: ``POST /api/login`` hands out an HMAC-signed role token for anyone who
asks. It separates the patient and clinic demo views; it is not production
authentication and must not be used as such.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import re
import secrets
import threading
import time
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Callable, Literal

from fastapi import APIRouter, Depends, FastAPI, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from app import attestation, monitor
from app.config import Settings, get_settings
from app.graph import BloomGraph, SessionLocked, SessionNotFound, progress, urgent_payload
from app.models import Brief, EvidenceItem, IntakeRecord, Provenance, SessionStatus, TrustEvent, utcnow
from app.prompts import OPENING_QUESTION
from app.retrieve import GuidelineRetriever
from app.router import ConfidentialRouteUnavailable, ModelCallError, ModelRouter
from app.store import BriefAlreadyDecided, NotFound, Store

SCENARIO_DIR = Path(__file__).resolve().parents[2] / "scenarios"
TOKEN_TTL_S = 12 * 3600
GUIDELINE_UPDATE_WINDOW = timedelta(days=7)


# ============================================================== services


@dataclass
class Services:
    settings: Settings
    store: Store
    router: Any
    retriever: Any
    graph: BloomGraph
    attestation: Callable[[], dict]
    secret: bytes


def build_services(
    settings: Settings | None = None,
    *,
    store: Store | None = None,
    router: Any = None,
    retriever: Any = None,
    attestation_fn: Callable[[], dict] | None = None,
) -> Services:
    settings = settings or get_settings()
    store = store or Store(settings.sqlite_path)
    router = router or ModelRouter(settings, on_event=store.record_trust_event)
    retriever = retriever or GuidelineRetriever(settings)
    # No configured secret: a random per-process one (tokens die on restart).
    secret = (settings.demo_login_secret or secrets.token_hex(32)).encode()
    return Services(
        settings=settings,
        store=store,
        router=router,
        retriever=retriever,
        graph=BloomGraph(settings, store, router, retriever),
        attestation=attestation_fn or attestation.fetch_gateway_attestation,
        secret=secret,
    )


# =============================================================== schemas


class ErrorResponse(BaseModel):
    error: str
    detail: str | None = None


class HealthResponse(BaseModel):
    ok: bool
    mode: Literal["dev", "private"]
    trustedrouter_configured: bool


class LoginRequest(BaseModel):
    role: Literal["patient", "doctor"]


class LoginResponse(BaseModel):
    token: str
    role: Literal["patient", "doctor"]
    expires_at: int  # unix seconds


class CreateSessionRequest(BaseModel):
    scenario_id: str | None = None


class CreateSessionResponse(BaseModel):
    session_id: str
    mode: Literal["dev", "private"]
    status: SessionStatus
    reply: str  # Bloom's first question
    progress: float


class MessageRequest(BaseModel):
    text: str = Field(min_length=1, max_length=4000)


class UrgentActionOut(BaseModel):
    label: str
    tel: str


class UrgentMessageOut(BaseModel):
    rule_id: str
    title: str
    body: str
    actions: list[UrgentActionOut]
    support: str | None = None


class MessageResponse(BaseModel):
    reply: str
    status: SessionStatus
    progress: float = Field(ge=0, le=1)
    done: bool  # true when the patient flow ends (urgent or intake finished)
    urgent: UrgentMessageOut | None = None


class SessionSummary(BaseModel):
    session_id: str
    scenario_id: str | None
    mode: str
    status: SessionStatus
    created_at: datetime
    updated_at: datetime
    red_flag_rule: str | None = None
    brief_id: str | None = None
    review_status: str | None = None
    age_band: str | None = None
    reason_for_visit: str | None = None


class SessionListResponse(BaseModel):
    sessions: list[SessionSummary]


class BriefResponse(BaseModel):
    brief_id: str
    session_id: str
    brief: Brief  # what the physician sees: the edited version if edited, else the draft
    original_brief: Brief  # the AI draft, never overwritten
    edited: bool
    provenance: Provenance
    evidence: list[EvidenceItem]
    # Optional, added for the "guideline updated" banner: evidence URLs whose page a
    # Context.dev Monitor reported as changed in the last 7 days. Older clients ignore it.
    guideline_updates: list[str] = Field(default_factory=list)


class GuidelineUpdateOut(BaseModel):
    url: str
    title: str | None
    detected_at: datetime
    change_summary: str


class GuidelineUpdatesResponse(BaseModel):
    updates: list[GuidelineUpdateOut]


class WebhookAck(BaseModel):
    stored: int


class DecisionRequest(BaseModel):
    decision: Literal["approve", "edit", "reject"]
    edited: Brief | None = None
    reviewer: str = Field(min_length=1, max_length=80)


class TrustResponse(BaseModel):
    session_id: str
    mode: str
    events: list[TrustEvent]
    attestation: dict


class FlagResponse(BaseModel):
    session_id: str
    rule_id: str
    matched: list[str]
    source: str | None
    created_at: datetime
    title: str
    body: str


class AuditRow(BaseModel):
    id: int
    actor: str
    action: str
    session_id: str | None
    created_at: datetime


class AuditResponse(BaseModel):
    rows: list[AuditRow]


class NegativeTestRequest(BaseModel):
    session_id: str | None = None  # attach the refused event to a session's D03 panel


class ScenarioRunResponse(BaseModel):
    session_id: str
    scenario_id: str
    status: SessionStatus
    turns_run: int
    brief_id: str | None = None


# ================================================================ errors


class ApiError(Exception):
    def __init__(self, status: int, error: str, detail: str | None = None):
        self.status, self.error, self.detail = status, error, detail


ERR = {
    401: {"model": ErrorResponse, "description": "Missing or invalid demo token"},
    403: {"model": ErrorResponse, "description": "Wrong role"},
    404: {"model": ErrorResponse, "description": "Not found"},
    409: {"model": ErrorResponse, "description": "Conflict"},
    502: {"model": ErrorResponse, "description": "confidential_route_unavailable or model_error"},
}


def _model_error(services: Services, exc: Exception, session_id: str | None) -> ApiError:
    if isinstance(exc, ConfidentialRouteUnavailable):
        services.store.audit("system", "route_refused", session_id)
        return ApiError(502, "confidential_route_unavailable", "No route met the privacy floor. Nothing was sent elsewhere.")
    services.store.audit("system", "model_error", session_id)
    return ApiError(502, "model_error", "The model call failed. Please try again.")


# ================================================================== auth


def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def make_token(secret: bytes, role: str, now: int | None = None) -> tuple[str, int]:
    exp = (now or int(time.time())) + TOKEN_TTL_S
    payload = _b64(json.dumps({"role": role, "exp": exp}, separators=(",", ":")).encode())
    sig = _b64(hmac.new(secret, payload.encode(), hashlib.sha256).digest())
    return f"{payload}.{sig}", exp


def read_token(secret: bytes, token: str) -> str | None:
    try:
        payload, sig = token.split(".")
        expected = _b64(hmac.new(secret, payload.encode(), hashlib.sha256).digest())
        if not hmac.compare_digest(sig, expected):
            return None
        data = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
        if int(data["exp"]) < time.time() or data["role"] not in ("patient", "doctor"):
            return None
        return data["role"]
    except (ValueError, KeyError, TypeError):
        return None


# ================================================================== app


def create_app(services: Services | None = None) -> FastAPI:
    app = FastAPI(
        title="Bloom API",
        version="0.2.0",
        description="Bloom demo API. Synthetic data only. Demo login is not production auth.",
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
        allow_methods=["*"],
        allow_headers=["*"],
    )
    holder: dict[str, Services | None] = {"s": services}
    guard = threading.Lock()

    def svc() -> Services:
        # Built lazily so importing the module does not open the database.
        with guard:
            if holder["s"] is None:
                holder["s"] = build_services()
            return holder["s"]

    app.state.services = svc

    @app.exception_handler(ApiError)
    async def _api_error(_: Request, exc: ApiError) -> JSONResponse:
        return JSONResponse(status_code=exc.status, content={"error": exc.error, "detail": exc.detail})

    def role_of(authorization: str | None = Header(default=None)) -> str:
        if not authorization or not authorization.lower().startswith("bearer "):
            raise ApiError(401, "unauthorized", "Send Authorization: Bearer <token> from POST /api/login")
        role = read_token(svc().secret, authorization[7:].strip())
        if role is None:
            raise ApiError(401, "unauthorized", "Invalid or expired token")
        return role

    def any_role(role: str = Depends(role_of)) -> str:
        return role

    def doctor(role: str = Depends(role_of)) -> str:
        if role != "doctor":
            raise ApiError(403, "forbidden", "Doctor role required")
        return role

    api = APIRouter(prefix="/api")

    @api.get("/healthz", response_model=HealthResponse)
    def healthz() -> HealthResponse:
        settings = get_settings() if holder["s"] is None else holder["s"].settings
        return HealthResponse(
            ok=True, mode=settings.bloom_mode, trustedrouter_configured=bool(settings.trustedrouter_api_key)
        )

    @api.post("/login", response_model=LoginResponse)
    def login(body: LoginRequest) -> LoginResponse:
        s = svc()
        token, exp = make_token(s.secret, body.role)
        s.store.audit(body.role, "login", None)
        return LoginResponse(token=token, role=body.role, expires_at=exp)

    # ------------------------------------------------------------ patient

    @api.post("/sessions", response_model=CreateSessionResponse, responses=ERR)
    def create_session(body: CreateSessionRequest | None = None, role: str = Depends(any_role)) -> CreateSessionResponse:
        s = svc()
        scenario_id = body.scenario_id if body else None
        sid = s.store.create_session(s.settings.bloom_mode, scenario_id)
        s.store.add_message(sid, "bloom", OPENING_QUESTION)
        s.store.audit(role, "session_created", sid)
        return CreateSessionResponse(
            session_id=sid, mode=s.settings.bloom_mode, status=SessionStatus.IN_PROGRESS,
            reply=OPENING_QUESTION, progress=0.0,
        )

    def _turn(s: Services, session_id: str, text: str):
        try:
            return s.graph.run_turn(session_id, text)
        except SessionNotFound:
            raise ApiError(404, "session_not_found") from None
        except SessionLocked as exc:
            raise ApiError(409, "session_locked", f"Session status is {exc}") from None
        except (ConfidentialRouteUnavailable, ModelCallError) as exc:
            raise _model_error(s, exc, session_id) from None

    @api.post("/sessions/{session_id}/messages", response_model=MessageResponse, responses=ERR)
    def post_message(session_id: str, body: MessageRequest, role: str = Depends(any_role)) -> MessageResponse:
        r = _turn(svc(), session_id, body.text)
        return MessageResponse(reply=r.reply, status=r.status, progress=r.progress, done=r.done, urgent=r.urgent)

    # ------------------------------------------------------------- clinic

    @api.get("/sessions", response_model=SessionListResponse, responses=ERR)
    def list_sessions(_: str = Depends(doctor)) -> SessionListResponse:
        out = []
        for row in svc().store.list_sessions():
            rec = IntakeRecord.model_validate_json(row["intake_json"]) if row.get("intake_json") else IntakeRecord()
            reason = rec.reason_for_visit
            out.append(SessionSummary(
                session_id=row["id"], scenario_id=row["scenario_id"], mode=row["mode"], status=row["status"],
                created_at=row["created_at"], updated_at=row["updated_at"], red_flag_rule=row["red_flag_rule"],
                brief_id=row["brief_id"], review_status=row["review_status"],
                age_band=rec.age_band.value if rec.age_band else None,
                reason_for_visit=(reason[:120] if reason else None),
            ))
        return SessionListResponse(sessions=out)

    def _guideline_updates_for(s: Services, evidence: list[EvidenceItem]) -> list[str]:
        updated = {
            monitor.normalize_url(u["url"])
            for u in s.store.list_guideline_updates(limit=1000, since=utcnow() - GUIDELINE_UPDATE_WINDOW)
        }
        out: list[str] = []
        for e in evidence:
            if monitor.normalize_url(e.url) in updated and e.url not in out:
                out.append(e.url)
        return out

    def _brief_response(s: Services, b: dict) -> BriefResponse:
        evidence = s.store.get_evidence(b["session_id"])
        return BriefResponse(
            brief_id=b["brief_id"], session_id=b["session_id"],
            brief=b["edited"] or b["original"], original_brief=b["original"], edited=b["edited"] is not None,
            provenance=b["provenance"], evidence=evidence,
            guideline_updates=_guideline_updates_for(s, evidence),
        )

    @api.get("/sessions/{session_id}/brief", response_model=BriefResponse, responses=ERR)
    def get_brief(session_id: str, _: str = Depends(doctor)) -> BriefResponse:
        s = svc()
        b = s.store.get_brief_for_session(session_id)
        if b is None:
            raise ApiError(404, "brief_not_found", "No brief has been generated for this session yet")
        s.store.audit("doctor", "brief_viewed", session_id)
        return _brief_response(s, b)

    @api.post("/briefs/{brief_id}/decision", response_model=BriefResponse, responses={**ERR, 422: {"model": ErrorResponse}})
    def decide(brief_id: str, body: DecisionRequest, _: str = Depends(doctor)) -> BriefResponse:
        s = svc()
        if body.decision == "edit" and body.edited is None:
            raise ApiError(422, "edited_brief_required", "decision=edit needs an 'edited' Brief")
        try:
            b = s.store.decide_brief(brief_id, body.decision, body.reviewer, body.edited)
        except NotFound:
            raise ApiError(404, "brief_not_found") from None
        except BriefAlreadyDecided:
            raise ApiError(409, "already_decided", "A decision was already recorded for this brief") from None
        s.store.audit("doctor", f"brief_{b['provenance'].review_status}", b["session_id"])
        return _brief_response(s, b)

    @api.get("/sessions/{session_id}/trust", response_model=TrustResponse, responses=ERR)
    def trust(session_id: str, _: str = Depends(doctor)) -> TrustResponse:
        s = svc()
        session = s.store.get_session(session_id)
        if session is None:
            raise ApiError(404, "session_not_found")
        return TrustResponse(
            session_id=session_id, mode=session["mode"],
            events=s.store.list_trust_events(session_id), attestation=s.attestation(),
        )

    @api.get("/sessions/{session_id}/flag", response_model=FlagResponse, responses=ERR)
    def flag(session_id: str, _: str = Depends(doctor)) -> FlagResponse:
        f = svc().store.get_red_flag(session_id)
        if f is None:
            raise ApiError(404, "flag_not_found")
        u = urgent_payload(f["rule_id"])
        return FlagResponse(**f, title=u["title"], body=u["body"])

    @api.get("/audit", response_model=AuditResponse, responses=ERR)
    def audit(_: str = Depends(doctor)) -> AuditResponse:
        return AuditResponse(rows=[AuditRow(**r) for r in svc().store.list_audit()])

    @api.get("/guideline-updates", response_model=GuidelineUpdatesResponse, responses=ERR)
    def guideline_updates(_: str = Depends(doctor)) -> GuidelineUpdatesResponse:
        rows = svc().store.list_guideline_updates(limit=20)
        return GuidelineUpdatesResponse(updates=[
            GuidelineUpdateOut(url=r["url"], title=r["title"], detected_at=r["detected_at"],
                               change_summary=r["change_summary"])
            for r in rows
        ])

    # ------------------------------------------------------------ webhooks

    @api.post(
        "/webhooks/context-monitor", response_model=WebhookAck,
        responses={400: {"model": ErrorResponse}, 401: {"model": ErrorResponse}, 503: {"model": ErrorResponse}},
    )
    async def context_monitor_webhook(
        request: Request, x_context_signature: str | None = Header(default=None),
    ) -> WebhookAck:
        """Context.dev Monitor webhook. No demo token: the HMAC signature is the auth.

        Fails closed: no configured secret -> 503, nothing parsed or stored.
        """
        s = svc()
        secret = s.settings.context_dev_webhook_secret
        if not secret:
            raise ApiError(503, "webhook_not_configured", "webhook not configured")
        body = await request.body()  # raw bytes: the signature covers them exactly
        try:
            stored = monitor.handle_webhook(
                s.store, secret, body, x_context_signature, s.settings.guideline_domain_list
            )
        except monitor.InvalidSignature:
            raise ApiError(401, "invalid_signature", "Bad or missing X-Context-Signature") from None
        except ValueError:
            raise ApiError(400, "invalid_payload", "Body is not valid JSON") from None
        s.store.audit("context.dev", "guideline_monitor_webhook", None)
        return WebhookAck(stored=stored)

    # --------------------------------------------------------------- demo

    @api.post("/demo/negative-test", response_model=TrustEvent, responses=ERR)
    def negative_test(body: NegativeTestRequest | None = None, _: str = Depends(doctor)) -> TrustEvent:
        """Expected failure: HTTP 200 with outcome=refused. The router stores the event."""
        s = svc()
        session_id = body.session_id if body else None
        if session_id and s.store.get_session(session_id) is None:
            raise ApiError(404, "session_not_found")
        event = s.router.negative_test(session_id)
        s.store.audit("doctor", "negative_test", session_id)
        return event

    @api.post("/demo/scenarios/{scenario_id}/run", response_model=ScenarioRunResponse, responses=ERR)
    def run_scenario(scenario_id: str, _: str = Depends(doctor)) -> ScenarioRunResponse:
        s = svc()
        if not re.fullmatch(r"S\d{1,2}", scenario_id):
            raise ApiError(404, "scenario_not_found")
        path = SCENARIO_DIR / f"{scenario_id}.json"
        if not path.is_file():
            raise ApiError(404, "scenario_not_found")
        turns = json.loads(path.read_text(encoding="utf-8"))["turns"]
        sid = s.store.create_session(s.settings.bloom_mode, scenario_id)
        s.store.add_message(sid, "bloom", OPENING_QUESTION)
        s.store.audit("doctor", "scenario_run", sid)
        result, run = None, 0
        for text in turns:
            result = _turn(s, sid, text)
            run += 1
            if result.status != SessionStatus.IN_PROGRESS.value:
                break
        status = result.status if result else SessionStatus.IN_PROGRESS.value
        return ScenarioRunResponse(
            session_id=sid, scenario_id=scenario_id, status=status, turns_run=run,
            brief_id=result.brief_id if result else None,
        )

    app.include_router(api)
    return app


app = create_app()

__all__ = ["app", "create_app", "build_services", "Services", "make_token", "read_token", "progress"]
