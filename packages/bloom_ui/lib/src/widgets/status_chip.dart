import 'package:bloom_ui/src/theme/bloom_tokens.dart';
import 'package:bloom_ui/src/tokens/bloom_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Session and brief states shown by [StatusChip].
enum BloomStatus { inProgress, redFlag, ready, approved, edited, rejected }

/// Figma component "StatusChip". Always icon plus text, never colour alone.
class StatusChip extends StatelessWidget {
  const new({required this.status, this.label, super.key});

  final BloomStatus status;

  /// Overrides the default English label.
  final String? label;

  static String defaultLabel(BloomStatus status) => switch (status) {
    BloomStatus.inProgress => 'In progress',
    BloomStatus.redFlag => 'Red flag',
    BloomStatus.ready => 'Ready',
    BloomStatus.approved => 'Approved',
    BloomStatus.edited => 'Edited',
    BloomStatus.rejected => 'Rejected',
  };

  static IconData iconFor(BloomStatus status) => switch (status) {
    BloomStatus.inProgress => Icons.schedule,
    BloomStatus.redFlag => Icons.error_outline,
    BloomStatus.ready => Icons.assignment_outlined,
    BloomStatus.approved => Icons.check_circle_outline,
    BloomStatus.edited => Icons.edit_outlined,
    BloomStatus.rejected => Icons.block,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = BloomTokens.of(context);
    final theme = Theme.of(context);
    final (Color bg, Color fg) = switch (status) {
      BloomStatus.inProgress => (tokens.brandSubtle, theme.colorScheme.primary),
      BloomStatus.redFlag => (tokens.criticalSubtle, tokens.critical),
      BloomStatus.ready => (tokens.warningSubtle, tokens.warning),
      BloomStatus.approved => (tokens.verifiedSubtle, tokens.verified),
      BloomStatus.edited => (tokens.verifiedSubtle, tokens.verified),
      BloomStatus.rejected => (
        theme.colorScheme.surfaceContainer,
        tokens.textSecondary,
      ),
    };
    final text = label ?? defaultLabel(status);

    return Semantics(
      label: 'Status: $text',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(BloomRadius.full),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BloomSpacing.sm,
            vertical: BloomSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconFor(status), size: 16, color: fg),
              const SizedBox(width: BloomSpacing.xs),
              Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
