import 'package:material_ui/material_ui.dart';

/// Colour tokens from docs/design-tokens.json (Figma variables). Use these
/// values exactly; change Figma first, then the tokens file, then this file.
abstract final class BloomColors {
  static const bgCanvas = Color(0xFFFBF8F4);
  static const bgSurface = Color(0xFFFFFFFF);
  static const bgSubtle = Color(0xFFF3EEE7);
  static const bgBrandSubtle = Color(0xFFFAF4F8);
  static const bgBrandMuted = Color(0xFFF3E6EF);

  static const actionPrimary = Color(0xFF6B2D5C);

  /// Pressed state of [actionPrimary].
  // TODO(figma): TODO-Figma, action/primary-pressed is not defined in Figma
  // yet. Derived as about 12% darker than actionPrimary (design-tokens.json).
  static const actionPrimaryPressed = Color(0xFF5E2851);

  static const textPrimary = Color(0xFF1F1A1D);
  static const textSecondary = Color(0xFF5E5560);
  static const textOnAction = Color(0xFFFFFFFF);
  static const textBrand = Color(0xFF6B2D5C);

  static const borderDefault = Color(0xFFDCD3C8);
  static const borderBrand = Color(0xFF6B2D5C);

  static const statusCritical = Color(0xFFB42318);
  static const statusCriticalSubtle = Color(0xFFFEF3F2);
  static const statusVerified = Color(0xFF2F6B52);
  static const statusVerifiedSubtle = Color(0xFFE3F0E8);
  static const statusWarning = Color(0xFFB54708);
  static const statusWarningSubtle = Color(0xFFFFFAEB);
}
