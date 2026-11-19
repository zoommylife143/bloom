# Bloom demo video: voiceover script

Narration used in `bloom-demo-voiceover.mp4` (1:54). Generated locally with Piper TTS (voice `en_US-lessac-medium`); re-record in your own voice by reading each line at its start time. Wording follows the claims policy: the demo route is zero data retention (operator-declared), not confidential.

| Start | Screen | Partner(s) | Narration |
| --- | --- | --- | --- |
| 0:00 | Title → P01 consent | Boat.dev | This is Bloom, a private AI copilot for gynecology visits, built by Zoom My Life. The whole app runs on a Boat.dev virtual machine. |
| 0:11 | P02 intake chat (S1) | GLM-5.3 Flash, NY Token Exchange TrustedRouter | The patient answers a short intake chat before the visit. Each question is written by GLM-5.3 Flash, and every model call goes through NY Token Exchange's TrustedRouter, with a zero-data-retention privacy floor set by the server, never by the browser. Bloom's own safety rules check every answer. |
| 0:33 | S7 → P03 urgent care | Bloom safety rules (no partner, no model) | Now a second patient reports heavy bleeding and feeling lightheaded. Rule R2 fires. That is deterministic code on the server, not the model, so the chat stops and urgent-care steps appear at once. |
| 0:47 | D01 queue → D02 brief | Context.dev | In the clinic, the red flag sits at the top of the queue. The first patient's brief cites cervical screening guidance from the USPSTF. Context.dev found those passages on guideline sites only, using queries built from structured fields, never the patient's own words. |
| 1:05 | D02 edit and save | GLM-5.3 Flash (draft) | Every AI output is a draft. The doctor confirms, edits, or rejects it, and Bloom keeps the original draft and its provenance. |
| 1:15 | D03 Privacy & Trust | TrustedRouter, Context.dev | The Privacy and Trust panel lists every outside call for this patient: the TrustedRouter route, the privacy policy, the signed gateway receipt, the request ID, and latency. In this demo the route is zero data retention, not confidential, and Bloom labels it that way. The Context.dev row shows the search used structured fields only. |
| 1:39 | D05 negative test | TrustedRouter | Finally, the negative test. We ask TrustedRouter for a confidential route that no provider can meet. It is refused after one call, and no fallback model is used. If it can't be private, Bloom says no. |
