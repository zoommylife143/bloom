# Bloom: demo video recording plan

Target: one video, **2:00 or less**, that works with the sound off (captions carry the story). Script source: `docs/submission.md` → "2-minute video script". Screen IDs and routes: `docs/02-app-flow.md`.

Wording rules for captions and voiceover: no "HIPAA compliant", no "secure", no "encrypted", no "data never leaves the app". The demo runs in **dev mode**: GLM-5.3 Flash on a zero-data-retention route (operator-declared), **not** confidential. Say so on screen (segment 5).

## 0. Before you record (15 min)

1. Deploy is up: `<VM host URL>/intake/` and `<VM host URL>/doctor/` both load. Run `server/scripts/live_check.py --base <VM host URL>` once; it should pass.
2. Browser: Chrome, normal (not incognito) profile with no extensions showing, zoom 100%, window **1440×900** or larger. D02 needs at least 1024 px of content width to show the brief and the Privacy & Trust panel side by side.
3. Open two tabs:
   - Tab A (patient): `<VM host URL>/intake/`
   - Tab B (clinic): `<VM host URL>/doctor/`
4. Tab B, sign in now (off camera is fine): A01 "Sign in to the demo" → field "Your name on review decisions": type `Dr. Demo` → click **Continue as clinician**. You land on D01 "Pre-visit intakes". Do **not** reload tab B during the take: the demo token lives in memory, and a reload signs you out.
5. Safety net: in tab B go to **Demo scenarios** (D05) and click **Run** on S1 once, before recording. If the live S1 brief in segment 4 is slow, open this one instead; its D02 looks the same.
6. Recorder: OBS, QuickTime or the Chrome screen recorder, 1080p, 30 fps, capture the browser window only. Hide bookmarks bar and desktop notifications.
7. Have this file open on a second screen or printed. Copy the scenario turns below into a text file so you can paste them; typing live is fine too.

Model calls take a few seconds to a minute each. Record the long parts in full, then **cut or speed up the waits in editing** and show the caption "Model waits sped up" while sped up. Never cut a refusal or a red flag.

## 1. 0:00–0:15 · A01 → P01 (patient)

Tab A.
1. Start recording on A01 "Sign in to the demo".
2. Click **Continue as patient**.
3. P01 "Before your gynecology visit": pause 2 s on the "How this conversation is protected" list.
4. Tick the consent box ("I understand this is a demo…").
5. Click **Start**.

Captions:
- 0:00 `Bloom · a pre-visit AI copilot for gynecology`
- 0:05 `Visits are short. Patients tell their story first, before the appointment.`
- 0:10 `Demo login · synthetic patients only`

## 2. 0:15–0:45 · P02 with scenario S1

Tab A, P02 Intake chat. Bloom asks a question; reply with the next S1 line (from `scenarios/S1.json`), one per turn, in this order. If Bloom asks something already answered, answer with the closest line below or skip with the quick reply if one fits.

| Turn | Type exactly |
| --- | --- |
| 1 | `I'd like a checkup. I think I'm overdue for a Pap smear.` |
| 2 | `I'm 34.` |
| 3 | `My last Pap was in 2019, so it's been a while. I've never had an HPV test that I know of.` |
| 4 | `My periods have been a bit irregular the last few months, sometimes 24 days apart and sometimes 38.` |
| 5 | `My last period started about 3 weeks ago.` |
| 6 | `No, I don't think I could be pregnant. We use condoms every time.` |
| 7 | `No pain, just the timing is unpredictable.` |
| 8 | `No medications and no allergies.` |

Press Enter (or click Send) after each line. Keep the progress bar ("Question N of about M") in frame. The chat ends on P04 "Thank you".

In editing: keep turns 1–3 at normal speed, speed up the rest, hold P04 for 2 s.

Captions:
- 0:15 `Scenario S1 (synthetic): 34, overdue cervical screening, irregular cycles`
- 0:22 `Bloom asks one question at a time and tracks progress`
- 0:35 `Model waits sped up`
- 0:42 `Intake done → the doctor gets a draft brief`

## 3. 0:45–1:00 · P02 with S7 → P03 (red flag R2)

Tab A.
1. Reload the page (`<VM host URL>/intake/`). A reload signs the patient out, which starts a fresh session.
2. Click **Continue as patient** → tick consent → **Start**.
3. Type the S7 lines (`scenarios/S7.json`), one per turn:

| Turn | Type exactly |
| --- | --- |
| 1 | `I'm bleeding a lot more than usual.` |
| 2 | `I'm 38.` |
| 3 | `Since this morning I've been soaking through a pad every hour and I feel lightheaded.` |

