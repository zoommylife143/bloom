import 'package:bloom_ui/src/tokens/bloom_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Figma component "QuickReply": a group of tappable reply chips under a
/// Bloom question.
class QuickReply extends StatelessWidget {
  const new({
    required this.options,
    required this.onSelected,
    this.enabled = true,
    this.semanticLabel = 'Quick replies',
    super.key,
  });

  final List<String> options;
  final ValueChanged<String> onSelected;
  final bool enabled;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Wrap(
        spacing: BloomSpacing.sm,
        runSpacing: BloomSpacing.sm,
        children: [
          for (final option in options)
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: BloomSpacing.minTapTarget,
                minWidth: BloomSpacing.minTapTarget,
              ),
              child: ActionChip(
                label: Text(option),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onPressed: enabled ? () => onSelected(option) : null,
              ),
            ),
        ],
      ),
    );
  }
}
