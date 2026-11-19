"""Tests for app.safety. Synthetic messages only; no real patient data."""

import json
from pathlib import Path

import pytest

from app import safety
from app.models import BleedingPattern, IntakeRecord, RedFlagRule, Symptom
from app.safety import (
    NEXT_QUESTION_PLACEHOLDER,
    URGENT_MESSAGES,
    check_fields,
    check_text,
    filter_patient_reply,
)

R1, R2, R3, R4, R5, R6 = (RedFlagRule(f"R{i}") for i in range(1, 7))

PREG_UNSURE = IntakeRecord(pregnancy_possible="unsure")
PREG_NO = IntakeRecord(pregnancy_possible="no")
POSTPARTUM = IntakeRecord(pregnancy_possible="no", pregnant_or_postpartum="postpartum")
PREGNANT = IntakeRecord(pregnancy_possible="yes", pregnant_or_postpartum="pregnant")
NEITHER = IntakeRecord(pregnancy_possible="no", pregnant_or_postpartum="neither")

# (message, context, expected rule)
POSITIVE_TEXT = [
    # R1
    ("I have sharp pain on my left side, low in my belly", PREG_UNSURE, R1),
    ("My period is late and I feel really dizzy", PREG_NO, R1),  # text cue overrides "no"
    ("I missed my period and there's a stabbing pain on the right", None, R1),
    ("The pain is 9/10 right now", IntakeRecord(pregnancy_possible="yes"), R1),
    ("I almost passed out earlier", None, R1),  # unknown pregnancy counts as "not no"
    # R2
    ("I'm soaking through a pad every hour", NEITHER, R2),
    ("I've been changing my tampon every hour since this morning", NEITHER, R2),
    ("I'm passing clots the size of a golf ball", NEITHER, R2),
    ("There is a lot of bleeding and I feel lightheaded", PREG_NO, R2),
    ("I feel faint", IntakeRecord(pregnancy_possible="no", bleeding_pattern=BleedingPattern.HEAVY), R2),
    # R3
    ("I have a fever and pelvic pain", NEITHER, R3),
    ("My temperature was 101.2 and my lower belly hurts", NEITHER, R3),
    ("I've been running a temperature since yesterday", IntakeRecord(
        pregnancy_possible="no", symptom=Symptom(location="lower abdomen", severity_0_10=5)), R3),
    # R4
    ("I had my baby two weeks ago and now I have a severe headache", NEITHER, R4),
    ("I have blurry vision and seeing spots", POSTPARTUM, R4),
    ("I'm 30 weeks pregnant and I'm short of breath", None, R4),
    ("My chest hurts", PREGNANT, R4),
    ("I had a seizure this morning", POSTPARTUM, R4),
    # R5
    ("Sometimes I think about killing myself", None, R5),
    ("Honestly I just want to die", NEITHER, R5),
    ("I've had thoughts of hurting myself lately", PREG_NO, R5),
    ("I can't stop thinking about ending my life", None, R5),
    ("I don't want to be alive anymore", None, R5),
    # R6
    ("I was raped last weekend", None, R6),
    ("Someone forced me to have sex at a party", NEITHER, R6),
    ("I was sexually assaulted a few days ago", None, R6),
    ("It happened against my will", None, R6),
]

# Look-alike negatives: (message, context). None of these may fire.
NEGATIVE_TEXT = [
    # R1
    ("I have sharp pain on my left side", PREG_NO),  # pregnancy ruled out, no text cue
    ("I'm not dizzy and the pain is mild", PREG_UNSURE),
    ("Mild cramps, about a 3 out of 10", PREG_UNSURE),
    ("I fainted once in high school", PREG_UNSURE),  # distant past
    # R2
    ("My period pad lasts all day", NEITHER),
    ("I change my pad every 4 hours on heavy days", NEITHER),
    ("Small clots sometimes, no big ones", NEITHER),
    ("Heavy periods but I've never fainted", IntakeRecord(
        pregnancy_possible="no", bleeding_pattern=BleedingPattern.HEAVY)),
    # R3
    ("I had a fever last year, no pain now", NEITHER),
    ("No fever, just some pelvic pain", NEITHER),
    ("I have a fever and a sore throat", NEITHER),
    # R4
    ("Postpartum, mild headache that went away", POSTPARTUM),  # decided: does not fire (documented)
    ("I have a bad headache", NEITHER),  # not pregnant or postpartum
    ("No chest pain and no trouble breathing", PREGNANT),
    # R5
    ("I've never had thoughts of hurting myself", None),
    ("No, I'm not suicidal", NEITHER),
    ("This cramping is killing me", PREG_NO),
    # R6
    ("I've never been sexually assaulted", None),
    ("My partner and I use condoms", NEITHER),
    ("I'd like STI testing after a new partner", NEITHER),
    # General
    ("Hello, I'm here for my yearly checkup", None),
    ("I'm on the pill and have no allergies", NEITHER),
]


