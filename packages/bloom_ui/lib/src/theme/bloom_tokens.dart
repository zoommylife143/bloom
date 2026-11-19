import 'dart:ui' show lerpDouble;

import 'package:bloom_ui/src/tokens/bloom_colors.dart';
import 'package:bloom_ui/src/tokens/bloom_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Bloom values Material 3 has no slot for: status colours and their subtle
/// variants, brand tints, and the card radius for the current app.
///
/// Read with `BloomTokens.of(context)`.
@immutable
class BloomTokens extends ThemeExtension<BloomTokens> {
  const new({
    required this.verified,
    required this.verifiedSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.critical,
    required this.criticalSubtle,
    required this.brandSubtle,
    required this.brandMuted,
    required this.border,
    required this.textSecondary,
    required this.cardRadius,
  });

  /// Patient app: cards use radius lg.
  static const patient = BloomTokens(
    verified: BloomColors.statusVerified,
    verifiedSubtle: BloomColors.statusVerifiedSubtle,
    warning: BloomColors.statusWarning,
    warningSubtle: BloomColors.statusWarningSubtle,
    critical: BloomColors.statusCritical,
    criticalSubtle: BloomColors.statusCriticalSubtle,
    brandSubtle: BloomColors.bgBrandSubtle,
    brandMuted: BloomColors.bgBrandMuted,
    border: BloomColors.borderDefault,
    textSecondary: BloomColors.textSecondary,
    cardRadius: BloomRadius.lg,
  );

  /// Clinic app: cards use radius md.
  static const clinic = BloomTokens(
    verified: BloomColors.statusVerified,
    verifiedSubtle: BloomColors.statusVerifiedSubtle,
    warning: BloomColors.statusWarning,
    warningSubtle: BloomColors.statusWarningSubtle,
    critical: BloomColors.statusCritical,
    criticalSubtle: BloomColors.statusCriticalSubtle,
    brandSubtle: BloomColors.bgBrandSubtle,
    brandMuted: BloomColors.bgBrandMuted,
    border: BloomColors.borderDefault,
    textSecondary: BloomColors.textSecondary,
    cardRadius: BloomRadius.md,
  );

  final Color verified;
  final Color verifiedSubtle;
  final Color warning;
  final Color warningSubtle;
  final Color critical;
  final Color criticalSubtle;
  final Color brandSubtle;
  final Color brandMuted;
  final Color border;
  final Color textSecondary;
  final double cardRadius;

  /// The tokens of the nearest theme, or [patient] if the theme has none.
  static BloomTokens of(BuildContext context) =>
      Theme.of(context).extension<BloomTokens>() ?? patient;

  @override
  BloomTokens copyWith({
    Color? verified,
    Color? verifiedSubtle,
    Color? warning,
    Color? warningSubtle,
    Color? critical,
    Color? criticalSubtle,
    Color? brandSubtle,
    Color? brandMuted,
    Color? border,
    Color? textSecondary,
    double? cardRadius,
  }) => BloomTokens(
    verified: verified ?? this.verified,
    verifiedSubtle: verifiedSubtle ?? this.verifiedSubtle,
    warning: warning ?? this.warning,
    warningSubtle: warningSubtle ?? this.warningSubtle,
    critical: critical ?? this.critical,
    criticalSubtle: criticalSubtle ?? this.criticalSubtle,
    brandSubtle: brandSubtle ?? this.brandSubtle,
    brandMuted: brandMuted ?? this.brandMuted,
    border: border ?? this.border,
    textSecondary: textSecondary ?? this.textSecondary,
    cardRadius: cardRadius ?? this.cardRadius,
  );

  @override
  BloomTokens lerp(BloomTokens? other, double t) {
    if (other == null) return this;
    return BloomTokens(
      verified: Color.lerp(verified, other.verified, t)!,
      verifiedSubtle: Color.lerp(verifiedSubtle, other.verifiedSubtle, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      criticalSubtle: Color.lerp(criticalSubtle, other.criticalSubtle, t)!,
      brandSubtle: Color.lerp(brandSubtle, other.brandSubtle, t)!,
      brandMuted: Color.lerp(brandMuted, other.brandMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
    );
  }
}
