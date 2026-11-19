import 'package:bloom_ui/bloom_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Figma Button styles used on the patient screens.
enum PatientButtonStyle {
  /// `style=Primary`: main action per screen.
  primary,

  /// `style=Secondary`: surface bg, default border, primary text.
  secondary,

  /// `style=Critical`: urgent-care actions only (P03).
  critical,

  /// `style=Ghost`: brand text, no background.
  ghost,
}

/// A Figma Button at the 44 px tap target. Figma has no disabled or loading
/// variant; P01 loading draws Primary at 60 % opacity, so a disabled button
/// keeps its colours and fades to 60 %.
class PatientButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.style = PatientButtonStyle.primary,
    this.expand = false,
    this.semanticLabel,
    this.semanticHint,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final PatientButtonStyle style;
  final bool expand;
  final String? semanticLabel;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, BorderSide side) = switch (style) {
      PatientButtonStyle.primary => (
        BloomColors.actionPrimary,
        BloomColors.textOnAction,
        BorderSide.none,
      ),
      PatientButtonStyle.secondary => (
        BloomColors.bgSurface,
        BloomColors.textPrimary,
        const BorderSide(color: BloomColors.borderDefault),
      ),
      PatientButtonStyle.critical => (
        BloomColors.statusCritical,
        BloomColors.textOnAction,
        BorderSide.none,
      ),
      PatientButtonStyle.ghost => (
        Colors.transparent,
        BloomColors.textBrand,
        BorderSide.none,
      ),
    };
    final enabled = onPressed != null;
    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(bg),
      foregroundColor: WidgetStatePropertyAll(fg),
      overlayColor: WidgetStatePropertyAll(fg.withValues(alpha: 0.08)),
      side: WidgetStatePropertyAll(side),
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(
        Size(BloomSpacing.minTapTarget, BloomSpacing.minTapTarget),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: BloomSpacing.xl,
          vertical: BloomSpacing.md,
        ),
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: const WidgetStatePropertyAll(BloomTextStyles.label),
    );

    final button = TextButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: Text(label, textAlign: TextAlign.center),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      hint: semanticHint,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: expand
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}
