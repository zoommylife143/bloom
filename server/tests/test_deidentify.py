from datetime import date

import pytest

from app.deidentify import (
    MAX_QUERIES,
    QUERY_VOCABULARY,
    NotDeidentifiedError,
    assert_deidentified,
    build_queries,
    contraception_category,
    screening_status,
    severity_bucket,
)
from app.models import AgeBand, BleedingPattern, IntakeRecord, Symptom

TODAY = date(2026, 11, 19)

# Fake, synthetic identifiers (F9). None of these belong to a real person.
FAKE_NAME = "Zorbella Quixtana"
FAKE_DOB = "03/14/1991"
FAKE_PHONE = "(555) 010-4477"
FAKE_EMAIL = "zorbella.q@example.test"
FAKE_ADDRESS = "742 Evergreen Terrace"
FAKE_MRN = "MRN 88812345"


def planted_record() -> IntakeRecord:
    return IntakeRecord(
        reason_for_visit=(
            f"Hi I'm {FAKE_NAME}, born {FAKE_DOB}, painful periods and want birth control, "
            f"call {FAKE_PHONE}"
        ),
        other_notes=f"email {FAKE_EMAIL}, I live at {FAKE_ADDRESS}, {FAKE_MRN}, heavy bleeding",
        symptom=Symptom(severity_0_10=7, location=f"left side near {FAKE_NAME}'s scar"),
        bleeding_pattern=BleedingPattern.HEAVY,
        contraception=f"pill prescribed by Dr. {FAKE_NAME}",
        medications=["Zorbaprofen 400 mg"],
        allergies=["Quixtanacillin"],
        last_pap_hpv="2019",
        last_mammogram="never",
        age_band=AgeBand.B40_49,
        pregnancy_possible="no",
    )


def test_planted_identifiers_never_reach_a_query():
    queries = build_queries(planted_record(), today=TODAY)
    assert 1 <= len(queries) <= MAX_QUERIES
    joined = " ".join(queries).lower()
    for planted in (
        "zorbella", "quixtana", "1991", "03/14", "555", "4477", "example.test", "@",
        "evergreen", "742", "88812345", "zorbaprofen", "quixtanacillin", "scar", "prescribed",
    ):
        assert planted not in joined
    for q in queries:
        assert set(q.split()) <= QUERY_VOCABULARY
        assert_deidentified(q)


def test_example_query_shape():
    rec = IntakeRecord(age_band=AgeBand.B30_39, last_pap_hpv="2019")
    assert "cervical cancer screening interval age 30-39 last test over 3 years" in build_queries(
        rec, today=TODAY
    )


def test_queries_use_structured_fields():
    rec = IntakeRecord(
        age_band=AgeBand.B25_29,
        reason_for_visit="my periods are really painful",
        symptom=Symptom(severity_0_10=6, location="lower belly"),
        contraception="thinking about an IUD",
        pregnant_or_postpartum="neither",
    )
    qs = build_queries(rec, today=TODAY)
    assert qs[0] == "dysmenorrhea management lower abdominal moderate age 25-29"
    assert "contraception counseling intrauterine device age 25-29" in qs


def test_postpartum_and_postmenopausal():
    pp = build_queries(IntakeRecord(pregnant_or_postpartum="postpartum"), today=TODAY)
    assert pp[0] == "postpartum warning signs care"
    pm = build_queries(
        IntakeRecord(age_band=AgeBand.B50_64, bleeding_pattern=BleedingPattern.SPOTTING), today=TODAY
    )
    assert pm[0] == "postmenopausal bleeding endometrial cancer evaluation"
    assert "breast cancer screening mammography age 50-64" in pm


def test_structured_pain_fallback_without_keywords():
    rec = IntakeRecord(age_band=AgeBand.B18_24, symptom=Symptom(severity_0_10=8, location="right side"))
    assert "pelvic pain evaluation one-sided severe age 18-24" in build_queries(rec, today=TODAY)


def test_at_most_four_queries():
    rec = planted_record().model_copy(update={"pregnant_or_postpartum": "postpartum"})
    assert len(build_queries(rec, today=TODAY)) == MAX_QUERIES


def test_empty_record_gives_no_queries():
    assert build_queries(IntakeRecord(), today=TODAY) == []


@pytest.mark.parametrize(
    ("value", "expected"),
    [("2019", "over 3 years"), ("2025", "up to date"), ("never", "never"), ("unknown", "unknown"),
     (None, "unknown"), ("last spring", "unknown"), ("2099", "unknown")],
)
def test_screening_status(value, expected):
    assert screening_status(value, today=TODAY, overdue_after_years=3) == expected


def test_helpers():
    assert severity_bucket(2) == "mild" and severity_bucket(5) == "moderate" and severity_bucket(9) == "severe"
    assert severity_bucket(None) is None
    assert contraception_category("the pill") == "combined oral contraceptive"
    assert contraception_category("something my aunt suggested") == "other method"
    assert contraception_category(None) is None


@pytest.mark.parametrize(
    "query",
    [
        "cervical cancer screening Zorbella",  # capitalized name
        "my name is zorbella screening",
        "dr. quixtana pelvic pain",
        "pelvic pain 03/14/1991",
        "pelvic pain 1991-03-14",
        "pelvic pain march 14",
        "pelvic pain 14th of march",
        "screening since 2019",
        "call 555-010-4477",
        "call (555) 010 4477",
        "zq@example.test screening",
        "742 evergreen terrace screening",
        "apt 4 screening",
        "record 88812345",
        "see https://example.test",
        "",
        "   ",
        "x" * 201,
    ],
)
def test_assert_deidentified_rejects(query):
    with pytest.raises(NotDeidentifiedError):
        assert_deidentified(query)


@pytest.mark.parametrize(
    "query",
    [
        "cervical cancer screening interval age 30-39 last test over 3 years",
        "heavy menstrual bleeding evaluation age 40-49",
        "breast cancer screening mammography age 65+ never screened",
        "contraception counseling IUD age 18-24",
        "HPV testing interval USPSTF",
        "dysmenorrhea management lower abdominal moderate age 25-29",
    ],
)
def test_assert_deidentified_accepts(query):
    assert_deidentified(query)


def test_error_message_does_not_echo_identifier():
    with pytest.raises(NotDeidentifiedError) as exc:
        assert_deidentified(f"screening {FAKE_EMAIL}")
    assert FAKE_EMAIL not in str(exc.value)
