# Bloom: sponsor execution runbook

This runbook gives the steps to build and ship Bloom with each Boat Hackathon sponsor. Follow it in order. "You" means a team member at a laptop. Steps marked (Claude) can be done by Claude Code in the repo.

The final submission deadline is Fri Nov 20, 5:00 PM PT. Aim to submit Wed Nov 18.

## 0. Accounts and keys (Mon)
| Sponsor | Get | Where it goes |
| --- | --- | --- |
| Boat.dev | Account + credits (Anicet) | `boat` CLI login on your laptop |
| NY Token Exchange / TrustedRouter | API key with confidential-route access, plus the GLM-5.3 Flash credit and its model ID | `.env`: `NYTE_API_KEY`, `NYTE_MODEL_ID`, `DEV_MODEL_ID` |
| Context.dev | API key + credits (Michael) | `.env`: `CONTEXT_DEV_API_KEY` |
| Teamily | Join the group; PLUS code 78ACUM | Team channel |

Keys live only in `.env` on the VM and on laptops. Never put them in git or chat.

## 1. Boat.dev: the computer
1. Install the CLI.
   - Windows cmd: `powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://boat.dev/install.ps1 | iex"`
   - macOS/Linux: `curl -fsSL https://boat.dev/install | sh`
2. Run `boat new`, then `boat list`, then `boat ssh`.
3. On the VM, run `git clone https://github.com/zoommylife143/bloom && cd bloom`, then `cp .env.example .env` and fill in the keys.
4. Run `docker compose up -d --build`. Check `curl localhost/api/healthz`.
5. Get a public URL. Boat VMs have public IPv6, and the IP changes on resume. Ask Boat for the recommended HTTPS hostname, or else run a tunnel from the VM. Test it from a phone on cellular.
6. Raise auto-stop to cover Nov 18–21. The default is 1 hour.
7. Optional: `boat prompt` runs Claude Code inside the VM, so the build can continue while you are aboard.
8. On Thu, once all scenarios pass, run `boat fork` to make the demo snapshot. Demo from the fork.
9. For the coding-aboard evidence: on a boat, `boat ssh`, make a real commit and push it, then photograph the screen and post it on X.

## 2. NY Token Exchange: private inference
1. (Claude) `server/app/router.py` uses the OpenAI SDK with `base_url=https://api.nytokenexchange.com/v1`.
2. Hello-world: make one call with `NYTE_MODEL_ID`. Use `with_raw_response` and save every header and body field to `docs/nyte-response-sample.json`, with the key redacted. This decides what the D03 panel shows.
3. Map the real fields to TrustRow: route/provider, policy, evidence, request ID, latency. If a field isn't returned, show "Evidence not exposed by provider".
4. Refusal test: request a route that can't qualify, and record the exact status and error code. `router.py` maps it to `ConfidentialRouteUnavailable`. The UI then shows `P02 / route refused` and a Refused row in D03. Add a unit test asserting that no second model call happens.
5. Dev mode: use the same SDK with `DEV_MODEL_ID` (GLM-5.3 Flash). The mode comes from `BLOOM_MODE` on the server and never from the client.
6. Demo line: "confidential inference with verifiable evidence". Never say "HIPAA compliant".

## 3. Context.dev: cited guidelines
1. (Claude) `server/app/retrieve.py` uses the Python SDK and the `GUIDELINE_DOMAINS` allowlist (acog.org, uspreventiveservicestaskforce.org, cdc.gov).
2. `deidentify.py` builds queries from structured fields only, for example "cervical cancer screening interval age 30-39". The planted-identifier test must pass.
3. For each query, call Search (or Answers with a JSON schema). Keep the passage, URL and retrieved_at in the `evidence` table.
4. The brief node may cite only stored passages. With no passages, it writes "No guideline retrieved" (the `D02 / no guideline` screen).
5. Stretch: a Monitor on the guideline URLs calls the webhook `/api/webhooks/context-monitor` and shows a "guideline updated" banner. Parse Document handles a synthetic lab PDF.
6. During development, Claude can run sample searches through the connected Context.dev tools to collect real passages for scenarios S1–S5.
7. Budget: the free tier is 1,000 credits per month. Cache evidence per scenario so demos don't spend credits.

## 4. Teamily and LetsEncrypt.AI
- **Teamily:** post daily status, ask Travis eligibility questions, and ask the sponsors the open questions in `docs/STATUS.md`.
- **LetsEncrypt.AI:** use it to frame the pitch for the $1,000 prize: encrypted AI doing useful work in a real clinical flow. Show the D05 negative test live.

## 5. Build order (maps to plan §10)
| Day | Steps | Sponsor |
| --- | --- | --- |
| Mon | Scaffold (ADR 0003), Boat VM + URL, NYTE and Context.dev hello-worlds, coding-aboard post | Boat, NYTE, Context.dev |
| Tue | `bloom_ui` from Figma tokens; patient app P01–P04; intake graph; rules R1–R6 with tests | NYTE (dev mode) |
| Wed | Private mode fail-closed; de-identify + retrieve; brief; clinic D01, D02, D03, D06; rough video; submit | NYTE, Context.dev |
| Thu | 10 scenarios; D04, D05, S01; polish; `boat fork`; final video | Boat |
| Fri | Links, captain's log, X thread tagging sponsors; freeze at noon | all |
| Sat | Demo from the fork | all |

## 6. Submission (BoatHackathon.com/builders)
Submit the boat "Bloom", crew, the public X post URL, the app URL, and a video of at most 2 minutes. The upload form is on that page. The deadline is Fri Nov 20, 5:00 PM, and demo picks are rolling, so submit early.

The X post must use #boathackathon and tag @boathackathon and @teamily_ai. Also tag each sponsor whose prize you want: @boatdotdev, @getcontextdev and @nytokenexchange.

Contacts: Travis at travis@codemkrs.com or the group chat. Context.dev credits: michael@context.dev or @michael_chomsky on X.

Boat.dev billing: free participant credits are not confirmed. Ask Travis or the Boat.dev team about the repeat charge before paying again.

$1,000 LetsEncrypt.AI prize: it goes to the most useful app whose users use encrypted AI tokens. The organizers say TrustedRouter's GLM 5.3 Flash can be used. Confirm that the route is confidential before labeling it private in D03.
