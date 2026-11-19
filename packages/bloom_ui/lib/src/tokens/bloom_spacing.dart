/// Spacing tokens (px) from docs/design-tokens.json.
abstract final class BloomSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Minimum tap target for every interactive component.
  static const double minTapTarget = 44;
}

/// Corner radius tokens (px) from docs/design-tokens.json. Patient cards use
/// [lg]; clinic cards use [md].
abstract final class BloomRadius {
  static const double md = 12;
  static const double lg = 16;
  static const double full = 999;
}
