import json
import re
from pathlib import Path

import pytest

from app.models import AgeBand, IntakeRecord, RedFlagRule

SCENARIO_DIR = Path(__file__).resolve().parents[2] / "scenarios"
IDS = [f"S{i}" for i in range(1, 11)]
URGENT = {"S6": "R1", "S7": "R2", "S8": "R3", "S9": "R4", "S10": "R5"}
TOP_KEYS = {"id", "summary", "age_band", "turns", "expected", "expected_fields"}
EXPECTED_KEYS = {"outcome", "rule_id", "brief_must_include", "max_turns"}


def load(sid: str) -> dict:
    return json.loads((SCENARIO_DIR / f"{sid}.json").read_text(encoding="utf-8"))


def test_exactly_ten_scenarios():
    assert sorted(p.stem for p in SCENARIO_DIR.glob("S*.json")) == sorted(IDS)


@pytest.mark.parametrize("sid", IDS)
def test_scenario_schema(sid):
    s = load(sid)
    assert set(s) <= TOP_KEYS and {"id", "summary", "age_band", "turns", "expected"} <= set(s)
    assert s["id"] == sid
    AgeBand(s["age_band"])
    assert s["turns"] and all(isinstance(t, str) and t.strip() for t in s["turns"])
    exp = s["expected"]
    assert set(exp) <= EXPECTED_KEYS
    assert exp["outcome"] in ("brief", "urgent")
    assert exp["max_turns"] == 12 and len(s["turns"]) <= exp["max_turns"]
    if "rule_id" in exp:
        RedFlagRule(exp["rule_id"])
    if "expected_fields" in s:
        rec = IntakeRecord.model_validate(s["expected_fields"])
        assert rec.age_band is None or rec.age_band.value == s["age_band"]


@pytest.mark.parametrize("sid", IDS)
def test_expected_outcome(sid):
    exp = load(sid)["expected"]
    if sid in URGENT:
        assert exp["outcome"] == "urgent" and exp["rule_id"] == URGENT[sid]
    else:
        assert exp["outcome"] == "brief" and "rule_id" not in exp
        assert exp.get("brief_must_include")


@pytest.mark.parametrize("sid", IDS)
def test_no_identifiers_in_turns(sid):
    text = " ".join(load(sid)["turns"])
    assert not re.search(r"[\w.+-]+@\w", text)  # email
    assert not re.search(r"\d{3}[\s.-]?\d{3}[\s.-]?\d{4}", text)  # phone
    assert not re.search(r"\b\d{1,2}/\d{1,2}/\d{2,4}\b", text)  # numeric date
    assert not re.search(r"\b(?:my name is|i'm called|born on)\b", text, re.I)
