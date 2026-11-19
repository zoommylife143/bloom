# Figma build references

Exported from Figma file `0lWIv5IY18QemXtzP3YaTE` on 2026-11-19 with the Figma MCP (`get_screenshot`, `get_design_context`, `get_metadata`). Figma is the source of truth: if a spec here disagrees with Figma, Figma wins and this folder should be regenerated.

- PNGs are 1x renders at the frame's native size (desktop 1440 x 900, phone 390 x 844, tablet 768 x 1024 or 1024 x 1366).
- Each `<ID>.md` is the build spec for that screen and all its states: layout top to bottom, verbatim copy, Bloom components and variants, tokens, and what each state changes.
- Token values are also in `docs/design-tokens.json`. Screen IDs, routes and node IDs come from `docs/02-app-flow.md`.
- D04 (`7:310`) and S01 (`27:3`) are cut this week and were not exported.

## Index

| ID | Screen | Spec | PNGs (node) |
| --- | --- | --- | --- |
| A01 | Sign in | [A01.md](A01.md) | `A01.png` (26:3), `A01-invalid-code.png` (26:38), `A01-phone.png` (26:74) |
| P01 | Welcome + consent | [P01.md](P01.md) | `P01.png` (6:2), `P01-loading.png` (23:33) |
| P02 | Intake chat | [P02.md](P02.md) | `P02.png` (6:40), `P02-waiting.png` (10:23), `P02-refused.png` (6:87), `P02-model-error.png` (23:71), `P02-tablet.png` (23:108) |
| P03 | Urgent care | [P03.md](P03.md) | `P03.png` (6:125) |
| P04 | Done | [P04.md](P04.md) | `P04.png` (6:143) |
| D01 | Patient queue | [D01.md](D01.md) | `D01.png` (7:2), `D01-empty.png` (11:362), `D01-loading.png` (25:198) |
| D02 | Physician brief | [D02.md](D02.md) | `D02.png` (7:139), `D02-generating.png` (25:281), `D02-approved.png` (11:128), `D02-edited.png` (25:401), `D02-rejected.png` (25:497), `D02-no-guideline.png` (11:252), `D02-tablet.png` (25:622) |
| D03 | Privacy & Trust panel (side sheet in D02) | [D03.md](D03.md) | `D03-row-states.png` (7:261); default appearance is visible in the D02 PNGs |
| D05 | Demo scenarios | [D05.md](D05.md) | `D05.png` (7:428) |
| D06 | Red-flag summary | [D06.md](D06.md) | `D06.png` (25:722) |

## Components (page "Components", node 1:3)

Map each to a `packages/bloom_ui` widget. Values below are from `get_design_context` on each component set.

