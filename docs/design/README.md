# Bloom design handoff

Figma is the source of truth. This folder is a snapshot for development, exported 2026-11-19.

- `tokens.json`: colors (primitives and semantic), spacing, radius, text styles, and the component list with Figma node IDs.
- `screens/`: PNG exports of each frame. **Empty for now.** Add them by hand: in Figma, select the frames, then Export, PNG 1x. Name them like `P02-intake-chat--waiting.png`.
- `bloom.fig`: optional. In Figma, use File → Save local copy, and commit it here if you want an offline copy.

## Frames
Base URL: `https://www.figma.com/design/0lWIv5IY18QemXtzP3YaTE?node-id=`

| Screen | Frame | Link suffix |
| --- | --- | --- |
| A01 Sign in | default / invalid code / phone | `26-3` / `26-38` / `26-74` |
| P01 Welcome + consent | default / loading | `6-2` / `23-33` |
| P02 Intake chat | default / waiting / route refused / model error / tablet | `6-40` / `10-23` / `6-87` / `23-71` / `23-108` |
| P03 Urgent care | default | `6-125` |
| P04 Done | default | `6-143` |
| D01 Patient queue | default / empty / loading | `7-2` / `11-362` / `25-198` |
| D02 Physician brief | default / generating / approved / edited / rejected / no guideline / tablet | `7-139` / `25-281` / `11-128` / `25-401` / `25-497` / `11-252` / `25-622` |
| D03 Privacy & Trust panel | row states | `7-261` |
| D04 Audit log | default | `7-310` |
| D05 Demo scenarios | default | `7-428` |
| D06 Red-flag summary | default | `25-722` |
| S01 Privacy & data settings | default | `27-3` |
| Flows | screen map | `28-3` |
| Foundations | specimen | `13-2` |
| Components | page | `1-3` |

## Using it in code
- `packages/bloom_ui` maps `tokens.json` to a Material 3 `ColorScheme`, a `TextTheme` (Fraunces and DM Sans from Google Fonts) and a `ThemeExtension` for the status colors and spacing.
- Widgets take their styling from the theme. No hex values or raw spacing numbers go in widgets.
- One widget per Figma component, with the same name and variants.
- Before building a screen, open its frame from the table above. After building, compare a screenshot of the running app with the frame.
- If the design changes, change Figma first, then re-export `tokens.json`.
