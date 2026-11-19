import 'package:bloom_ui/bloom_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Patient screens are drawn at 390 wide (phone) with 24 px side padding.
/// On tablets and desktop the content stays a centered 480 px column
/// (Figma P02 tablet 23:108: 768 wide, 144 side padding).
class ContentColumn extends StatelessWidget {
  const new({required this.child, this.padding, super.key});

  static const maxWidth = 480.0;

  final Widget child;

  /// Defaults to `spacing/xl` 24 on every side.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: maxWidth + 2 * BloomSpacing.xl,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(BloomSpacing.xl),
        child: child,
      ),
    ),
  );
}
