"""Shared contracts (plan section 5 and 6). Every module imports its types from here.

Change a model only in coordination with every module that uses it.
"""

from datetime import date, datetime, timezone
from enum import StrEnum
from typing import ClassVar, Literal

from pydantic import BaseModel, Field


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class AgeBand(StrEnum):
    B18_24 = "18-24"
    B25_29 = "25-29"
    B30_39 = "30-39"
    B40_49 = "40-49"
    B50_64 = "50-64"
    B65_PLUS = "65+"


class BleedingPattern(StrEnum):
    REGULAR = "regular"
    IRREGULAR = "irregular"
    HEAVY = "heavy"
    SPOTTING = "spotting"
    NONE = "none"


YesNoUnsure = Literal["yes", "no", "unsure"]
# A year such as "2021", or "never" / "unknown".
YearOrNever = str


class Symptom(BaseModel):
    onset: str | None = None
    duration: str | None = None
    severity_0_10: int | None = Field(default=None, ge=0, le=10)
    location: str | None = None
    triggers: str | None = None


class IntakeRecord(BaseModel):
    """Filled by the intake node. All fields optional until the intake completes."""

    reason_for_visit: str | None = None
    symptom: Symptom | None = None
    lmp_date: date | Literal["unknown"] | None = None
    cycle_length_days: int | None = None
    bleeding_pattern: BleedingPattern | None = None
    pregnancy_possible: YesNoUnsure | None = None
    pregnant_or_postpartum: Literal["pregnant", "postpartum", "neither"] | None = None
    gravida: int | None = None
    para: int | None = None
    contraception: str | None = None
    last_pap_hpv: YearOrNever | None = None
    last_mammogram: YearOrNever | None = None
    sti_concerns: str | Literal["declined"] | None = None
    medications: list[str] = Field(default_factory=list)
    allergies: list[str] = Field(default_factory=list)
    age_band: AgeBand | None = None
    # Free text. Never sent to Context.dev (plan section 6).
    other_notes: str | None = None

    REQUIRED_FOR_DONE: ClassVar[tuple[str, ...]] = ("reason_for_visit", "age_band", "pregnancy_possible")

    def is_complete(self) -> bool:
        return all(getattr(self, f) is not None for f in self.REQUIRED_FOR_DONE)


class RedFlagRule(StrEnum):
    R1 = "R1"  # possible ectopic
    R2 = "R2"  # heavy bleeding
    R3 = "R3"  # pelvic infection signs
    R4 = "R4"  # pregnancy / postpartum warning
    R5 = "R5"  # self-harm
    R6 = "R6"  # sexual assault disclosure


class RedFlagHit(BaseModel):
    rule_id: RedFlagRule
    matched: list[str]  # keywords or field names that matched; no free text copied
    source: Literal["text", "fields"]


class SessionStatus(StrEnum):
    IN_PROGRESS = "in_progress"
    URGENT = "urgent"
    READY = "ready"  # intake done, brief drafted
    APPROVED = "approved"
    EDITED = "edited"
    REJECTED = "rejected"


class TrustOutcome(StrEnum):
    OK = "ok"
    REFUSED = "refused"
    ERROR = "error"


class TrustEvent(BaseModel):
    """One row per model or retrieval call. Metadata only, never clinical text."""

    session_id: str | None = None
    node: str
    mode: Literal["dev", "private"]
    model_id: str | None = None
    route: str | None = None  # provider that actually served, if the gateway says
    policy_required: str  # e.g. "zdr", "confidential"
    evidence: dict = Field(default_factory=dict)  # headers / receipt fields returned
    request_id: str | None = None
    latency_ms: int | None = None
    outcome: TrustOutcome
    created_at: datetime = Field(default_factory=utcnow)


class EvidenceItem(BaseModel):
    query: str
    url: str
    title: str | None = None
    passage: str
    retrieved_at: datetime = Field(default_factory=utcnow)


class ScreeningLine(BaseModel):
    text: str
    source_url: str | None = None  # None means "No guideline retrieved"


class Brief(BaseModel):
    """AI-drafted physician brief. Always a draft until a physician decides."""

    subjective: str
    objective: str
    assessment_considerations: str  # considerations for the physician, never a diagnosis
    plan_considerations: str
    flags: list[str] = Field(default_factory=list)
    screenings_possibly_due: list[ScreeningLine] = Field(default_factory=list)
    suggested_questions: list[str] = Field(default_factory=list)


class Provenance(BaseModel):
    generated_by: str  # "<model_id> (<mode>)"
    evidence_urls: list[str] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=utcnow)
    review_status: Literal["draft", "approved", "edited", "rejected"] = "draft"
    reviewed_by: str | None = None
    reviewed_at: datetime | None = None
