# Agent 03: de-identification, guideline retrieval and scenarios (build steps 4 and 8)

## Goal
Build `server/app/deidentify.py` (guideline queries from structured fields only), `server/app/retrieve.py` (Context.dev search restricted to guideline domains, with a per-query cache) and the ten synthetic scenarios in `scenarios/`.

## Read first
- `CLAUDE.md`, `docs/agent-prompts/README.md`, `docs/sponsor-runbook.md` §3
- `server/app/models.py`: IntakeRecord, EvidenceItem
- `server/app/config.py`: `context_dev_api_key`, `guideline_domain_list`
- Context.dev API: find its search endpoint, auth header and domain-filter syntax from the official docs (start at https://context.dev and its docs or API reference). Record the exact endpoint and parameters you used in the module docstring. If you can't confirm the domain filter, also filter results by URL host after the call.

## Build
1. `deidentify.py`
   - `build_queries(rec: IntakeRecord) -> list[str]`: queries from structured fields only: age band, bleeding pattern, symptom location/severity bucket, pregnancy/postpartum status, last Pap/HPV and mammogram status ("overdue", "never", "unknown" from the year), contraception category. Example: "cervical cancer screening interval age 30-39 last test over 3 years". At most 4 queries.
   - Never use `other_notes`, `reason_for_visit` free text, medications or allergies verbatim. Map free text only through fixed vocabularies (for example a symptom keyword list) so nothing typed by the patient passes through.
   - `assert_deidentified(query: str) -> None`: raises if the query contains anything that looks like a name, a date, a phone number, an email, a street address or a long number. Call it on every query before returning.
2. `retrieve.py`
   - `class GuidelineRetriever(settings, http: httpx.Client | None = None, cache_dir: Path | None = None)`
   - `search(query: str, *, max_results: int = 3) -> list[EvidenceItem]`: calls `assert_deidentified`, calls Context.dev, keeps only results whose host is in `guideline_domain_list` (exact host or subdomain), returns passage + URL + title.
   - Cache: JSON files under `cache_dir` keyed by a hash of the query, so demos and tests spend no credits. `search` reads the cache first.
   - No key or an API error: return `[]` and let the brief say "No guideline retrieved". Never raise into the graph.
   - Also return a TrustEvent-style metadata dict per call (`node="retrieve"`, latency, outcome, request ID if returned), without the passage text.
3. `scenarios/S1.json` … `S10.json`, exactly as plan §11:
   S1 34 overdue cervical screening, mild cycle irregularity · S2 52 postmenopausal spotting · S3 27 painful periods, contraception question · S4 45 heavy regular periods, fatigue, no syncope · S5 30 declines sexual-health questions · S6 29 missed period + one-sided pain + dizziness → R1 · S7 38 soaking a pad per hour + lightheaded → R2 · S8 24 fever + pelvic pain → R3 · S9 33, two weeks postpartum, severe headache + vision changes → R4 · S10 41 mentions thoughts of self-harm mid-intake → R5.
   Schema: `{"id", "summary", "age_band", "turns": ["patient message", ...], "expected": {"outcome": "brief" | "urgent", "rule_id"?: "R1", "brief_must_include"?: [...], "max_turns": 12}, "expected_fields"?: {partial IntakeRecord}}`. Patient turns are plain first-person answers. No names, dates of birth or real identifiers; use relative times ("about 6 weeks ago").
4. `scenarios/evidence-cache/`: if you can reach Context.dev with a key available through the environment (don't read `.env`; if `CONTEXT_DEV_API_KEY` isn't set, skip), prefill the cache for the S1–S5 queries. Otherwise create two clearly marked fixture files (`"fixture": true`) from real public pages you fetched on acog.org, uspreventiveservicestaskforce.org or cdc.gov, with exact URLs and short quoted passages.

## Tests (`server/tests/test_deidentify.py`, `test_retrieve.py`, `test_scenarios.py`)
- Planted-identifier test (F9): an IntakeRecord whose `other_notes` and `reason_for_visit` contain a fake name, DOB, phone and email; none of them appear in any query.
- `assert_deidentified` rejects each identifier type and accepts normal guideline queries.
- Domain filter drops a non-allowlisted URL; subdomains of allowlisted hosts are kept.
- Cache hit makes zero HTTP calls (respx).
- API failure returns `[]`.
- All 10 scenarios load and validate; S6–S10 have the right `rule_id`; S1–S5 expect a brief.

## Done when
`cd server && uv run pytest -q` passes. Report per the README format, including the Context.dev endpoint and filter syntax you confirmed.
