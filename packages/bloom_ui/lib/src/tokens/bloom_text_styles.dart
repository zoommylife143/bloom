import 'package:bloom_ui/src/tokens/bloom_colors.dart';
import 'package:material_ui/material_ui.dart';

/// Text styles from docs/design-tokens.json. Fonts are bundled in this
/// package (SIL OFL), so no font CDN is contacted at runtime.
abstract final class BloomTextStyles {
  static const _package = 'bloom_ui';
  static const fraunces = 'Fraunces';
  static const dmSans = 'DM Sans';

  static const display = TextStyle(
    fontFamily: fraunces,
    package: _package,
    fontWeight: FontWeight.w600,
    fontSize: 32,
    height: 40 / 32,
    letterSpacing: 0,
    color: BloomColors.textPrimary,
  );

  static const heading = TextStyle(
    fontFamily: fraunces,
    package: _package,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 32 / 24,
    letterSpacing: 0,
    color: BloomColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: dmSans,
    package: _package,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 26 / 18,
    letterSpacing: 0,
    color: BloomColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: dmSans,
    package: _package,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0,
    color: BloomColors.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontFamily: dmSans,
    package: _package,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    color: BloomColors.textPrimary,
  );

  static const label = TextStyle(
    fontFamily: dmSans,
    package: _package,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    color: BloomColors.textPrimary,
  );

  static const caption = TextStyle(
    fontFamily: dmSans,
    package: _package,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    color: BloomColors.textSecondary,
  );

  /// Overline: uppercase labels.
  // TODO(figma): TODO-Figma, letterSpacing 6 is read as 6% (0.72 px at
  // 12 px); confirm in Figma.
  static const overline = TextStyle(
    fontFamily: dmSans,
    package: _package,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.72,
    color: BloomColors.textSecondary,
  );
}
