# Agent 04: Flutter workspace and bloom_ui (build steps 1 and 3)

## Goal
Create the Flutter Web workspace from ADR 0003 and build `packages/bloom_ui` (tokens, ThemeData and the 8 Figma components) so the patient and clinic screens can be built on it.

## Read first
- `CLAUDE.md`, `docs/agent-prompts/README.md`, `docs/adr/0003-continuum-style-structure.md`, `docs/02-app-flow.md`
- `docs/design-tokens.json`: every colour, spacing, radius and text style value, read from Figma. Use these values exactly.
- Flutter SDK: `~/flutter-sdk/bin/flutter` (3.50.0 stable, web enabled). `dart`, `melos` and `very_good` are in `~/flutter-sdk/bin` and `~/.pub-cache/bin`. Export `PATH="$HOME/flutter-sdk/bin:$HOME/.pub-cache/bin:$PATH"` in every shell command.

## Build
1. Workspace (Dart pub workspaces with melos, or melos alone if simpler):
   - `apps/patient` and `apps/clinic` (web only: `flutter create --platforms web --org com.zoommylife.bloom`).
   - `packages/bloom_ui`, `packages/core_domain` (pure Dart), `packages/core_data`, `packages/l10n` (ARB, `en` only).
   - Deps: flutter_bloc, bloc, go_router, equatable, freezed + freezed_annotation + json_serializable + build_runner (sealed states and DTOs), http or dio for `core_data`, google_fonts (Fraunces, DM Sans), bloc_test, mocktail, very_good_analysis.
   - `analysis_options.yaml` with very_good_analysis in every package (relax only rules that block progress, listed in a comment).
2. `bloom_ui`
   - `BloomColors`, `BloomSpacing`, `BloomRadius`, `BloomTextStyles` as constants from the tokens file.
   - `BloomTheme.patient()` and `BloomTheme.clinic()` returning Material 3 `ThemeData`: map tokens into a `ColorScheme` (primary = action/primary, error = status/critical, surface = bg/surface, background = bg/canvas), plus a `ThemeExtension<BloomTokens>` carrying the status colours (verified, warning, critical and their subtle variants) that M3 has no slot for. Patient cards use radius lg; clinic cards use radius md.
   - Components (one widget each, all styling from the theme, semantic labels, 44 px minimum tap targets):
     - `BloomButton` (primary, secondary, text; loading state)
     - `StatusChip` (in progress, red flag, ready, approved, edited, rejected; icon plus text, never colour alone)
     - `ChatBubble` (patient vs Bloom; optional "Optional question" marker)
     - `QuickReply` (chip group of replies)
     - `BloomBanner` (info, warning, critical, verified; for the demo banner "Do not enter real health information", route refused, model error)
     - `CitationLink` (title and host; opens URL; "No guideline retrieved" variant)
     - `TrustRow` (label, value, status: verified / not exposed / refused / dev warning; literal wording, e.g. "Evidence not exposed by provider", never "Secure")
     - `DecisionBar` (Confirm / Edit / Reject; disabled after a decision; shows "Draft, needs your review" until decided)
   - A `bloom_ui` widgetbook is NOT needed. A simple gallery page in `apps/clinic` at route `/dev/gallery` is enough for visual checks.
3. `core_domain`: `AppFailure` sealed class (network, server, routeRefused, locked, notFound), and entities mirroring `server/app/models.py` that the UI needs: `SessionSummary`, `SessionStatus`, `IntakeTurn`, `Brief`, `ScreeningLine`, `Provenance`, `TrustEvent`, `RedFlagRule`, `UrgentMessage`.
4. `core_data`: `BloomApiClient` (base URL from `--dart-define=API_BASE_URL`, default `/api`) with method stubs for the plan §6 endpoints, returning `Result`-style values (no exceptions into blocs). Map HTTP 502 `confidential_route_unavailable` to `AppFailure.routeRefused` and 409 to `AppFailure.locked`. Repositories: `IntakeRepository`, `BriefRepository`, `TrustRepository`, `SessionRepository`.
5. Both apps: `MaterialApp.router` with go_router, the right theme, routes named by screen ID (`P01`, `P02`… / `D01`, `D02`…) with placeholder pages for now; route paths from `docs/02-app-flow.md`. Each app builds with `flutter build web --base-href /intake/` (patient) and `/doctor/` (clinic).

## Tests
- Widget tests for each bloom_ui component (renders, semantic label present, tap target ≥ 44 px, DecisionBar disables after a decision, StatusChip shows icon and text).
- A theme test asserting ColorScheme.primary == #6b2d5c and the status extension values.
- `core_data` tests with a mocked HTTP client for the 502 → routeRefused and 409 → locked mapping.

## Done when
From the repo root, for each package and app: `flutter analyze` is clean and `flutter test` passes; `flutter build web` succeeds for both apps. Report per the README format, with the exact commands you ran and the workspace layout.
