# Bloom: submission kit (draft)

Deadline: Fri 2026-11-20, 5:00 PM PT. Submit at BoatHackathon.com/builders from the regular builder sign-in (saves in preview mode don't count). Fill in every `TODO` before submitting.

## Form fields
| Field | Value |
| --- | --- |
| Boat name | Bloom |
| Participation | TODO: in person or remote |
| Project logo | TODO: PNG/JPEG, up to 4 MB |
| Project link | TODO: live app URL (`https://<host>/intake/`). The repo is private, so use the app URL. |
| Demo video link | TODO: X or YouTube, 2 minutes or less |
| X post link | TODO |
| Crew | TODO |

## Captain's log (paste into the form)
Bloom is a private AI copilot for gynecology visits. A patient answers a short intake chat before the appointment. Bloom turns it into a one-page physician brief with guideline citations. The gynecologist confirms, edits or rejects every AI draft before it counts.

Three things make it different:
1. **Safety first, without the model.** Six red-flag rules (possible ectopic pregnancy, heavy bleeding, pelvic infection signs, pregnancy or postpartum warning signs, self-harm, sexual assault disclosure) are deterministic Python on the server, each with tests. When one fires, the chat stops and the patient sees urgent-care actions straight away.
2. **Private inference that fails closed.** Every model call goes through TrustedRouter with a privacy floor set by the server, not the browser. In private mode, if no confidential route is available, Bloom refuses and does not fall back to another model. The Privacy & Trust panel shows the route, policy, receipt evidence and latency for every call, and a live negative test shows a refusal.
3. **Cited, de-identified guidelines.** Context.dev searches guideline sites (ACOG, USPSTF, CDC) with queries built only from structured fields, never from what the patient typed. The brief may cite only passages that were actually retrieved.

Built on a Boat.dev VM (Flutter Web, FastAPI and LangGraph, SQLite, Docker Compose). All demo data is synthetic.

## X post (thread)
1/ We built Bloom on the water at #boathackathon: a private AI copilot for gynecology visits. Patients do a short intake chat; the gynecologist gets a cited one-page brief to confirm, edit or reject. @boathackathon @teamily_ai
2/ Red flags never depend on the model: six deterministic rules stop the chat and show urgent care actions.
3/ Every AI call goes through @nytokenexchange TrustedRouter with a server-set privacy floor. Private mode fails closed: no fallback model, ever. The trust panel shows the evidence for each call.
4/ Guidelines come from @getcontextdev, searched with de-identified queries and an allowlist of guideline sites. Built and run on a @boatdotdev VM.
5/ Demo: TODO video link · App: TODO URL

## 2-minute video script
| Time | Screen | Say |
| --- | --- | --- |
| 0:00–0:15 | A01 → P01 | "Gynecology visits are short. Bloom lets the patient tell their story first, privately." |
| 0:15–0:45 | P02 with S1 | Run scenario S1 live: a few turns, progress bar, then P04 Done. |
| 0:45–1:00 | P02 with S7 → P03 | "Soaking a pad every hour and lightheaded": rule R2 fires, the chat stops, urgent actions appear. "No model decided that." |
| 1:00–1:25 | D01 → D02 | Queue with the red flag on top. Open the S1 brief: citations to USPSTF. Click Edit, change a line, Confirm. Provenance is stored. |
| 1:25–1:45 | D03 | Privacy & Trust panel: route, ZDR policy, receipt, latency per call. |
| 1:45–2:00 | D05 negative test | Run the negative test: a confidential floor the route can't meet returns Refused, one call, no fallback. "Encrypted AI doing real clinical work." |

Wording rules: never say "HIPAA compliant", "secure" without evidence, or "data never leaves the app". The GLM-5.3 Flash route is zero-data-retention (operator-declared), not confidential; say so if asked.

## Prize checklist
- Boat.dev: running on a Boat VM; `boat fork` demo snapshot; coding-aboard photo and commit.
- NY Token Exchange / TrustedRouter: all AI calls through TrustedRouter; D03 evidence; D05 negative test.
- Context.dev: cited guideline retrieval with a domain allowlist; Monitor webhook for guideline updates (stretch).
- LetsEncrypt.AI ($1,000): GLM-5.3 Flash via TrustedRouter for every AI call; show the D05 refusal live.
- Teamily: daily status posts in the group.
