import 'package:bloom_ui/src/tokens/bloom_spacing.dart';
import 'package:material_ui/material_ui.dart';

enum BloomButtonVariant { primary, secondary, text }

/// Figma component "Button": primary (filled), secondary (outlined) or text.
/// While [isLoading] it shows a spinner, ignores taps and announces
/// "loading". Styling comes from the theme.
class BloomButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.variant = BloomButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.semanticLabel,
    super.key,
  });

  const new secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.semanticLabel,
    super.key,
  }) : variant = BloomButtonVariant.secondary;

  const new text({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.semanticLabel,
    super.key,
  }) : variant = BloomButtonVariant.text;

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final BloomButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Fill the available width (phone layouts).
  final bool expand;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final spinnerColor = variant == BloomButtonVariant.primary
        ? colors.onPrimary
        : colors.primary;
    final onTap = isLoading ? null : onPressed;

    final child = isLoading
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spinnerColor,
            ),
          )
        : Text(label);
    final leading = isLoading || icon == null ? null : Icon(icon, size: 18);

    final Widget button = switch (variant) {
      BloomButtonVariant.primary =>
        leading == null
            ? FilledButton(onPressed: onTap, child: child)
            : FilledButton.icon(onPressed: onTap, icon: leading, label: child),
      BloomButtonVariant.secondary =>
        leading == null
            ? OutlinedButton(onPressed: onTap, child: child)
            : OutlinedButton.icon(
                onPressed: onTap,
                icon: leading,
                label: child,
              ),
      BloomButtonVariant.text =>
        leading == null
            ? TextButton(onPressed: onTap, child: child)
            : TextButton.icon(onPressed: onTap, icon: leading, label: child),
    };

    final name = semanticLabel ?? label;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: isLoading ? '$name, loading' : name,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: BloomSpacing.minTapTarget,
          minWidth: BloomSpacing.minTapTarget,
        ),
        child: expand
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}
