# Captain's log: Bloom

Paste-ready project description for the submission form, written as a captain's log. Wording follows the claims policy in `docs/submission.md`.

```
CAPTAIN'S LOG: BLOOM, a Zoom My Life build. Boat Hackathon SF 2026.

MISSION
Gynecology visits are short, and patients often run out of time to tell their story. Bloom is a private AI copilot that lets them tell it first. Before the appointment, the patient answers a short intake chat. Bloom turns it into a one-page physician brief with guideline citations, and the gynecologist confirms, edits or rejects every AI draft before it counts.

CHARTING THE COURSE
We designed every screen in Figma first. Screen IDs double as frame names and app routes, and the design tokens became one shared Flutter design system for two apps: a patient intake app and a clinic dashboard. Three compressed design, technical and plan gates were approved before any code was written.

THE CREW ON DECK
- Boat.dev is the ship. One VM runs the whole stack (Flutter Web, FastAPI with LangGraph, SQLite) in Docker Compose. A frozen boat fork serves the demo, and the original VM is kept as a backup.
- NY Token Exchange TrustedRouter is the only way to the model. The server sets the privacy floor, never the browser. Every call returns a signed receipt, a request ID and latency, and Bloom shows them in a Privacy & Trust panel. Bloom does not verify the receipt signature.
- GLM-5.3 Flash (LetsEncrypt.AI) writes every intake question and every brief, in JSON mode, with one repair step and a fixed fallback question so a patient never hits a dead end.
- Context.dev finds the guidelines (ACOG, USPSTF, CDC only) using queries built from structured fields, never the patient's own words. A brief can cite only passages that were actually retrieved.

ROUGH WATER
Our first live runs failed when the model answered in prose. JSON mode and a repair step got every turn of our live test scenarios through on the first pass. One provider route returned errors, so we moved to a working zero-data-retention route and labelled it honestly.

SAFETY ABOARD
Six red-flag rules (possible ectopic pregnancy, heavy bleeding, pelvic infection, pregnancy or postpartum warning signs, self-harm, sexual assault disclosure) are deterministic server code with tests. When one fires, the chat stops and urgent-care steps appear. No model decides that.

IF IT CAN'T BE PRIVATE, BLOOM SAYS NO
Private mode fails closed: with no confidential route, Bloom refuses and calls no fallback model. A live negative test shows the refusal. The demo runs in dev mode on a zero-data-retention route (operator-declared), not a confidential one, and the app says so.

SHIP'S LOG
834 tests passing, 10 synthetic scenarios, 25 of 25 smoke checks on the live VM.

All data is synthetic. Bloom is a hackathon prototype, not a medical device.
```