4. After turn 3 the chat stops and P03 Urgent care appears. Hold 3 s on the urgent actions and "Bloom has stopped the questions…". Do not click **I understand** on camera (optional).

Captions:
- 0:45 `Scenario S7 (synthetic): heavy bleeding and lightheaded`
- 0:52 `Rule R2 fired: deterministic server code, not the model`
- 0:56 `The chat stops. Urgent-care steps appear at once.`

## 4. 1:00–1:25 · D01 → D02 (physician brief)

Tab B.
1. Click **Patient queue** in the nav, then **Refresh**. The S7 session shows status **Red flag** at the top; S1 shows **Ready**.
2. Hover the Red flag row for 1 s (no click).
3. On the S1 row (reason mentions cervical screening), click **Open brief**. If it still shows "Generating draft", wait (cut in editing) or open the S1 run from section 0, step 5 instead.
4. D02: scroll slowly through Subjective → Screenings possibly due. Hover a citation link to USPSTF (cervical screening) for 2 s.
5. In the decision bar, click **Edit**.
6. In "Suggested questions" (one item per line), add a new last line: `Ask about HPV vaccination history.`
7. Click **Save edits**. The banner changes to "Edited and approved by Dr. Demo at … · original AI draft kept in history". Hold 2 s on the banner and the Provenance line.

Captions:
- 1:00 `Doctor view · the red flag sits at the top of the queue`
- 1:07 `One-page brief with guideline citations (USPSTF), retrieved, not invented`
- 1:15 `Every AI output is a draft: Confirm, Edit or Reject`
- 1:21 `Edit saved · the original AI draft and provenance are kept`

## 5. 1:25–1:45 · D03 Privacy & Trust panel

Tab B, same D02 page; the panel is the right-hand column (or open `<VM host URL>/doctor/brief/<id>/trust`).
1. Scroll the panel slowly from the top: Mode (dev), the dev-mode warning, then the call rows.
2. Pause on one OK row so viewers can read: "Route: … · Zero data retention (operator-declared)", "Required policy: … · model: …", "Evidence: gateway receipt returned (signature not verified by Bloom)", "Request ID … · latency".
3. Pause 2 s on the Context.dev row: "Built from structured fields only · N passages returned".

Captions:
- 1:25 `Privacy & Trust: every external call for this patient`
- 1:31 `Route, privacy policy, gateway receipt and latency per call`
- 1:37 `Dev mode: GLM-5.3 Flash, zero data retention, not confidential, and labelled so`
- 1:42 `Guideline searches use structured fields only, never the patient's words`

## 6. 1:45–2:00 · D05 negative test

Tab B.
1. Click **Demo scenarios** in the nav.
2. Scroll to the card "Negative test: confidential route unavailable".
3. Click **Run negative test**. Wait for the red banner: "Request refused before inference: no route met the confidential privacy floor. No fallback model was called." and the Refused row below it.
4. Hold 3 s, end recording.

If the banner says "Provider error, not a refusal", click **Run negative test** again; never publish a take that shows a provider error as a refusal.

Captions:
- 1:45 `Negative test: ask for a confidential route that isn't available`
- 1:51 `Refused · one call · no fallback model`
- 1:56 `If it can't be private, Bloom says no. · Synthetic data only.`

## 7. Edit and export

1. Trim to **≤ 2:00** (aim for 1:55). Check the final length in the export dialog.
2. Captions: burn them in (white text on a `#6b2d5c` plum bar, bottom of frame, 2 lines max). Optional: end card with `docs/submission/bloom-logo-1024.png` for 2 s inside the 2:00.
3. Export MP4, H.264, 1080p. File name `bloom-demo.mp4`. Do not commit it.
4. Watch it once with sound off: every segment must make sense from captions alone; no real names or health data visible; no "secure"/"encrypted"/"HIPAA" wording.

## 8. Upload (pick one)

YouTube (unlisted):
1. youtube.com → Create → Upload video → select `bloom-demo.mp4`.
2. Title: `Bloom · AI copilot for gynecology visits (Boat Hackathon SF 2026)`.
3. Description: the first paragraph of the captain's log + `Synthetic data only. Not a medical device.`
4. Audience: "No, it's not made for kids". Visibility: **Unlisted** → Save.
5. Copy the share link (`https://youtu.be/...`). Open it in a private window to check it plays signed out.

X:
1. Post the video as a reply in the thread (or attach it to post 1/). X allows up to 2:20 for standard accounts; ours is ≤ 2:00.
2. After it processes, open the post, click Share → Copy link.

Then paste the link into the form's "Demo video link" and into post 5/ of the X thread (`docs/submission.md`).
