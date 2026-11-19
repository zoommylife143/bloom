"""De-identified guideline queries, built from structured IntakeRecord fields only.

Context.dev gets de-identified queries only (CLAUDE.md, plan section 6). Every query
string is assembled from the fixed vocabularies below. Patient free text
(`reason_for_visit`, `other_notes`, `symptom.location`, `contraception`) is only
*matched against* keyword lists; the output is always a constant topic phrase, so
nothing the patient typed can reach a query. Medications, allergies, `lmp_date`,
gravida/para and `sti_concerns` text are never used.

`assert_deidentified` is a second, independent check run on every query before it
leaves this module and again in `retrieve.GuidelineRetriever.search`.

The vocabularies are demo triage aids and need clinician review before any use
beyond the hackathon demo.
"""

from __future__ import annotations

import re
from datetime import date

from app.models import AgeBand, BleedingPattern, IntakeRecord

MAX_QUERIES = 4

# --- fixed vocabularies ---------------------------------------------------------

# Keyword (matched in lower-cased free text) -> fixed topic phrase. First match wins
# per entry; the patient's words are never copied.
SYMPTOM_TOPICS: tuple[tuple[tuple[str, ...], str], ...] = (
    (
        (
            "painful period",
            "period pain",
            "periods are painful",
            "periods are really painful",
            "periods hurt",
            "menstrual pain",
            "cramp",
            "dysmenorrhea",
        ),
        "dysmenorrhea management",
    ),
    (("pelvic pain", "lower belly pain", "lower abdominal pain", "pelvis hurts"), "pelvic pain evaluation"),
    (("pain with sex", "painful sex", "hurts during sex"), "dyspareunia evaluation"),
    (("discharge", "itch", "odor", "odour"), "vaginitis evaluation"),
    (("hot flash", "hot flush", "night sweat", "menopause"), "menopause symptom management"),
    (("fatigue", "tired", "exhausted"), "heavy menstrual bleeding iron deficiency anemia"),
    (("missed period", "late period", "no period"), "amenorrhea evaluation"),
    (("breast lump", "breast pain"), "breast symptom evaluation"),
)

CONTRACEPTION_KEYWORDS: tuple[str, ...] = ("contracept", "birth control", "the pill", "iud", "implant")

# Contraception free text -> fixed category.
CONTRACEPTION_CATEGORIES: tuple[tuple[tuple[str, ...], str], ...] = (
    (("iud", "coil", "intrauterine"), "intrauterine device"),
    (("implant", "nexplanon"), "contraceptive implant"),
    (("pill", "oral"), "combined oral contraceptive"),
    (("patch", "ring"), "hormonal patch or ring"),
    (("shot", "injection", "depo"), "injectable contraception"),
    (("condom", "barrier", "diaphragm"), "barrier contraception"),
    (("none", "nothing", "no "), "no current method"),
)

LOCATION_TERMS: tuple[tuple[tuple[str, ...], str], ...] = (
    (("left", "right", "one side", "one-sided"), "one-sided"),
    (("pelvi", "lower abdomen", "lower belly", "low belly"), "lower abdominal"),
    (("back",), "low back"),
)

# Fixed phrases build_queries may emit outside the tables above.
FIXED_PHRASES: tuple[str, ...] = (
    "postpartum warning signs care",
    "prenatal care warning signs",
    "postmenopausal bleeding endometrial cancer evaluation",
    "heavy menstrual bleeding evaluation",
    "irregular menstrual cycles evaluation",
    "intermenstrual bleeding evaluation",
    "contraception counseling",
    "cervical cancer screening interval",
    "breast cancer screening mammography",
    "last test last mammogram over up to date years never screened",
    "mild moderate severe",
    "age 2 3",
)

# Words allowed to start with a capital letter in a query (acronyms).
ALLOWED_CAPITALIZED = frozenset({"HPV", "STI", "STIs", "IUD", "PCOS", "USPSTF", "ACOG", "CDC"})

# --- identifier patterns used by assert_deidentified ---------------------------

