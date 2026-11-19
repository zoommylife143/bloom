import 'package:bloom_ui/src/theme/bloom_tokens.dart';
import 'package:bloom_ui/src/tokens/bloom_spacing.dart';
import 'package:bloom_ui/src/widgets/bloom_button.dart';
import 'package:bloom_ui/src/widgets/status_chip.dart';
import 'package:material_ui/material_ui.dart';

/// A physician's decision on an AI draft.
enum BloomDecision { confirmed, edited, rejected }

/// Figma component "DecisionBar": Confirm / Edit / Reject for every AI draft.
///
/// Controlled by the caller's bloc: pass [decision] once one is stored. Until
/// then it shows "Draft, needs your review"; afterwards the buttons are
/// disabled and the decision shows as a [StatusChip]. [isBusy] disables the
/// buttons while a decision is being saved.
class DecisionBar extends StatelessWidget {
  const new({
    required this.onConfirm,
    required this.onEdit,
    required this.onReject,
    this.decision,
    this.isBusy = false,
    this.draftLabel = 'Draft, needs your review',
    super.key,
  });

  final BloomDecision? decision;
  final bool isBusy;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onReject;
  final String draftLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = BloomTokens.of(context);
    final enabled = decision == null && !isBusy;

    final state = switch (decision) {
      null => Semantics(
        container: true,
        label: draftLabel,
        liveRegion: true,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note, size: 20, color: tokens.warning),
            const SizedBox(width: BloomSpacing.xs),
            Flexible(
              child: Text(
                draftLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: tokens.warning,
                ),
              ),
            ),
          ],
        ),
      ),
      BloomDecision.confirmed => const StatusChip(status: BloomStatus.approved),
      BloomDecision.edited => const StatusChip(status: BloomStatus.edited),
      BloomDecision.rejected => const StatusChip(status: BloomStatus.rejected),
    };

    return Semantics(
      container: true,
      label: 'Review decision',
      child: Wrap(
        spacing: BloomSpacing.sm,
        runSpacing: BloomSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          state,
          BloomButton(
            label: 'Confirm',
            icon: Icons.check,
            onPressed: enabled ? onConfirm : null,
            isLoading: isBusy,
          ),
          BloomButton.secondary(
            label: 'Edit',
            icon: Icons.edit_outlined,
            onPressed: enabled ? onEdit : null,
          ),
          BloomButton.text(
            label: 'Reject',
            icon: Icons.close,
            onPressed: enabled ? onReject : null,
          ),
        ],
      ),
    );
  }
}
