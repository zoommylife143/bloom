"""Deterministic red-flag rules R1-R6, fixed urgent-care messages and the patient reply filter.

CLINICIAN REVIEW REQUIRED: every keyword list, threshold and message in this module is a
hackathon demo triage trigger, not clinical judgement. A licensed clinician must review and
sign off on all of them before any use beyond the synthetic-data demo.

Design choices (deliberately conservative: when in doubt, interrupt the intake):
- Text is lower-cased, apostrophes removed ("don't" -> "dont"), hyphens and slashes turned into
  spaces and split into clauses on punctuation and on "and", "but", "though", "although",
  "however", "except".
- A keyword is ignored when a negator (NEGATORS) appears up to NEGATION_WINDOW words before it
  in the same clause ("no fever", "not dizzy", "never had thoughts of hurting myself").
  "can't", "cannot" and "without" are NOT negators, so "I can't stop thinking about killing
  myself" and "I can't stand up without feeling dizzy" still fire. Hedges such as "not sure"
  and "don't know" are treated as uncertainty, never as negation.
- For R1-R4 a keyword is ignored when its clause clearly refers to the distant past
  (PAST_MARKERS: "last year", "years ago", "used to"...). R5 and R6 ignore PAST_MARKERS:
  any self-harm or assault disclosure interrupts.
- R1: an unknown pregnancy status (None) counts as "not no", as the plan's rule literally says.
  Severe pain anywhere counts (location is not required). Text pregnancy cues ("missed period",
  "might be pregnant") override a recorded "no".
- R2: a "heavy" bleeding_pattern on its own does not fire (routine heavy periods, scenario S4);
  it fires together with dizziness/fainting.
- R4: needs pregnancy/postpartum evidence (context field, pregnancy_possible == "yes", or a
  text cue). A "mild headache that went away" does not fire: only severe-headache phrasings
  count. Any vision change, chest pain, shortness of breath or seizure fires regardless of
  severity or whether it has passed.
- Precedence when several rules match: R5 (988 first), R6, then R2, R1, R3, R4 (R2 before R1
  because dizziness alone can satisfy R1; both show the same P03 screen).
- RedFlagHit.matched holds only the constant keywords from this module or field names, never
  the patient's words.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field

from app.models import BleedingPattern, IntakeRecord, RedFlagHit, RedFlagRule

# ---------------------------------------------------------------------------
# Normalization vocabulary
# ---------------------------------------------------------------------------

NEGATORS: frozenset[str] = frozenset(
    {
        "no", "not", "never", "none", "nor", "neither", "denies", "deny", "denied",
        "dont", "didnt", "doesnt", "havent", "hasnt", "hadnt", "isnt", "arent", "wasnt",
        "werent", "wont", "nothing",
    }
)
NEGATION_WINDOW = 5  # words before a keyword that are checked for a negator

# Phrases that mean "uncertain", rewritten to "unsure" so they never act as a negation.
HEDGES: tuple[str, ...] = ("not sure", "dont know", "not certain", "no idea")

# A clause containing one of these is about the distant past (ignored for R1-R4 only).
PAST_MARKERS: tuple[str, ...] = (
    "last year", "years ago", "year ago", "months ago", "month ago", "a long time ago",
    "long ago", "as a kid", "as a child", "as a teen", "when i was younger", "in high school",
    "in college", "in the past", "used to", "back in",
)

CLAUSE_SPLIT_WORDS: tuple[str, ...] = ("and", "but", "though", "although", "however", "except")

# ---------------------------------------------------------------------------
# Shared symptom vocabularies
# ---------------------------------------------------------------------------

PAIN_WORDS: tuple[str, ...] = (
    "pain", "pains", "painful", "hurts", "hurt", "hurting", "ache", "aches", "aching", "achy",
    "cramp", "cramps", "cramping", "stabbing", "sore", "tender",
)

DIZZY_FAINT_PHRASES: tuple[str, ...] = (
    "dizzy", "dizziness", "lightheaded", "light headed", "lightheadedness", "faint", "fainted",
    "fainting", "feel faint", "passed out", "pass out", "passing out", "blacked out",
    "black out", "blacking out", "syncope", "room is spinning", "room spinning",
)

PREGNANCY_TEXT_CUES: tuple[str, ...] = (
    "pregnant", "pregnancy", "missed period", "missed my period", "period is late",
    "late period", "period late", "positive test", "positive pregnancy test", "expecting",
)

POSTPARTUM_TEXT_CUES: tuple[str, ...] = (
    "postpartum", "post partum", "gave birth", "had a baby", "had my baby", "just delivered",
    "delivered my baby", "c section", "since delivery", "after delivery", "after giving birth",
    "newborn",
)

# ---------------------------------------------------------------------------
# R1 Possible ectopic
# ---------------------------------------------------------------------------

R1_ONE_SIDED_MARKERS: tuple[str, ...] = (
    "one side", "one sided", "left side", "right side", "left sided", "right sided",
    "on my left", "on my right", "on the left", "on the right", "lower left", "lower right",
    "left lower", "right lower", "left ovary", "right ovary",
)

R1_SEVERE_PAIN_PHRASES: tuple[str, ...] = (
    "severe pain", "severe cramps", "severe cramping", "worst pain", "really bad pain",
    "very bad pain", "terrible pain", "horrible pain", "excruciating", "unbearable",
    "agonizing", "sharp pain", "stabbing pain", "doubled over", "cant stand up",
    "cant walk", "pain is severe", "pain is really bad", "pain is unbearable",
)
# "7 out of 10" .. "10 out of 10" (after normalization "8/10" becomes "8 out of 10").
R1_SEVERE_PAIN_SCORE = re.compile(r"\b([7-9]|10) (out of|outta|on a scale of|over) 10\b")
R1_SEVERE_PAIN_SCORE_LABEL = "pain score 7+ out of 10"
SEVERE_PAIN_SEVERITY_MIN = 7  # IntakeRecord.symptom.severity_0_10 at or above this is severe

# ---------------------------------------------------------------------------
# R2 Heavy bleeding
# ---------------------------------------------------------------------------

R2_SOAKING_PHRASES: tuple[str, ...] = (
    "soaking a pad", "soaking through a pad", "soaking a tampon", "soaking through a tampon",
    "soaking through", "soaked through", "soak through", "soaking pads", "soaking my pad",
    "soaking my clothes", "soaking the bed", "bleeding through", "gushing", "hemorrhaging",
)
# A pad/tampon/cup in the same clause as a one-hour-or-less interval.
R2_HOURLY_PAD = re.compile(
    r"\b(pad|pads|tampon|tampons|cup)\b.*\b("
    r"(every|each|per|an|a|one|1|half|half an|within an|within the|less than an|under an) (hour|hr)"
    r"|hourly|(15|20|30|45|thirty|twenty|fifteen|forty five) (min|mins|minutes))\b"
    r"|\b(every|each|per|an|a|one|1|half an|within an|less than an|under an) (hour|hr)\b.*"
    r"\b(pad|pads|tampon|tampons|cup)\b"
)
R2_HOURLY_PAD_LABEL = "pad or tampon in an hour or less"
R2_CLOT_WORDS: tuple[str, ...] = ("clot", "clots", "clotting")
R2_LARGE_CLOT_SIZES: tuple[str, ...] = (
    "golf ball", "golfball", "quarter", "large", "big", "huge", "bigger", "larger", "massive",
    "lemon", "plum", "egg", "fist", "palm",
)
R2_BLEEDING_WORDS: tuple[str, ...] = (
    "bleeding", "bleed", "bleeds", "blood", "hemorrhage", "hemorrhaging", "heavy period",
    "heavy periods", "heavy flow",
)

# ---------------------------------------------------------------------------
# R3 Pelvic infection signs
# ---------------------------------------------------------------------------

R3_FEVER_PHRASES: tuple[str, ...] = (
    "fever", "fevers", "feverish", "febrile", "high temperature", "running a temperature",
    "running a temp", "temperature is high", "chills and fever", "fever and chills",
)
# 100.4 F and up / 38 C and up (decimals are dropped during normalization).
R3_FEVER_READING = re.compile(
    r"\b(10[0-5]) (degrees|f|fahrenheit)\b|\b(3[89]|4[0-1]) (degrees|c|celsius)\b"
    r"|\b(temp|temperature) (of |is |was )?(10[0-5]|3[89]|4[01])\b"
)
R3_FEVER_READING_LABEL = "temperature 100.4F or 38C and up"
R3_PELVIC_PAIN_PHRASES: tuple[str, ...] = (
    "pelvic pain", "pain in my pelvis", "cramps", "cramping", "lower belly pain",
    "lower abdominal pain", "lower stomach pain", "pain down there",
)
PELVIC_LOCATION_WORDS: tuple[str, ...] = (
    "pelvis", "pelvic", "lower belly", "lower abdomen", "lower abdominal", "lower stomach",
    "belly", "abdomen", "abdominal", "stomach", "tummy", "uterus", "womb", "ovary", "ovaries",
    "down there", "vagina", "vaginal", "groin",
)

# ---------------------------------------------------------------------------
# R4 Pregnancy / postpartum warning signs
# ---------------------------------------------------------------------------

R4_SEVERE_HEADACHE_PHRASES: tuple[str, ...] = (
    "severe headache", "bad headache", "really bad headache", "worst headache",
    "terrible headache", "horrible headache", "pounding headache", "splitting headache",
    "headache that wont go away", "headache wont go away", "headache is severe",
    "headache is really bad", "constant headache",
)
R4_VISION_PHRASES: tuple[str, ...] = (
    "vision changes", "vision change", "changes in my vision", "blurry vision",
    "blurred vision", "vision is blurry", "seeing spots", "seeing stars", "flashing lights",
    "spots in my vision", "double vision", "lost my vision", "cant see", "trouble seeing",
)
R4_CHEST_PHRASES: tuple[str, ...] = (
    "chest pain", "chest hurts", "pain in my chest", "chest tightness", "tight chest",
    "chest pressure", "pressure in my chest",
)
R4_BREATH_PHRASES: tuple[str, ...] = (
    "shortness of breath", "short of breath", "cant breathe", "cant catch my breath",
    "trouble breathing", "hard to breathe", "difficulty breathing", "struggling to breathe",
    "out of breath",
)
R4_SEIZURE_PHRASES: tuple[str, ...] = ("seizure", "seizures", "seizing", "convulsion", "convulsions")

# ---------------------------------------------------------------------------
# R5 Self-harm (precedence over every other rule)
# ---------------------------------------------------------------------------

R5_SELF_HARM_PHRASES: tuple[str, ...] = (
    "kill myself", "killing myself", "end my life", "ending my life", "end it all",
    "take my own life", "taking my own life", "suicide", "suicidal", "hurt myself",
    "hurting myself", "harm myself", "harming myself", "self harm", "cut myself",
    "cutting myself", "want to die", "wanna die", "wish i was dead", "wish i were dead",
    "better off dead", "dont want to live", "dont want to be alive", "dont want to be here anymore",
    "no reason to live", "nothing to live for", "not worth living", "dont want to wake up",
)

# ---------------------------------------------------------------------------
# R6 Sexual assault disclosure
# ---------------------------------------------------------------------------

R6_ASSAULT_PHRASES: tuple[str, ...] = (
    "rape", "raped", "sexual assault", "sexually assaulted", "assaulted", "assault",
    "forced me", "forced sex", "forced to have sex", "made me have sex", "against my will",
    "didnt consent", "did not consent", "without my consent", "sexually abused", "molested",
)

# ---------------------------------------------------------------------------
# Patient reply filter (no diagnosis reaches a patient)
# ---------------------------------------------------------------------------

_YOU_HAVE_SAFE_NEXT = r"(?! (been|shared|told|mentioned|said|described|answered|any|had|done|given|questions)\b)"
DIAGNOSIS_PATTERNS: tuple[str, ...] = (
    # "you have X" as a statement; questions like "do you have" or "how long have you had" pass.
    r"(?<!do )(?<!did )(?<!if )(?<!when )(?<!long )(?<!since )(?<!what )(?<!whether )"
    r"(?<!many )(?<!could )(?<!would )\byou have\b" + _YOU_HAVE_SAFE_NEXT,
    r"\byouve got\b",
    r"\byou (might|may|could|probably|likely|most likely) have\b" + _YOU_HAVE_SAFE_NEXT,
    r"\bsounds like you (have|might|may|could)\b",
    r"\bsounds like (it is|its|it could be|it might be|this is|this could be)\b",
    r"\bdiagnos(is|es|ed|e|ing)\b",
    r"\b(this|that|it) is (likely|probably|most likely)\b",
    r"\b(this|that|it)s (likely|probably)\b",
    r"\bmost likely\b",
    r"\bconsistent with\b",
    r"\bsuggestive of\b",
    r"\b(could|may|might|is) be a sign of\b",
    r"\bis a sign of\b",
    r"\byou are suffering from\b",
    r"\byoure suffering from\b",
)
NAMED_CONDITIONS: tuple[str, ...] = (
    "endometriosis", "adenomyosis", "pcos", "polycystic ovary", "polycystic ovarian",
    "ectopic", "ectopic pregnancy", "molar pregnancy", "miscarriage", "miscarrying",
    "pregnancy loss", "cancer", "tumor", "tumour", "malignancy", "chlamydia", "gonorrhea",
    "syphilis", "herpes", "trichomoniasis", "genital warts", "pelvic inflammatory disease",
    "pid", "bacterial vaginosis", "yeast infection", "urinary tract infection", "uti",
    "fibroid", "fibroids", "ovarian cyst", "ovarian torsion", "torsion", "preeclampsia",
    "pre eclampsia", "eclampsia", "anemia", "anaemia", "sepsis", "infertility",
)
# Deliberately NOT listed: "hpv", "sti", "std", "pap" (used in normal screening questions).
# Removed before the named-condition check so screening questions are not filtered.
FILTER_ALLOWED_PHRASES: tuple[str, ...] = ("cancer screening", "screening for cancer", "history of cancer")

NEXT_QUESTION_PLACEHOLDER = "{next_question}"
SAFE_PATIENT_REPLY = (
    "Thank you for sharing that. Your care team will look at everything you tell me. "
    + NEXT_QUESTION_PLACEHOLDER
)

# ---------------------------------------------------------------------------
# Urgent-care messages (screen P03)
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class UrgentAction:
    label: str
    tel: str


@dataclass(frozen=True)
class UrgentMessage:
    title: str
    body: str
    actions: tuple[UrgentAction, ...]
    support: str | None = None  # extra care-and-support line (R6)
    stop_questions: bool = field(default=True)  # the intake asks nothing more after this


CALL_911 = UrgentAction(label="Call 911", tel="tel:911")
CALL_988 = UrgentAction(label="Call or text 988", tel="tel:988")
CALL_RAINN = UrgentAction(label="National Sexual Assault Hotline", tel="tel:18006564673")

_GET_CARE_NOW = (
    "Please call 911 or go to the nearest emergency room now. "
    "If you can, ask someone to stay with you. "
    "We will stop the questions here so you can get help."
)

URGENT_MESSAGES: dict[RedFlagRule, UrgentMessage] = {
    RedFlagRule.R1: UrgentMessage(
        title="Please get care now",
        body=(
            "Thank you for telling me. Pain like this, or feeling dizzy or faint, "
            "when there is a chance of pregnancy needs to be checked by a doctor right away. "
            + _GET_CARE_NOW
        ),
        actions=(CALL_911, CALL_988),
    ),
    RedFlagRule.R2: UrgentMessage(
        title="Please get care now",
        body=(
            "Thank you for telling me. Bleeding this heavy, or bleeding with feeling dizzy "
            "or faint, needs to be checked by a doctor right away. "
            "If you feel faint, sit or lie down. " + _GET_CARE_NOW
        ),
        actions=(CALL_911, CALL_988),
    ),
    RedFlagRule.R3: UrgentMessage(
        title="Please get care today",
        body=(
            "Thank you for telling me. A fever together with pain low in your belly "
            "needs to be checked by a doctor soon. " + _GET_CARE_NOW
        ),
        actions=(CALL_911, CALL_988),
    ),
    RedFlagRule.R4: UrgentMessage(
        title="Please get care now",
        body=(
            "Thank you for telling me. During pregnancy or after having a baby, "
            "what you described needs to be checked by a doctor right away. "
            "Tell them you are pregnant or recently gave birth. " + _GET_CARE_NOW
        ),
        actions=(CALL_911, CALL_988),
    ),
    RedFlagRule.R5: UrgentMessage(
        title="You are not alone",
        body=(
            "Thank you for telling me. That took courage. You deserve support right now. "
            "You can call or text 988 any time, day or night, to talk with someone who cares. "
            "If you might act on these thoughts or are in danger, call 911 now. "
            "We will stop the questions here."
        ),
        actions=(CALL_988, CALL_911),
    ),
    RedFlagRule.R6: UrgentMessage(
        title="We are here for you",
        body=(
            "Thank you for telling me. What happened is not your fault. "
            "If you are in danger or hurt, call 911 now. "
            "No more questions will be asked."
        ),
        actions=(CALL_911, CALL_RAINN, CALL_988),
        support=(
            "You can talk with someone at the National Sexual Assault Hotline any time. "
            "It is free and private, and you choose what to share. "
            "A doctor or nurse can also care for you, whenever you are ready."
        ),
    ),
}

# ---------------------------------------------------------------------------
# Implementation
# ---------------------------------------------------------------------------

# R2 before R1: dizziness alone can satisfy R1 when pregnancy status is unknown, so explicit
# heavy-bleeding evidence (scenario S7) is reported as R2. Both lead to the same P03 screen.
_PRECEDENCE: tuple[RedFlagRule, ...] = (
    RedFlagRule.R5, RedFlagRule.R6, RedFlagRule.R2, RedFlagRule.R1, RedFlagRule.R3, RedFlagRule.R4,
)

_CLAUSE_SPLIT_RE = re.compile(r"[.,;:!?()\[\]\n]+|\b(?:" + "|".join(CLAUSE_SPLIT_WORDS) + r")\b")


def _normalize(text: str) -> str:
    t = text.lower()
    t = t.replace("’", "'").replace("‘", "'").replace("`", "'")
    t = t.replace("'", "")
    t = re.sub(r"(\d+)\.\d+", r"\1", t)  # 100.4 -> 100 (before "." splits clauses)
    t = re.sub(r"(\d+)\s*/\s*10\b", r"\1 out of 10", t)
    t = re.sub(r"[-/_\"*]", " ", t)
    for hedge in HEDGES:
        t = t.replace(hedge, "unsure")
    t = t.replace("cannot", "cant")
    return t


def _clauses(text: str) -> list[str]:
    parts = _CLAUSE_SPLIT_RE.split(_normalize(text))
    return [" ".join(p.split()) for p in parts if p and p.strip()]


_PATTERN_CACHE: dict[str, re.Pattern[str]] = {}


def _phrase_re(phrase: str) -> re.Pattern[str]:
    pat = _PATTERN_CACHE.get(phrase)
    if pat is None:
        pat = re.compile(r"\b" + re.escape(phrase) + r"\b")
        _PATTERN_CACHE[phrase] = pat
    return pat


def _negated(clause: str, start: int) -> bool:
    prefix = clause[:start].split()[-NEGATION_WINDOW:]
    return any(tok in NEGATORS for tok in prefix)


def _is_past(clause: str) -> bool:
    return any(_phrase_re(m).search(clause) for m in PAST_MARKERS)


def _clause_hits(clause: str, phrases: tuple[str, ...], *, allow_past: bool) -> list[str]:
    if not allow_past and _is_past(clause):
        return []
    hits = []
    for phrase in phrases:
        for m in _phrase_re(phrase).finditer(clause):
            if not _negated(clause, m.start()):
                hits.append(phrase)
                break
    return hits


def _find(clauses: list[str], phrases: tuple[str, ...], *, allow_past: bool = False) -> list[str]:
    found: list[str] = []
    for clause in clauses:
        for hit in _clause_hits(clause, phrases, allow_past=allow_past):
            if hit not in found:
                found.append(hit)
    return found


def _find_regex(clauses: list[str], pattern: re.Pattern[str], label: str) -> list[str]:
    for clause in clauses:
        if _is_past(clause):
            continue
        for m in pattern.finditer(clause):
            if not _negated(clause, m.start()):
                return [label]
    return []


def _find_pair(
    clauses: list[str], first: tuple[str, ...], second: tuple[str, ...]
) -> list[str]:
    """Both a phrase from `first` and one from `second` in the same clause, neither negated."""
    for clause in clauses:
        a = _clause_hits(clause, first, allow_past=False)
        b = _clause_hits(clause, second, allow_past=False)
        if a and b:
            return [a[0], b[0]]
    return []


@dataclass
class _Signals:
    """Each attribute lists the constant keywords / field names that produced it."""

    pregnancy_possible: list[str] = field(default_factory=list)
    pregnant_or_postpartum: list[str] = field(default_factory=list)
    one_sided_pain: list[str] = field(default_factory=list)
    severe_pain: list[str] = field(default_factory=list)
    dizzy_faint: list[str] = field(default_factory=list)
    soaking: list[str] = field(default_factory=list)
    large_clots: list[str] = field(default_factory=list)
    bleeding: list[str] = field(default_factory=list)
    fever: list[str] = field(default_factory=list)
    pelvic_pain: list[str] = field(default_factory=list)
    r4_warning: list[str] = field(default_factory=list)
    self_harm: list[str] = field(default_factory=list)
    assault: list[str] = field(default_factory=list)


def _text_signals(text: str) -> _Signals:
    c = _clauses(text)
    s = _Signals()
    s.pregnancy_possible = _find(c, PREGNANCY_TEXT_CUES)
    s.pregnant_or_postpartum = _find(c, PREGNANCY_TEXT_CUES + POSTPARTUM_TEXT_CUES)
    s.one_sided_pain = _find_pair(c, R1_ONE_SIDED_MARKERS, PAIN_WORDS)
    s.severe_pain = _find(c, R1_SEVERE_PAIN_PHRASES) + _find_regex(
        c, R1_SEVERE_PAIN_SCORE, R1_SEVERE_PAIN_SCORE_LABEL
    )
    s.dizzy_faint = _find(c, DIZZY_FAINT_PHRASES)
    s.soaking = _find(c, R2_SOAKING_PHRASES) + _find_regex(c, R2_HOURLY_PAD, R2_HOURLY_PAD_LABEL)
    s.large_clots = _find_pair(c, R2_CLOT_WORDS, R2_LARGE_CLOT_SIZES)
    s.bleeding = _find(c, R2_BLEEDING_WORDS)
    s.fever = _find(c, R3_FEVER_PHRASES) + _find_regex(c, R3_FEVER_READING, R3_FEVER_READING_LABEL)
    s.pelvic_pain = _find(c, R3_PELVIC_PAIN_PHRASES) or _find_pair(c, PELVIC_LOCATION_WORDS, PAIN_WORDS)
    s.r4_warning = (
        _find(c, R4_SEVERE_HEADACHE_PHRASES)
        + _find(c, R4_VISION_PHRASES)
        + _find(c, R4_CHEST_PHRASES)
        + _find(c, R4_BREATH_PHRASES)
        + _find(c, R4_SEIZURE_PHRASES)
    )
    s.self_harm = _find(c, R5_SELF_HARM_PHRASES, allow_past=True)
    s.assault = _find(c, R6_ASSAULT_PHRASES, allow_past=True)
    return s


def _field_signals(rec: IntakeRecord | None) -> _Signals:
    s = _Signals()
    if rec is None:
        return s
    sym = rec.symptom
    if sym is not None:
        if sym.severity_0_10 is not None and sym.severity_0_10 >= SEVERE_PAIN_SEVERITY_MIN:
            s.severe_pain = ["symptom.severity_0_10"]
        if sym.location:
            loc = _clauses(sym.location)
            if _find(loc, R1_ONE_SIDED_MARKERS):
                s.one_sided_pain = ["symptom.location"]
            if _find(loc, PELVIC_LOCATION_WORDS):
                s.pelvic_pain = ["symptom.location"]
    if rec.pregnant_or_postpartum in ("pregnant", "postpartum"):
        s.pregnant_or_postpartum = ["pregnant_or_postpartum"]
    elif rec.pregnancy_possible == "yes":
        s.pregnant_or_postpartum = ["pregnancy_possible"]
    if rec.bleeding_pattern == BleedingPattern.HEAVY:
        s.bleeding = ["bleeding_pattern"]
    return s


def _pregnancy_not_ruled_out(rec: IntakeRecord | None, text_cues: list[str]) -> list[str]:
    """R1 premise: pregnancy_possible != "no" (unknown counts). Text cues override a "no"."""
    if text_cues:
        return text_cues
    if rec is not None and rec.pregnant_or_postpartum == "pregnant":
        return ["pregnant_or_postpartum"]
    if rec is None or rec.pregnancy_possible != "no":
        return ["pregnancy_possible"]
    return []


def _merge(a: list[str], b: list[str]) -> list[str]:
    return a + [x for x in b if x not in a]


def _evaluate(text_sig: _Signals, field_sig: _Signals, rec: IntakeRecord | None, *, require_text: bool):
    """Return (rule, matched) for the highest-precedence rule that fires, else None.

    With require_text, a rule fires only if at least one of its parts came from the text.
    """
    results: dict[RedFlagRule, list[str]] = {}

    def fire(rule: RedFlagRule, text_parts: list[str], field_parts: list[str]) -> None:
        if require_text and not text_parts:
            return
        results.setdefault(rule, _merge(text_parts, field_parts))

    t, f = text_sig, field_sig

    if t.self_harm:
        fire(RedFlagRule.R5, t.self_harm, [])
    if t.assault:
        fire(RedFlagRule.R6, t.assault, [])

    # R1
    preg = _pregnancy_not_ruled_out(rec, t.pregnancy_possible)
    if preg:
        for t_part, f_part in (
            (t.one_sided_pain, f.one_sided_pain),
            (t.severe_pain, f.severe_pain),
            (t.dizzy_faint, []),
        ):
            if t_part or f_part:
                text_preg = [p for p in preg if p in t.pregnancy_possible]
                field_preg = [p for p in preg if p not in t.pregnancy_possible]
                fire(RedFlagRule.R1, _merge(t_part, text_preg), _merge(f_part, field_preg))
                if RedFlagRule.R1 in results:
                    break

    # R2
    if t.soaking:
        fire(RedFlagRule.R2, t.soaking, [])
    elif t.large_clots:
        fire(RedFlagRule.R2, t.large_clots, [])
    elif t.dizzy_faint and (t.bleeding or f.bleeding):
        fire(RedFlagRule.R2, _merge(t.dizzy_faint, t.bleeding), f.bleeding if not t.bleeding else [])

    # R3
    if t.fever and (t.pelvic_pain or f.pelvic_pain):
        fire(RedFlagRule.R3, _merge(t.fever, t.pelvic_pain), f.pelvic_pain if not t.pelvic_pain else [])

    # R4
    status_t, status_f = t.pregnant_or_postpartum, f.pregnant_or_postpartum
    if t.r4_warning and (status_t or status_f):
        fire(RedFlagRule.R4, _merge(t.r4_warning, status_t), status_f if not status_t else [])

    for rule in _PRECEDENCE:
        if rule in results:
            return rule, results[rule]
    return None


def check_text(text: str, context: IntakeRecord | None = None) -> RedFlagHit | None:
    """Check one patient message (safety_pre). Fields in `context` complete multi-part rules,
    but at least one part of the rule must come from this message."""
    if not text or not text.strip():
        return None
    res = _evaluate(_text_signals(text), _field_signals(context), context, require_text=True)
    if res is None:
        return None
    rule, matched = res
    return RedFlagHit(rule_id=rule, matched=matched, source="text")


def _free_text_fields(rec: IntakeRecord) -> str:
    parts: list[str | None] = [rec.reason_for_visit, rec.other_notes]
    if rec.symptom is not None:
        parts += [rec.symptom.onset, rec.symptom.duration, rec.symptom.location, rec.symptom.triggers]
    if rec.sti_concerns and rec.sti_concerns != "declined":
        parts.append(rec.sti_concerns)
    # "." keeps each field in its own clause.
    return ". ".join(p for p in parts if p)


def check_fields(rec: IntakeRecord) -> RedFlagHit | None:
    """Check the extracted IntakeRecord (safety_post): structured fields plus its free-text fields."""
    res = _evaluate(_text_signals(_free_text_fields(rec)), _field_signals(rec), rec, require_text=False)
    if res is None:
        return None
    rule, matched = res
    return RedFlagHit(rule_id=rule, matched=matched, source="fields")


# ---------------------------------------------------------------------------
# Patient reply filter
# ---------------------------------------------------------------------------

_DIAGNOSIS_RES: tuple[re.Pattern[str], ...] = tuple(re.compile(p) for p in DIAGNOSIS_PATTERNS)


def _filter_normalize(text: str) -> str:
    t = text.lower().replace("’", "'").replace("‘", "'").replace("'", "")
    t = re.sub(r"[^a-z0-9]+", " ", t)
    return " " + " ".join(t.split()) + " "


def contains_diagnosis_language(text: str) -> bool:
    t = _filter_normalize(text)
    if any(p.search(t) for p in _DIAGNOSIS_RES):
        return True
    for allowed in FILTER_ALLOWED_PHRASES:
        t = t.replace(" " + allowed + " ", " ")
    return any(_phrase_re(c).search(t) for c in NAMED_CONDITIONS)


def filter_patient_reply(text: str, next_question: str = NEXT_QUESTION_PLACEHOLDER) -> tuple[str, bool]:
    """Return (reply, filtered). A reply with diagnosis language is replaced by a neutral
    acknowledgement followed by `next_question` (default: the literal placeholder)."""
    if contains_diagnosis_language(text):
        return SAFE_PATIENT_REPLY.replace(NEXT_QUESTION_PLACEHOLDER, next_question), True
    return text, False