_MONTHS = (
    r"jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?"
    r"|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?"
)
_IDENTIFIER_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("email", re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)*", re.I)),
    ("url", re.compile(r"https?://|www\.", re.I)),
    ("phone", re.compile(r"(?:\+?1[\s.-]?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}\b")),
    ("ssn", re.compile(r"\b\d{3}-\d{2}-\d{4}\b")),
    ("date", re.compile(r"\b\d{1,4}[/.-]\d{1,2}[/.-]\d{1,4}\b")),
    ("date", re.compile(rf"\b(?:{_MONTHS})\.?\s+\d{{1,2}}(?:st|nd|rd|th)?\b", re.I)),
    ("date", re.compile(rf"\b\d{{1,2}}(?:st|nd|rd|th)?\s+(?:of\s+)?(?:{_MONTHS})\b", re.I)),
    ("date", re.compile(r"\b(?:19|20)\d{2}\b")),
    (
        "address",
        re.compile(
            r"\b\d+\s+(?:[a-z]+\s+){0,3}(?:street|st|avenue|ave|road|rd|boulevard|blvd|lane|ln"
            r"|drive|dr|way|court|ct|place|pl|terrace|parkway|pkwy|highway|hwy)\b\.?",
            re.I,
        ),
    ),
    ("address", re.compile(r"\b(?:apt|apartment|suite|unit|p\.?o\.? box)\s*#?\s*\d+", re.I)),
    ("long_number", re.compile(r"\d{5,}")),
    ("name", re.compile(r"\b(?:mr|mrs|ms|miss|mx|dr)\.?\s+[a-z]", re.I)),
    ("name", re.compile(r"\b(?:my name is|name:|i am called|i'm called)\b", re.I)),
)


class NotDeidentifiedError(ValueError):
    """A query looked like it could carry an identifier. The message names the type only."""


def assert_deidentified(query: str) -> None:
    """Raise NotDeidentifiedError if `query` contains anything that looks like an identifier.

    Checks names (honorifics, "my name is", any capitalized word that is not a known
    acronym), dates (numeric, month-name, four-digit years), phone numbers, emails,
    URLs, street addresses and long numbers. The error message names only the
    identifier type, never the matched text, so it is safe to log.
    """
    if not query or not query.strip():
        raise NotDeidentifiedError("empty query")
    if len(query) > 200:
        raise NotDeidentifiedError("query too long")
    for kind, pattern in _IDENTIFIER_PATTERNS:
        if pattern.search(query):
            raise NotDeidentifiedError(f"query contains a possible {kind}")
    for token in re.findall(r"[A-Za-z][A-Za-z'-]*", query):
        if token[0].isupper() and token not in ALLOWED_CAPITALIZED:
            raise NotDeidentifiedError("query contains a possible name")


# --- helpers ---------------------------------------------------------------------


def _match_topic(text: str, table: tuple[tuple[tuple[str, ...], str], ...]) -> list[str]:
    found: list[str] = []
    for keywords, topic in table:
        if any(k in text for k in keywords) and topic not in found:
            found.append(topic)
    return found


def severity_bucket(score: int | None) -> str | None:
    if score is None:
        return None
    if score <= 3:
        return "mild"
    if score <= 6:
        return "moderate"
    return "severe"


def screening_status(value: str | None, *, today: date, overdue_after_years: int) -> str:
    """Map a stored year ("2019"), "never" or "unknown" to a fixed status phrase."""
    if value is None:
        return "unknown"
    v = value.strip().lower()
    if v == "never":
        return "never"
    if not re.fullmatch(r"\d{4}", v):
        return "unknown"
    years = today.year - int(v)
    if years < 0:
        return "unknown"
    return f"over {overdue_after_years} years" if years > overdue_after_years else "up to date"


def contraception_category(value: str | None) -> str | None:
    if not value:
        return None
    hits = _match_topic(value.lower(), CONTRACEPTION_CATEGORIES)
    return hits[0] if hits else "other method"


def _query_vocabulary() -> frozenset[str]:
    phrases = list(FIXED_PHRASES)
    for table in (SYMPTOM_TOPICS, CONTRACEPTION_CATEGORIES, LOCATION_TERMS):
        phrases.extend(topic for _, topic in table)
    phrases.extend(b.value for b in AgeBand)
    return frozenset(w for p in phrases for w in p.split())


QUERY_VOCABULARY = _query_vocabulary()


