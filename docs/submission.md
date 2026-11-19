# Bloom: submission kit

Deadline: **Fri 2026-11-20, 3:00 PM PT** (moved up from 5:00 PM; the earlier time no longer applies). Submit at BoatHackathon.com/builders from the regular builder sign-in (saves in preview mode don't count). Fill in every `TODO` before submitting.

Paste-ready answers and the pre-submit checklist: `docs/submission/form-answers.md`. Video runbook: `docs/submission/demo-recording-plan.md`.

## Form fields
| Field | Value |
| --- | --- |
| Boat name | Bloom |
| Participation | TODO (human): in person or remote |
| Project logo | `docs/submission/bloom-logo-1024.png` (1024×1024 PNG, 54 KB; 512 px version and SVG source in the same folder) |
| Project link | https://box-node-65cdd7262c0153ea-80.on.boat.dev/ (landing page with Patient and Doctor buttons; demo fork; the repo is private, so use the app URL) |
| Demo video link | TODO (human): YouTube (unlisted) or X, 2 minutes or less |
| X post link | TODO (human): link to post 1/ of the thread below, after posting |
| Crew | TODO (human): names and X handles of everyone on the crew |

## Captain's log (paste into the form)
Bloom is a private AI copilot for gynecology visits. A patient answers a short intake chat before the appointment. Bloom turns it into a one-page physician brief with guideline citations. The gynecologist confirms, edits or rejects every AI draft before it counts.

Three things make it different:
1. **Safety first, without the model.** Six red-flag rules (possible ectopic pregnancy, heavy bleeding, pelvic infection signs, pregnancy or postpartum warning signs, self-harm, sexual assault disclosure) are deterministic Python on the server, each with tests. When one fires, the chat stops and the patient sees urgent-care actions straight away.
2. **Private inference that fails closed.** Every model call (GLM-5.3 Flash) goes through NY Token Exchange's TrustedRouter with a privacy floor set by the server, not the browser. In private mode, if no confidential route is available, Bloom refuses and does not fall back to another model. The Privacy & Trust panel shows the route, policy, gateway receipt (Bloom does not verify its signature) and latency for every call, and a live negative test shows a refusal. The live demo runs in dev mode on a zero-data-retention route (operator-declared), not a confidential one, and the panel labels it that way.
3. **Cited, de-identified guidelines.** Context.dev searches guideline sites (ACOG, USPSTF, CDC) with queries built only from structured fields, never from what the patient typed. The brief may cite only passages that were actually retrieved.

Built on a Boat.dev VM (Flutter Web, FastAPI and LangGraph, SQLite, Docker Compose). All demo data is synthetic. Bloom is a hackathon prototype, not a medical device.

## X post (thread)
Character counts are X counts (a link counts as 23). Each post is under 280.

1/ (219) We built Bloom on the water at #boathackathon: an AI copilot for gynecology visits. Patients do a short intake chat; the gynecologist gets a cited one-page brief to confirm, edit or reject. @boathackathon @teamily_ai

2/ (199) Red flags never depend on the model: six deterministic server rules (heavy bleeding, possible ectopic pregnancy, self-harm and more) stop the chat and show urgent-care steps. Every rule has tests.

3/ (254) Every AI call (GLM-5.3 Flash) goes through @nytokenexchange TrustedRouter with a server-set privacy floor. Private mode fails closed: no fallback model. Our demo runs on a zero-data-retention route, not a confidential one, and the trust panel says so.

4/ (217) Guidelines come from @getcontextdev, searched with de-identified queries built from structured fields and an allowlist of guideline sites (ACOG, USPSTF, CDC). Built and run on a @boatdotdev VM. Synthetic data only.

5/ (103) 2-minute demo: `<video link>`
Try it (synthetic data only): `https://box-node-65cdd7262c0153ea-80.on.boat.dev/intake/`

Attach `docs/submission/bloom-logo-1024.png` (or a D02 screenshot) to post 1/.

## 2-minute video script
Click-by-click steps and on-screen captions: `docs/submission/demo-recording-plan.md`.

| Time | Screen | Say |
| --- | --- | --- |
| 0:00–0:15 | A01 → P01 | "Gynecology visits are short. Bloom lets the patient tell their story first, privately." |
| 0:15–0:45 | P02 with S1 | Run scenario S1 live: a few turns, progress bar, then P04 Done (model waits cut or sped up and labelled). |
| 0:45–1:00 | P02 with S7 → P03 | "Soaking a pad every hour and lightheaded": rule R2 fires, the chat stops, urgent actions appear. "No model decided that." |
| 1:00–1:25 | D01 → D02 | Queue with the red flag on top. Open the S1 brief: citations to USPSTF. Click Edit, change a line, Save edits. Provenance is stored. |
| 1:25–1:45 | D03 | Privacy & Trust panel: route, ZDR policy, receipt, latency per call. "Dev mode: zero data retention, not confidential, and it says so." |
| 1:45–2:00 | D05 negative test | Run the negative test: a confidential floor the route can't meet returns Refused, one call, no fallback. "If it can't be private, Bloom says no." |

Wording rules: never say "HIPAA compliant", "secure" without evidence, "encrypted" or "end-to-end encrypted" (the provider E2EE is not verified), or "data never leaves the app". The GLM-5.3 Flash route is zero-data-retention (operator-declared), not confidential; say so if asked.

## Prize checklist
- Boat.dev: running on a Boat VM; `boat fork` demo snapshot; coding-aboard photo and commit.
- NY Token Exchange / TrustedRouter: all AI calls through TrustedRouter; D03 evidence; D05 negative test.
- Context.dev: cited guideline retrieval with a domain allowlist; Monitor webhook for guideline updates (stretch).
- LetsEncrypt.AI ($1,000): GLM-5.3 Flash via TrustedRouter for every AI call; show the D05 refusal live.
- Teamily: daily status posts in the group.
