import 'package:bloom_ui/src/theme/bloom_tokens.dart';
import 'package:bloom_ui/src/tokens/bloom_colors.dart';
import 'package:bloom_ui/src/tokens/bloom_spacing.dart';
import 'package:bloom_ui/src/tokens/bloom_text_styles.dart';
import 'package:material_ui/material_ui.dart';

/// Material 3 themes for the two Bloom apps, built only from Bloom tokens.
abstract final class BloomTheme {
  /// Token mapping: primary = action/primary, error = status/critical,
  /// surface = bg/surface. `ColorScheme.background` is deprecated in M3, so
  /// bg/canvas goes to the scaffold and `surfaceContainerLow`.
  static const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: BloomColors.actionPrimary,
    onPrimary: BloomColors.textOnAction,
    primaryContainer: BloomColors.bgBrandMuted,
    onPrimaryContainer: BloomColors.textBrand,
    secondary: BloomColors.actionPrimary,
    onSecondary: BloomColors.textOnAction,
    secondaryContainer: BloomColors.bgBrandSubtle,
    onSecondaryContainer: BloomColors.textBrand,
    tertiary: BloomColors.statusVerified,
    onTertiary: BloomColors.textOnAction,
    tertiaryContainer: BloomColors.statusVerifiedSubtle,
    onTertiaryContainer: BloomColors.statusVerified,
    error: BloomColors.statusCritical,
    onError: BloomColors.textOnAction,
    errorContainer: BloomColors.statusCriticalSubtle,
    onErrorContainer: BloomColors.statusCritical,
    surface: BloomColors.bgSurface,
    onSurface: BloomColors.textPrimary,
    onSurfaceVariant: BloomColors.textSecondary,
    surfaceContainerLowest: BloomColors.bgSurface,
    surfaceContainerLow: BloomColors.bgCanvas,
    surfaceContainer: BloomColors.bgSubtle,
    surfaceContainerHigh: BloomColors.bgSubtle,
    surfaceContainerHighest: BloomColors.bgSubtle,
    outline: BloomColors.borderDefault,
    outlineVariant: BloomColors.borderDefault,
  );

  static const textTheme = TextTheme(
    displayLarge: BloomTextStyles.display,
    displayMedium: BloomTextStyles.display,
    displaySmall: BloomTextStyles.display,
    headlineLarge: BloomTextStyles.heading,
    headlineMedium: BloomTextStyles.heading,
    headlineSmall: BloomTextStyles.heading,
    titleLarge: BloomTextStyles.title,
    titleMedium: BloomTextStyles.title,
    titleSmall: BloomTextStyles.label,
    bodyLarge: BloomTextStyles.body,
    bodyMedium: BloomTextStyles.bodySmall,
    bodySmall: BloomTextStyles.caption,
    labelLarge: BloomTextStyles.label,
    labelMedium: BloomTextStyles.label,
    labelSmall: BloomTextStyles.overline,
  );

  /// Patient app (P screens): cards use radius lg.
  static ThemeData patient() => _build(BloomTokens.patient);

  /// Clinic app (D and S screens): cards use radius md.
  static ThemeData clinic() => _build(BloomTokens.clinic);

  static ThemeData _build(BloomTokens tokens) {
    const minSize = Size(BloomSpacing.minTapTarget, BloomSpacing.minTapTarget);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BloomRadius.full),
    );
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: BloomSpacing.xl,
      vertical: BloomSpacing.md,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: BloomTextStyles.dmSans,
      package: 'bloom_ui',
      scaffoldBackgroundColor: BloomColors.bgCanvas,
      canvasColor: BloomColors.bgCanvas,
      dividerColor: BloomColors.borderDefault,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [tokens],
      appBarTheme: const AppBarTheme(
        backgroundColor: BloomColors.bgCanvas,
        foregroundColor: BloomColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: BloomTextStyles.title,
      ),
      cardTheme: CardThemeData(
        color: BloomColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: const BorderSide(color: BloomColors.borderDefault),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: BloomColors.actionPrimary,
              foregroundColor: BloomColors.textOnAction,
              disabledBackgroundColor: BloomColors.bgSubtle,
              disabledForegroundColor: BloomColors.textSecondary,
              minimumSize: minSize,
              padding: buttonPadding,
              shape: buttonShape,
              textStyle: BloomTextStyles.label,
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(
                BloomColors.actionPrimaryPressed,
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BloomColors.textBrand,
          side: const BorderSide(color: BloomColors.borderBrand),
          minimumSize: minSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: BloomTextStyles.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BloomColors.textBrand,
          minimumSize: minSize,
          padding: const EdgeInsets.symmetric(horizontal: BloomSpacing.md),
          shape: buttonShape,
          textStyle: BloomTextStyles.label,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BloomColors.bgSurface,
        selectedColor: BloomColors.bgBrandMuted,
        side: const BorderSide(color: BloomColors.borderBrand),
        labelStyle: BloomTextStyles.label.copyWith(
          color: BloomColors.textBrand,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BloomRadius.full),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: BloomSpacing.md,
          vertical: BloomSpacing.sm,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BloomColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          borderSide: const BorderSide(color: BloomColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          borderSide: const BorderSide(color: BloomColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          borderSide: const BorderSide(
            color: BloomColors.borderBrand,
            width: 2,
          ),
        ),
      ),
    );
  }
}