def _assert_vocabulary(query: str) -> None:
    """Every word of a built query must come from the fixed vocabularies (defense in depth)."""
    if any(w not in QUERY_VOCABULARY for w in query.split()):
        raise NotDeidentifiedError("query contains a word outside the fixed vocabulary")


_OLDER_BANDS = {AgeBand.B50_64, AgeBand.B65_PLUS}
_MAMMO_BANDS = {AgeBand.B40_49, AgeBand.B50_64, AgeBand.B65_PLUS}


def build_queries(rec: IntakeRecord, *, today: date | None = None) -> list[str]:
    """Return at most MAX_QUERIES de-identified guideline queries, most relevant first.

    Uses: age band, bleeding pattern, symptom keyword topic + location term + severity
    bucket, pregnancy/postpartum status, Pap/HPV and mammogram status (from the year),
    and contraception category. Every query passes `assert_deidentified` and is made
    only of words from the fixed vocabularies (`QUERY_VOCABULARY`).
    """
    today = today or date.today()
    age = f"age {rec.age_band.value}" if rec.age_band else ""
    free_text = " ".join(t for t in (rec.reason_for_visit, rec.other_notes) if t).lower()
    queries: list[str] = []

    def add(*parts: str | None) -> None:
        q = " ".join(p for p in parts if p).strip()
        if q and q not in queries:
            queries.append(q)

    # 1. Pregnancy / postpartum status.
    if rec.pregnant_or_postpartum == "postpartum":
        add("postpartum warning signs care")
    elif rec.pregnant_or_postpartum == "pregnant":
        add("prenatal care warning signs", age)

    # 2. Bleeding pattern.
    bp = rec.bleeding_pattern
    if bp == BleedingPattern.SPOTTING and rec.age_band in _OLDER_BANDS:
        add("postmenopausal bleeding endometrial cancer evaluation")
    elif bp == BleedingPattern.HEAVY:
        add("heavy menstrual bleeding evaluation", age)
    elif bp == BleedingPattern.IRREGULAR:
        add("irregular menstrual cycles evaluation", age)
    elif bp == BleedingPattern.SPOTTING:
        add("intermenstrual bleeding evaluation", age)

    # 3. Symptom topic, through fixed vocabularies only.
    sym = rec.symptom
    sym_text = free_text + " " + (sym.location.lower() if sym and sym.location else "")
    topics = _match_topic(sym_text, SYMPTOM_TOPICS)
    location = None
    if sym and sym.location:
        locs = _match_topic(sym.location.lower(), LOCATION_TERMS)
        location = locs[0] if locs else None
    severity = severity_bucket(sym.severity_0_10) if sym else None
    # Structured fallback: a rated pain in a pelvic location with no keyword match.
    if (
        sym
        and sym.severity_0_10
        and location in ("one-sided", "lower abdominal")
        and not any("pain" in t or "dysmenorrhea" in t for t in topics)
    ):
        topics.insert(0, "pelvic pain evaluation")
    for topic in topics[:2]:
        if "pain" in topic or "dysmenorrhea" in topic:
            add(topic, location, severity, age)
        else:
            add(topic, age)

    # 4. Contraception category.
    category = contraception_category(rec.contraception)
    if category or any(k in free_text for k in CONTRACEPTION_KEYWORDS):
        add("contraception counseling", category if category not in (None, "other method") else None, age)

    # 5. Cervical screening (USPSTF covers ages 21-65).
    if rec.age_band and rec.age_band != AgeBand.B65_PLUS:
        status = screening_status(rec.last_pap_hpv, today=today, overdue_after_years=3)
        suffix = {"never": "never screened", "unknown": None, "up to date": None}.get(
            status, f"last test {status}"
        )
        add("cervical cancer screening interval", age, suffix)

    # 6. Breast screening for 40+.
    if rec.age_band in _MAMMO_BANDS:
        status = screening_status(rec.last_mammogram, today=today, overdue_after_years=2)
        suffix = {"never": "never screened", "unknown": None, "up to date": None}.get(
            status, f"last mammogram {status}"
        )
        add("breast cancer screening mammography", age, suffix)

    queries = queries[:MAX_QUERIES]
    for q in queries:
        _assert_vocabulary(q)
        assert_deidentified(q)
    return queries