@pytest.mark.parametrize(("message", "context", "rule"), POSITIVE_TEXT)
def test_check_text_positive(message, context, rule):
    hit = check_text(message, context)
    assert hit is not None, message
    assert hit.rule_id == rule
    assert hit.source == "text"
    assert hit.matched


@pytest.mark.parametrize(("message", "context"), NEGATIVE_TEXT)
def test_check_text_negative(message, context):
    assert check_text(message, context) is None


def test_every_rule_has_positive_and_negative_text_cases():
    assert {r for _, _, r in POSITIVE_TEXT} == set(RedFlagRule)
    counts = {r: sum(1 for *_, x in POSITIVE_TEXT if x == r) for r in RedFlagRule}
    assert all(n >= 2 for n in counts.values()), counts


def test_empty_text_returns_none():
    assert check_text("", PREG_UNSURE) is None
    assert check_text("   ", None) is None


def test_check_text_needs_a_text_part():
    """Fields alone are safety_post's job: a neutral message with a risky context does not fire."""
    ctx = IntakeRecord(pregnancy_possible="yes", symptom=Symptom(severity_0_10=9, location="left side"))
    assert check_text("Okay, thanks", ctx) is None
    assert check_fields(ctx) is not None


# --- check_fields --------------------------------------------------------------------------

POSITIVE_FIELDS = [
    (IntakeRecord(pregnancy_possible="unsure", symptom=Symptom(location="right lower abdomen")), R1,
     {"symptom.location", "pregnancy_possible"}),
    (IntakeRecord(pregnancy_possible="yes", symptom=Symptom(severity_0_10=8)), R1,
     {"symptom.severity_0_10", "pregnancy_possible"}),
    (IntakeRecord(pregnancy_possible="no", reason_for_visit="soaking a pad every hour"), R2, None),
    (IntakeRecord(pregnancy_possible="no", bleeding_pattern=BleedingPattern.HEAVY,
                  other_notes="feels lightheaded"), R2, {"bleeding_pattern"}),
    (IntakeRecord(pregnancy_possible="no", reason_for_visit="fever",
                  symptom=Symptom(location="pelvis")), R3, {"symptom.location"}),
    (IntakeRecord(pregnancy_possible="no", pregnant_or_postpartum="postpartum",
                  reason_for_visit="severe headache and vision changes"), R4, {"pregnant_or_postpartum"}),
    (IntakeRecord(other_notes="mentions suicidal thoughts", pregnancy_possible="no"), R5, None),
    (IntakeRecord(reason_for_visit="sexual assault", pregnancy_possible="unsure"), R6, None),
]


@pytest.mark.parametrize(("rec", "rule", "fields"), POSITIVE_FIELDS)
def test_check_fields_positive(rec, rule, fields):
    hit = check_fields(rec)
    assert hit is not None
    assert hit.rule_id == rule
    assert hit.source == "fields"
    if fields:
        assert fields <= set(hit.matched)


