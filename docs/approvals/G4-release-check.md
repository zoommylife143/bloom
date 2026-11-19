# Gate 4: release check

- **Decision:** Approved
- **Approver:** srinivas sreepada, in chat, 2026-11-19, 12:02 PT
- **Date of check:** 2026-11-19 (submission deadline Fri 2026-11-20, 3:00 PM PT per docs/submission.md)
- **Mode:** hackathon-fast (ADR 0002). Checklist from plan §8 (privacy controls, claims policy) and §12 (submission checklist), the 30-Hour Build Plan's Friday checklist, and the CLAUDE.md rules.
- **Branch checked:** `build/scaffold` (working tree clean before this check, 13 commits in history)

## Test and analysis results
| Package | Command | Result |
| --- | --- | --- |
| server | `cd server && uv run pytest -q` | 364 passed |
| apps/patient | very_good_cli MCP `test` | 191 passed |
| apps/clinic | very_good_cli MCP `test` | 116 passed |
| packages/core_data | very_good_cli MCP `test` | 108 passed |
| packages/bloom_ui | very_good_cli MCP `test` | 35 passed |
| packages/core_domain | very_good_cli MCP `test` | 16 passed |
| packages/l10n | very_good_cli MCP `test` | 4 passed |
| **Total** | | **834 passed, 0 failed** (matches docs/STATUS.md) |
| All six Flutter packages | `flutter analyze` | No issues found (each) |

## Engineering checklist (CLAUDE.md rules, plan §8)
| Item | Result | Evidence |
| --- | --- | --- |
| Red-flag rules R1–R6 are deterministic Python on the server | PASS | `server/app/safety.py:93-205` (one block per rule), precedence `safety.py:356` |
| Every red-flag rule has a test | PASS | `server/tests/test_safety.py:113` asserts every `RedFlagRule` has ≥2 positive text cases; negatives `:109`, field rules `:151/:174`, scenarios `:324/:347`; `test_safety.py` 143 passed |
| Private mode fails closed, no fallback model | PASS | `server/app/router.py:192-205` (private uses `private_model_id`, `min_privacy="confidential"`, `allow_fallbacks: False`; no model configured raises with no call); refusals never retried `router.py:301-304, 386-395`; deterministic fallbacks never run after a refusal `server/app/graph.py:31, 547`. Tests: `test_router.py:228, 248, 260, 276`; `test_graph_api.py:218` (502 after exactly one call), `:231` (zero calls); `test_bad_model.py:189` (one model only, no repair in private mode) |
| Every AI output is a draft with Confirm / Edit / Reject | PASS | `Provenance.review_status` defaults to `"draft"` (`server/app/models.py:153`); decision endpoint `server/app/main.py:472`; D02 `DecisionBar` `apps/clinic/lib/features/brief/presentation/pages/brief_page.dart:358`; component `packages/bloom_ui/lib/src/widgets/decision_bar.dart:10`. Tests: `server/tests/test_graph_api.py:308` (approve / reject / edit, 409 on re-decide), `apps/clinic/test/features/brief/brief_page_test.dart:107-261` |
| Provenance stored | PASS | `Provenance` (generated_by, evidence_urls, source, created_at, review_status, reviewed_by, reviewed_at) `server/app/models.py:146-155`; persisted in `server/app/store.py:206-213`; fallback drafts labelled `source="fallback"` (`graph.py:513-516`) |
| Context.dev queries de-identified, from structured fields | PASS | `server/app/deidentify.py:1-15` (fixed vocabularies, patient text only matched, never copied); second check `assert_deidentified` in `server/app/retrieve.py:140` before every search. Tests: `test_deidentify.py:47` (planted name/DOB/phone/MRN/email never reach a query), `:145`, `:165` |
| No secrets committed (tree) | PASS | `git ls-files` contains only `.env.example` (all key values empty); `.gitignore:1-3` ignores `.env` / `.env.*`; `git grep` for key patterns (sk-, tr_, AKIA, ghp_, github_pat_, xox, private-key blocks, JWTs, `*_KEY/SECRET/TOKEN=` with long values) found only the synthetic `whsec_synthetic_test_secret` in `server/tests/test_monitor.py:21`. `.env` was not opened |
| No secrets committed (history) | PASS | `git log --all -p` added lines scanned with the same patterns: no hits; no `.env` file ever committed (only `.env.example`) |
| Synthetic data only | PASS | Scenarios S1–S10 in `scenarios/` are scripted personas; P01 consent "I will use made-up answers" (`packages/l10n/lib/src/arb/app_en.arb:47`), sign-in footers `:27, :184`; only PII-shaped strings are planted fakes in `server/tests/test_deidentify.py:22-25` (555 numbers, `example.test`) |
| No "HIPAA compliant" | PASS | Only negations: `README.md:7` ("Not HIPAA compliant"), the wording rule in `docs/submission.md:56`; none in `app_en.arb`, `apps/*/lib`, `packages/bloom_ui/lib`, `apps/*/web` |
| No "data never leaves (the app)" | PASS | No match in UI strings, `docs/submission.md` (except the rule itself), or README |
| No unqualified "secure" | PASS | No user-facing "secure"; only a doc comment saying the TrustRow never says it (`packages/bloom_ui/lib/src/widgets/trust_row.dart:8`). "Encrypted" appears only as qualified labels ("Provider E2EE not verified", `app_en.arb:172, 276`) |
| No "diagnoses" claim | PASS | Only negations: `app_en.arb:43` ("Bloom never diagnoses"), `:325` ("not a diagnosis") |
| Flutter analyze clean | PASS | See table above |