| Component | Node | Variants (Figma property) | Spec |
| --- | --- | --- | --- |
| Button | 4:10 | `Style` = Primary 4:2, Secondary 4:4, Critical 4:6, Ghost 4:8 | Row, padding H `xl` 24 / V `md` 12, gap 8, radius `full` 999, Label text. Primary: bg `action/primary`, text `text/on-action`. Secondary: bg `bg/surface`, 1 px `border/default`, text `text/primary`. Critical: bg `status/critical`, text `text/on-action`. Ghost: no bg, text `text/brand`. Default label `Continue`. Usage note: Primary for the main action per screen; Critical only for urgent-care actions; Secondary for Edit/Reject. |
| StatusChip | 4:27 | `Status` = In progress 4:11, Red flag 4:13, Ready 4:15, Approved 4:17, Refused 4:19, Verified 4:21, Dev mode 4:23, Draft 4:25, Rejected 25:196 | Padding H `md` 12 / V `xs` 4, radius `full`, Overline text (DM Sans SemiBold 12/16, tracking 0.72 px), UPPERCASE label = status name (`IN PROGRESS`, `RED FLAG`, `READY`, `APPROVED`, `REFUSED`, `VERIFIED`, `DEV MODE`, `DRAFT`, `REJECTED`). Colours: In progress `bg/subtle` + `text/secondary`; Ready, Draft `bg/brand-muted` + `text/brand`; Approved, Verified `status/verified-subtle` + `status/verified`; Red flag, Refused, Rejected `status/critical-subtle` + `status/critical`; Dev mode `status/warning-subtle` + `status/warning`. No icon. |
| ChatBubble | 4:32 | `Sender` = Bloom 4:28, Patient 4:30 | Width 280 in master, padding H 16 / V 12, radius `lg` 16, Body text. Bloom: `bg/surface` + 1 px `border/default`, text `text/primary`. Patient: `action/primary` bg, text `text/on-action`. One question per bubble; never a diagnosis. |
| QuickReply | 4:33 | none | Padding H `lg` 16 / V `sm` 8, radius `full`, bg `bg/surface`, 1 px `border/brand`, Label text `text/brand`. Default text `Not sure`. Figma height 38: enforce 44 px min tap target in code (component description says so). |
| Banner | 4:56 | `Type` = Demo 4:35, Urgent 4:41, Draft 4:47, Verified 4:51 | Row, padding H 16 / V 12, gap 8, radius `md` 12, 18 px icon + Label text, master width 358 (instances usually fill). Demo: `icon/info`, `status/warning-subtle` bg, `status/warning` text, `Demo · do not enter real health information`. Urgent: `icon/alert`, `status/critical-subtle` / `status/critical`, `This needs urgent care`. Draft: `icon/sparkle`, `bg/brand-subtle` / `text/brand`, `AI draft · needs your review`. Verified: `icon/shield`, `status/verified-subtle` / `status/verified`, `Confidential inference · attested`. |
| CitationLink | 4:57 | none | Row, gap `xs` 4, `icon/link` 16 px + Body Small text in `text/brand`. Default text `uspreventiveservicestaskforce.org`. Allowlisted domains only (ACOG, USPSTF, CDC). |
| TrustRow | 4:105 | `Outcome` = Verified 4:62, Not exposed 4:72, Refused 4:83, Dev mode 4:93 | Column, width 392 in master, padding H 16 / V 12, gap 4, 1 px `border/default`, radius `md`. Header row (gap 8): 18 px icon + Label text (flex) + Overline outcome tag. Then three Caption lines in `text/secondary`. See the variant table below. |
| DecisionBar | 4:106 | none | Row, padding H 16 / V 12, gap 12, bg `bg/surface`, 1 px `border/default`, radius `lg` 16. Contains Button Primary `Confirm`, Button Secondary `Edit`, Button Secondary `Reject`. |

TrustRow variants (master content):

| Outcome | Bg | Icon | Tag text / colour | Line 1 | Line 2 | Line 3 |
| --- | --- | --- | --- | --- | --- | --- |
| Verified | `bg/surface` | `icon/shield` | `OK` / `status/verified` | `Route: confidential · e2e` | `Evidence: attestation reference returned` | `Request ID req_example_0142 · 1.8 s` |
| Not exposed | `bg/surface` | `icon/info` | `OK` / `text/secondary` | `Route: confidential` | `Evidence not exposed by provider` | same |
| Refused | `status/critical-subtle` | `icon/ban` | `REFUSED` / `status/critical` | `Route: none qualified` | `Request refused · no fallback model called` | same |
| Dev mode | `status/warning-subtle` | `icon/flask` | `DEV` / `status/warning` | `Route: GLM-5.3 Flash (development)` | `Not confidential · synthetic testing only` | same |

All four masters share the header title `brief · private demo mode`; screens override it per external call (see D03.md).

## Notable findings

