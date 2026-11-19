# Bloom: form answers (paste-ready)

Form: BoatHackathon.com/builders. Deadline: **Fri 2026-11-20, 3:00 PM PT**. Aim to submit by 2:00 PM PT.
Source of truth for wording: `docs/submission.md`. If the two differ, `docs/submission.md` wins; update this file to match.

Fields marked **HUMAN** cannot be filled by an agent.

## Fields

### Boat name
```
Bloom
```

### Participation — HUMAN
Pick one in the form: **In person** or **Remote**.

### Project logo
Upload `docs/submission/bloom-logo-1024.png` (1024×1024 PNG, about 54 KB; limit 4 MB).
Fallback if the uploader wants something smaller: `docs/submission/bloom-logo-512.png`. Vector source: `docs/submission/bloom-logo.svg`.

### Project link
```
https://box-node-65cdd7262c0153ea-80.on.boat.dev/
```
One link: a landing page with **Open patient app** (→ `/intake/`) and **Open clinic app** (→ `/doctor/`) buttons. Direct links still work: https://box-node-65cdd7262c0153ea-80.on.boat.dev/intake/ and https://box-node-65cdd7262c0153ea-80.on.boat.dev/doctor/.

Demo fork `bx_x6rcgdqh` (snapshot `bloom-demo` of VM `bx_2dpym7ge`), redeployed 2026-11-19 at `4727859`. Backup: https://box-node-ea80fef589949d9a-80.on.boat.dev/ (the original VM, same landing page). Open it in a private window first: the landing page and both buttons must work. The repo is private, so do not use the GitHub link.

### Demo video link — HUMAN
YouTube (unlisted) or X link, video 2:00 or less. Upload `docs/submission/bloom-demo-voiceover.mp4` (1:54, captions + narration). The narration text is in `docs/submission/voiceover-script.md`.

### X post link — HUMAN
Post the thread in `docs/submission.md` → "X post (thread)" from the team's X account, then paste the link to post 1/ (`https://x.com/<handle>/status/<id>`).

### Crew — HUMAN
Names (and X handles, if the form asks) of everyone on the crew.

### Captain's log
```
Bloom is a private AI copilot for gynecology visits. A patient answers a short intake chat before the appointment. Bloom turns it into a one-page physician brief with guideline citations. The gynecologist confirms, edits or rejects every AI draft before it counts.

Three things make it different:
1. Safety first, without the model. Six red-flag rules (possible ectopic pregnancy, heavy bleeding, pelvic infection signs, pregnancy or postpartum warning signs, self-harm, sexual assault disclosure) are deterministic Python on the server, each with tests. When one fires, the chat stops and the patient sees urgent-care actions straight away.
2. Private inference that fails closed. Every model call (GLM-5.3 Flash) goes through NY Token Exchange's TrustedRouter with a privacy floor set by the server, not the browser. In private mode, if no confidential route is available, Bloom refuses and does not fall back to another model. The Privacy & Trust panel shows the route, policy, gateway receipt (Bloom does not verify its signature) and latency for every call, and a live negative test shows a refusal. The live demo runs in dev mode on a zero-data-retention route (operator-declared), not a confidential one, and the panel labels it that way.
3. Cited, de-identified guidelines. Context.dev searches guideline sites (ACOG, USPSTF, CDC) with queries built only from structured fields, never from what the patient typed. The brief may cite only passages that were actually retrieved.

Built on a Boat.dev VM (Flutter Web, FastAPI and LangGraph, SQLite, Docker Compose). All demo data is synthetic. Bloom is a hackathon prototype, not a medical device.
```
(Plain text without `**` bold, in case the form doesn't render Markdown. If it does, paste the version in `docs/submission.md`. A longer version written as a captain's log, with each partner's role, is in `docs/submission/captains-log.md`.)

## Pre-submit checklist

Before opening the form
- [ ] Demo VM is up and `boat host … --public` is set; `https://box-node-65cdd7262c0153ea-80.on.boat.dev/` shows the landing page, and its Patient and Doctor buttons open `/intake/` and `/doctor/` in a private window.
- [ ] `server/scripts/live_check.py --base https://box-node-65cdd7262c0153ea-80.on.boat.dev` passes (S1 reaches a brief, S7 goes urgent R2).
- [ ] D05 negative test shows **Refused** (not "Provider error").
- [ ] VM won't auto-stop before judging (`--no-auto-stop` or `boat extend`).
- [ ] Demo video is ≤ 2:00, plays signed out (unlisted YouTube or public X), and has no real names or health data.
- [x] X thread is posted (2026-11-19): each post under 280 characters (counts in `docs/submission.md`); the @handles are checked against the sponsors' real accounts; post 5/ has the real video and app links.
- [ ] Wording check on everything pasted: no "HIPAA compliant", no unqualified "secure", no "encrypted", no "data never leaves the app"; the GLM-5.3 Flash route is called zero-data-retention, not confidential.

In the form
- [ ] Sign in from the **regular builder sign-in** at BoatHackathon.com/builders, **not preview mode** (saves in preview mode don't count).
- [ ] Every field filled; no `TODO`, `<VM host URL>` or `<video link>` placeholder left anywhere.
- [ ] Logo uploaded is `bloom-logo-1024.png` and the preview shows it.
- [ ] Project link is `https://box-node-65cdd7262c0153ea-80.on.boat.dev/` and opens the landing page (not GitHub).
- [ ] Captain's log pasted in full (check the end: "…not a medical device.").
- [ ] Click Submit, then reload the page and confirm the submission shows as submitted (not a draft).
- [ ] Screenshot the confirmation; note the time (must be before 3:00 PM PT, Fri 2026-11-20).

After submitting
- [ ] Post the confirmation in the Teamily group.
- [ ] Keep the VM running through judging; rotate the TrustedRouter and Context.dev keys after the demo (docs/STATUS.md).