NEGATIVE_FIELDS = [
    IntakeRecord(pregnancy_possible="no", symptom=Symptom(location="left lower abdomen", severity_0_10=8)),
    IntakeRecord(pregnancy_possible="no", bleeding_pattern=BleedingPattern.HEAVY,
                 reason_for_visit="heavy regular periods and tiredness"),
    IntakeRecord(pregnancy_possible="no", symptom=Symptom(location="pelvis", severity_0_10=4),
                 reason_for_visit="painful periods"),
    IntakeRecord(pregnancy_possible="no", pregnant_or_postpartum="postpartum",
                 reason_for_visit="contraception after birth"),
    IntakeRecord(pregnancy_possible="no", sti_concerns="declined", reason_for_visit="routine screening"),
    IntakeRecord(),
]


@pytest.mark.parametrize("rec", NEGATIVE_FIELDS)
def test_check_fields_negative(rec):
    assert check_fields(rec) is None


# --- precedence and matched ------------------------------------------------------------------

@pytest.mark.parametrize(
    ("message", "context"),
    [
        ("I was raped and I want to kill myself", None),
        ("I'm soaking a pad every hour and I want to die", NEITHER),
        ("Fever, pelvic pain, and I've thought about suicide", NEITHER),
        ("Two weeks postpartum with a severe headache and thoughts of hurting myself", POSTPARTUM),
        ("Pain on my left side, I feel dizzy, and I don't want to live", PREG_UNSURE),
    ],
)
def test_r5_wins(message, context):
    hit = check_text(message, context)
    assert hit is not None and hit.rule_id == R5


def test_r5_wins_in_fields():
    rec = IntakeRecord(pregnancy_possible="yes", symptom=Symptom(severity_0_10=9),
                       other_notes="self harm thoughts")
    assert check_fields(rec).rule_id == R5


@pytest.mark.parametrize(("message", "context", "rule"), POSITIVE_TEXT)
def test_matched_never_contains_input_sentence(message, context, rule):
    hit = check_text(message, context)
    allowed = set()
    for name in dir(safety):
        val = getattr(safety, name)
        if isinstance(val, tuple) and all(isinstance(v, str) for v in val):
            allowed.update(val)
    allowed |= {safety.R1_SEVERE_PAIN_SCORE_LABEL, safety.R2_HOURLY_PAD_LABEL, safety.R3_FEVER_READING_LABEL}
    for item in hit.matched:
        assert item.lower() != message.lower()
        assert message.lower() not in item.lower()
        assert item in allowed or item in IntakeRecord.model_fields or item.startswith("symptom."), item


# --- urgent messages ---------------------------------------------------------------------------

def test_urgent_messages_cover_every_rule():
    assert set(URGENT_MESSAGES) == set(RedFlagRule)
    for msg in URGENT_MESSAGES.values():
        assert msg.title and msg.body
        tels = [a.tel for a in msg.actions]
        assert "tel:911" in tels and "tel:988" in tels
        assert msg.stop_questions


def test_default_order_911_first_and_r5_988_first():
    for rule in (R1, R2, R3, R4, R6):
        assert URGENT_MESSAGES[rule].actions[0].tel == "tel:911"
    assert URGENT_MESSAGES[R5].actions[0].tel == "tel:988"
    assert URGENT_MESSAGES[R5].actions[0].label == "Call or text 988"


def test_r6_support_and_rainn():
    msg = URGENT_MESSAGES[R6]
    assert msg.support
    assert any(a.tel == "tel:18006564673" and a.label == "National Sexual Assault Hotline" for a in msg.actions)
    assert "no more questions" in msg.body.lower()


@pytest.mark.parametrize("rule", list(RedFlagRule))
def test_urgent_messages_have_no_diagnosis_language(rule):
    msg = URGENT_MESSAGES[rule]
    text = f"{msg.title} {msg.body} {msg.support or ''}"
    assert not safety.contains_diagnosis_language(text), rule
    for word in ("hipaa", "definitely", "certainly"):
        assert word not in text.lower()


# --- patient reply filter ------------------------------------------------------------------------

DIAGNOSIS_REPLIES = [
    "It sounds like you have endometriosis.",
    "You might have PCOS based on what you said.",
    "This is likely an ectopic pregnancy.",
    "You have a yeast infection.",
    "Your symptoms are consistent with fibroids.",
    "I can't make a diagnosis, but this could be a miscarriage.",
    "You may have chlamydia, so let's ask a few more questions.",
    "That's probably nothing serious, most likely a cyst.",
    "This could be a sign of cancer.",
    "You've got a UTI.",
    "It sounds like it could be pelvic inflammatory disease.",
]

