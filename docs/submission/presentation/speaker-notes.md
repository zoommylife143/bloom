# Bloom: Partner Architecture — speaker notes

Confidential · © 2026 Zoom My Life · Do not distribute

## 1. Bloom: how partner platforms power a private AI gynecology copilot

Bloom is a pre-visit intake and physician-brief agent for gynecology clinics. This deck walks through the architecture and shows, partner by partner, which requirement each platform satisfies and where it lives in the code.

## 2. Eight requirements shaped every architecture decision

Four of these come from the hackathon partner prizes (Boat, TrustedRouter, LetsEncrypt.AI, Context.dev). The other four are product rules from CLAUDE.md that the architecture enforces in code. The rest of the deck maps each one to a partner and a file.

## 3. One Boat VM, two gateways out

Everything Bloom runs is on one Boat.dev VM: nginx serves both Flutter Web apps and proxies /api to the FastAPI server, which is internal only. The server is the only component that talks to the outside: AI calls go to TrustedRouter, which forwards to GLM-5.3 Flash under a privacy floor; guideline searches go to Context.dev. The browser never sees a key and never chooses the privacy mode. Figma is upstream of the code: its tokens become the bloom_ui package both apps use.

## 4. Rules wrap every model call

Green boxes are deterministic code, dark plum boxes call GLM-5.3 Flash through TrustedRouter, and the light plum box calls Context.dev. A red flag can stop the turn before the model is ever called (safety_pre) or right after it (safety_post). When intake is complete, the graph de-identifies, retrieves guidelines and drafts the brief; sanitize_brief removes any citation that was not actually retrieved. Bad model JSON gets one repair call, then a fixed fallback question, so the patient never sees an error page.

## 5. Boat.dev

Boat.dev is the only place Bloom runs. The API is never exposed directly; only nginx is public. The demo fork is a frozen snapshot of a passing build, so last-minute changes can't break the judged copy. The original VM stays as a backup with the bloom-demo snapshot.

## 6. NY Token Exchange TrustedRouter

TrustedRouter is how requirement 2 (privacy floor) and requirement 3 (per-call evidence) are met. A TrustEvent row is stored for every model or retrieval call: metadata only, never clinical text. Be honest about the limit: Bloom displays the gateway’s signed receipt but does not verify the signature itself.

## 7. If it can’t be private, Bloom says no

This is the heart of requirement 2. Private mode fails closed by design: today PRIVATE_MODEL_ID is empty because NYTE has not named a confidential route, so private mode refuses everything. The demo runs in dev mode, and the UI says so plainly. The D05 negative test shows the refusal path live.

## 8. GLM-5.3 Flash · LetsEncrypt.AI

Before the JSON-mode fix, 6 of 8 turns in scenario S1 failed because the model answered in prose. After JSON mode, prompt changes and the repair step, live runs of S1, S3 and S7 got valid JSON on the first pass every time. If the model is unavailable, a deterministic brief is written and clearly labelled “written without AI”.

## 9. Context.dev

Context.dev satisfies requirement 5. The key design choice is that the search query is built from structured intake fields (age band, topic), never from free text, so no identifier can leak into a third-party search. The brief may cite only passages that were actually retrieved and stored. With no passage, D02 shows “No guideline retrieved”.

## 10. Figma

The rule in this repo is: a design change goes into Figma first, then the docs, then the code. Bloom tokens are mapped into a Material 3 ColorScheme in bloom_ui, so both Flutter apps share one look. This palette (plum, warm canvas, verified green, critical red) is the one used in this deck.

## 11. Planned in gates, built by agents, coordinated in the open

The team worked in hackathon-fast mode: one plan document stood in for the full doc set, and three compressed gates were approved on 16 November before code started. Each part of the system was built by a Claude Code agent from a written brief, which is why the code maps so cleanly onto the partner boundaries.

## 12. Every requirement has evidence you can check

This closes the loop on the requirements slide: each row names something that can be re-run or opened. The live check script, server/scripts/live_check.py, re-runs S1, S3 and S7 against any deployed copy.

## 13. What we proved, and what we didn’t claim

Numbers are from the G4 release check and the deploy logs on 19 November. The limits box matters as much as the numbers: the wording rules in the repo forbid claiming HIPAA compliance, encryption or that data never leaves the app.

## 14. Safety without the model. Privacy that fails closed. Citations you can check.

Close on the three differentiators. Open the patient app, run scenario S7 to show the red flag, then the clinic app’s D05 negative test to show a refusal.