- **Overline letter spacing resolved:** Figma's `letterSpacing: 6` on Overline renders as `tracking 0.72px` at 12 px, so it is 6 percent. Use `letterSpacing: 0.72` in Flutter. (`docs/design-tokens.json` flagged this as unconfirmed.)
- **Button Secondary is 46 px tall, the others 44 px:** the 1 px border is added outside the 44 px content box in Figma. In Flutter, keep all buttons the same height (put the border inside) unless srinivas wants the 2 px difference.
- **TrustRow `Not exposed` shows the tag `OK`** (in `text/secondary`), the same word as Verified. It reads like a pass, which may be intended ("call succeeded, no evidence"), but check with design before shipping; the colour alone carries the difference, which breaks the "meaning never depends on colour alone" rule the Banner description sets.
- **TrustRow masters all carry the same title** `brief · private demo mode`; the title is an instance override, not tied to the variant.
- **Banner master has a fixed width (358)**; instances override it to fill. Build the widget as fill-width.
- **QuickReply is 38 px tall in Figma**; code must use a 44 px minimum target.
- **Button Ghost** exists in the library but check the screen specs for where (if anywhere) it is used.
- **Component defaults leaking into screens (P02):** some ChatBubble instances have no message override and render the master default `When did your last period start?` (third Bloom bubble in P02 default, waiting and tablet; first bubble in refused and model error). The third QuickReply renders its default `Not sure`. P02.md lists what actually renders; decide with design whether those are intended.
- **P02 model-error title is clipped** in Figma (`Something went wrong on our side` set to one line). Let it wrap in code.
- **Error/refused cards in P02 are hand-built**, not components; the model-error card layer is still named "Refused card".
- **No disabled or loading variants exist:** P02's paused input/send use `bg/subtle`; P01's loading Button (`Starting…`) is Primary at 60 percent opacity. Build disabled/loading into the Button widget.
- **P02 typing indicator** is a single 70 x 38 vector, not a component. QuickReply instances on P02 are 36 px tall (still below the 44 px target).
- **P02 tablet** uses raw numbers: 144 px side padding, 480 px content column, bubbles fixed at 280. The progress fill is a fixed width (171 phone, 240 tablet = 50 percent for "Question 5 of about 10"); compute it from the question count.
- **D06 Banner** is `Type=Urgent` with overridden text (verified on instance 25:790).
- **Doctor card radius:** D01, D05 and D06 cards use `radius/lg` 16 in Figma, while the plan (section 3) says doctor cards use `radius/md` 12. The specs follow Figma; confirm with srinivas.
- **Untokenised values:** D01 loading skeleton bars use radius 6 (a `radius/sm` variable exists in Figma, VariableID 2:46, but is not in `docs/design-tokens.json`); D01 empty state uses padding 24/48 (48 has no token).
- **D01 Demo Banner** keeps the master's fixed 358 width instead of filling. D05 and D06 have no Demo Banner.
- **Header styles differ:** D06 uses Heading + Caption subtitle with 12 gap; D01 and D05 use Display + Body Small with 16 gap.
- **States not drawn in Figma:** D05 has no pre-run/running state for scenario cards or the negative test; D06 has no "contacted" state after "Mark as contacted".
- **D03 is not a side sheet in Figma.** `docs/02-app-flow.md` calls it one, but D02 draws it as a fixed 424 px right column (node 7:224). On D02 tablet (25:622) it moves below the brief at full width (960), and the sidebar (25:623) is hidden with no replacement navigation.
- **DecisionBar only appears in D02 default and no-guideline.** Generating, approved, edited and rejected remove it; there is no disabled DecisionBar.
- **No "Edited" StatusChip:** the D02 edited state uses `Status=Approved`. Approved/edited use Banner `Type=Verified`, rejected uses Banner `Type=Urgent`, both with overridden text.
- **D02 rejected** dims the four brief section cards to 50 percent opacity. D02 generating uses skeleton bars (520 x 14, 380 x 14) with radius 6 (untokenised).
- **D02 no-guideline** keeps the check icon on the De-identification block even when the guideline search fails (`search failed (timeout)`).
- **TrustRow Refused and Dev mode** appear only in the reference frame 7:261, not in any D02 frame; D05's negative test uses Refused.
- Copy uses typographic apostrophes (U+2019) in several strings (A01 error, D06 "clinic’s"); copy them exactly.
- Icons inside screens are mostly unnamed vector layers ("Frame"); component icons are named `icon/info`, `icon/alert`, `icon/sparkle`, `icon/shield`, `icon/link`, `icon/ban`, `icon/flask`. Export SVGs with `download_assets` when building; no icon assets were downloaded into this folder.