NORMAL_REPLIES = [
    "Thanks for sharing that. When did the pain start?",
    "Do you have any allergies to medicines?",
    "How long have you had these symptoms?",
    "When was your last Pap or HPV test?",
    "Is there any chance you could be pregnant?",
    "Thank you, you have been really helpful. On a scale of 0 to 10, how bad is the pain?",
    "Do you have any STI concerns you'd like to mention? You can skip this question.",
    "When was your last mammogram or other cancer screening?",
]


@pytest.mark.parametrize("reply", DIAGNOSIS_REPLIES)
def test_filter_blocks_diagnosis(reply):
    out, filtered = filter_patient_reply(reply)
    assert filtered is True
    assert out == safety.SAFE_PATIENT_REPLY
    assert NEXT_QUESTION_PLACEHOLDER in out


def test_filter_fills_next_question():
    out, filtered = filter_patient_reply("You have endometriosis.", next_question="How old are you?")
    assert filtered and out.endswith("How old are you?")
    assert NEXT_QUESTION_PLACEHOLDER not in out


@pytest.mark.parametrize("reply", NORMAL_REPLIES)
def test_filter_passes_normal_replies(reply):
    assert filter_patient_reply(reply) == (reply, False)


# --- scenarios ------------------------------------------------------------------------------------

SCENARIO_DIR = Path(__file__).resolve().parents[2] / "scenarios"

# Inline equivalents of S6-S10 (plan section 11), used whether or not the JSON files exist.
INLINE_SCENARIOS = [
    ("S6", R1, ["I missed my period about six weeks ago",
                "I have pain on one side, the left, and I feel dizzy when I stand up"]),
    ("S7", R2, ["My period has been really heavy",
                "I'm soaking a pad about every hour and I feel lightheaded"]),
    ("S8", R3, ["I've had a fever since yesterday", "My pelvic area hurts a lot too"]),
    ("S9", R4, ["I'm two weeks postpartum",
                "I've had a severe headache and my vision is blurry"]),
    ("S10", R5, ["My periods are irregular", "Lately I've had thoughts of hurting myself"]),
]


def _run_turns(turns, context=None):
    """Simulate safety_pre: check each turn with the running text of the session so far."""
    for i, turn in enumerate(turns):
        hit = check_text(turn, context) or check_text(" . ".join(turns[: i + 1]), context)
        if hit is not None:
            return hit
    return None


@pytest.mark.parametrize(("sid", "rule", "turns"), INLINE_SCENARIOS)
def test_inline_scenarios(sid, rule, turns):
    hit = _run_turns(turns)
    assert hit is not None and hit.rule_id == rule, sid


def _load_scenarios(ids):
    out = []
    for sid in ids:
        path = SCENARIO_DIR / f"{sid}.json"
        if path.exists():
            out.append(pytest.param(json.loads(path.read_text()), id=sid))
    return out or [pytest.param(None, marks=pytest.mark.skip(reason="scenarios/*.json not present"))]


def _context(data):
    fields = data.get("expected_fields") or {}
    try:
        return IntakeRecord.model_validate(fields)
    except Exception:  # partial or loose fixture: fall back to no context
        return None


@pytest.mark.parametrize("data", _load_scenarios([f"S{i}" for i in range(6, 11)]))
def test_red_flag_scenarios_from_json(data):
    hit = _run_turns(data["turns"]) or _run_turns(data["turns"], _context(data))
    assert hit is not None, data["id"]
    assert hit.rule_id == data["expected"]["rule_id"], data["id"]


@pytest.mark.parametrize("data", _load_scenarios([f"S{i}" for i in range(1, 6)]))
def test_brief_scenarios_do_not_fire(data):
    ctx = _context(data)
    for turn in data["turns"]:
        assert check_text(turn, ctx) is None, (data["id"], check_text(turn, ctx))
    if ctx is not None:
        assert check_fields(ctx) is None, data["id"]