## Submission checklist (plan §12, 30-Hour Build Plan)
These are human steps. The code check cannot verify them; they stay open until done.

| Item | Result | Evidence |
| --- | --- | --- |
| BoatBuilder account accepted | PASS | Plan §12 checklist: boarding pass #034 |
| Boat named Bloom, captain's log, project link, logo | Open (human) | Captain's log and logo ready: `docs/submission.md` "Captain's log", `docs/submission/bloom-logo-1024.png`; project link waits on the VM URL |
| Captain's log checked against the claims policy | PASS | `docs/submission.md` captain's log: states dev mode is ZDR (operator-declared), not confidential; no forbidden phrases |
| Working app URL (Boat VM) | Open (human) | docs/STATUS.md "Waiting on srinivas": VM, `scripts/deploy.sh`, `boat host`, snapshot, fork |
| NYTE/TrustedRouter and Context.dev demonstrated | Open (human) | Live-checked in dev mode per docs/STATUS.md; needs the recorded video |
| Video ≤ 2 min uploaded and linked | Open (human) | `docs/submission.md` field "Demo video link" is TODO |
| Public X post (#boathackathon, tags) and URL in form | Open (human) | Thread drafted in `docs/submission.md`; post URL is TODO |
| Code change made aboard a boat | Open (human) | Needs photo + commit |
| Crew accepted aboard | Open (human, optional) | `docs/submission.md` "Crew" TODO |
| Submitted and accepted by Fri 3:00 PM PT | Open (human) | |
| STATUS updated, G4 recorded in docs/approvals/ | PASS (this file); STATUS owned by another agent | This file |

## Fixes made during this check
- `.env.example`: `TR_MODEL_ID` changed from `fortanix/glm-5.3-flash` to `z-ai/glm-5.3-flash`, matching the server default (`server/app/config.py:22`). The fortanix route returned 502 provider_error on 2026-11-19 (docs/STATUS.md), so a VM `.env` copied from the example would have broken every AI call. Server tests re-run after the change: 364 passed.
- `docs/sponsor-runbook.md:49`: "encrypted AI doing useful work" reworded to "privacy-floored AI calls (zero-data-retention route, operator-declared; provider E2EE not verified)", per the wording rule in `docs/submission.md:56`.

## Open issues (not blocking the code check)
1. **Deadline:** CLAUDE.md and `docs/submission.md` now agree on Fri 3:00 PM PT; plan §12 and the organizer notes in the plan still say 5:00 PM. Work to 3:00 PM.
2. **P01 dev-route wording** (`app_en.arb:39`): "Your answers go to an AI service that does not keep them (zero data retention)." states ZDR as fact; the route is operator-declared ZDR. Suggest "...that says it does not keep them (zero data retention, operator-declared)." Not changed here because it needs `gen-l10n` and test updates. **Done 2026-11-19 (session 5):** wording applied, l10n regenerated, patient tests pass (191).
3. **Plan §12 positioning paragraph** still says Bloom "uses NY Token Exchange for confidential AI inference"; the demo runs in dev mode (ZDR, not confidential). Use the captain's log in `docs/submission.md`, which is accurate, not the plan's paragraph.
4. **Private mode is not demonstrable end to end:** `PRIVATE_MODEL_ID` is empty, so private mode refuses every call (fail-closed by design). The D05 negative test is the private-AI evidence.
5. **Red-flag keyword lists and screening wording** still need clinician review before any use beyond the demo (plan §8).
6. **Branch:** checked on `build/scaffold`; docs/STATUS.md names `main` as the branch. Confirm which branch the VM deploys.
7. **Key rotation** for TrustedRouter and Context.dev after the demo (docs/STATUS.md).

## Approval
Approved by srinivas sreepada in chat, 2026-11-19, 12:02 PT ("approve now").

At approval:
- Human submission items reported done by srinivas: demo video posted, submission form submitted, X thread posted.
- Open issue 2 (P01 wording) fixed and live on both VMs (redeployed at `4727859`; smoke 27/27 and live check S1, S3, S7 PASS on each public URL).
- Open issue 6 (branch): resolved; `main` and `build/scaffold` point to the same commit, and both VMs deploy `main`.
- Still open and accepted for the hackathon: issues 3 (plan §12 paragraph; the submitted captain's log is accurate), 4 (private mode not demonstrable end to end), 5 (clinician review of keyword lists) and 7 (key rotation after the demo).
