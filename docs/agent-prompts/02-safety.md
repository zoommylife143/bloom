# Agent 02: red-flag rules and patient output filter (build step 5)

## Goal
Build `server/app/safety.py`: deterministic Python red-flag rules R1–R6 that interrupt the intake, the fixed urgent-care messages, and a filter that stops any diagnosis reaching a patient. Every rule has a positive and a negative test. These are hackathon triage triggers, not clinical judgement; keep them conservative (prefer interrupting).

## Read first
- `CLAUDE.md`, `docs/agent-prompts/README.md`
- `server/app/models.py`: IntakeRecord, RedFlagRule, RedFlagHit

## Rules (plan §8)
| Rule | Trigger | Urgent screen |
| --- | --- | --- |
| R1 Possible ectopic | pregnancy_possible != "no" AND (one-sided or severe pelvic/lower-abdominal pain OR dizziness/fainting) | P03 |
| R2 Heavy bleeding | soaking a pad or tampon in an hour or less, clots larger than a quarter/golf ball, or bleeding with fainting/dizziness | P03 |
| R3 Pelvic infection signs | fever AND pelvic pain | P03 |
| R4 Pregnancy/postpartum warning | pregnant or postpartum AND (severe headache, vision changes, chest pain, shortness of breath, seizure) | P03 |
| R5 Self-harm | thoughts of self-harm or suicide, wanting to die | P03, 988 shown first |
| R6 Sexual assault disclosure | recent assault, rape, forced sex | P03 with care-and-support message, no further questions |

## Build
1. `check_text(text: str, context: IntakeRecord | None = None) -> RedFlagHit | None`, used by safety_pre on each patient message. Normalize case, punctuation and common contractions; handle simple negation ("no fever", "not dizzy", "never had thoughts of hurting myself") so negatives don't fire. Combine the message with the structured context for multi-part rules (for example R1 uses `context.pregnancy_possible`, R4 uses `context.pregnant_or_postpartum`). If R5 and another rule both match, return R5 (988 first).
2. `check_fields(rec: IntakeRecord) -> RedFlagHit | None`, used by safety_post on extracted fields.
3. `RedFlagHit.matched` holds rule keywords or field names only, never the patient's sentence.
4. `URGENT_MESSAGES: dict[RedFlagRule, UrgentMessage]` where `UrgentMessage` is a small dataclass with `title`, `body`, `actions` (ordered list of `{label, tel}`: "Call 911" `tel:911`, "Call or text 988" `tel:988`). Warm, plain, 6th-grade reading level, no diagnosis, no certainty. R5 lists 988 first. R6 adds a care-and-support line and RAINN `tel:18006564673` ("National Sexual Assault Hotline"), and says no more questions will be asked.
5. `filter_patient_reply(text: str) -> str`: if the model's patient-facing reply contains diagnosis language ("you have", "you might have", "diagnosis", "it sounds like you have", "this is likely", named conditions such as endometriosis, PCOS, ectopic pregnancy, cancer, STI names, "miscarriage"), replace it with a safe neutral acknowledgement plus the next question placeholder, and return a flag that it was filtered. Signature: `-> tuple[str, bool]`.
6. Keep all keyword lists as module-level constants so a clinician can review them in one place. Put a module docstring stating they need clinician review before any use beyond the demo.

## Tests (`server/tests/test_safety.py`)
- R1–R6: at least two positive phrasings each, from text, and from fields where the rule uses fields.
- At least one look-alike negative per rule (for example "I had a fever last year, no pain now", "my period pad lasts all day", "postpartum, mild headache that went away" is still conservative: decide and document).
- Precedence: R5 wins over other matches.
- `matched` never contains the input sentence.
- Filter: 8+ diagnosis phrasings are filtered; 5+ normal questions and acknowledgements pass unchanged.
- Parametrize the scenario messages from `scenarios/S6–S10.json` if they exist when you run; otherwise inline equivalent synthetic messages.

## Done when
`cd server && uv run pytest -q` passes. Report per the README format, including the full keyword lists so the orchestrator can review them.
