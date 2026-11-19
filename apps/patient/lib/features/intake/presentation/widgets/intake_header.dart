import 'package:bloom_patient/app/view/widgets/bloom_wordmark.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// P02 header (Figma 6:41): brand, "Question n of about 10" and a 6 px
/// progress bar driven by the server's `progress`.
class IntakeHeader extends StatelessWidget {
  const new({required this.questionNumber, required this.progress, super.key});

  /// The server tracks about ten intake fields (server/app/graph.py
  /// PROGRESS_FIELDS), so about ten questions.
  static const estimatedQuestions = 10;

  final int questionNumber;

  /// 0-1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = questionNumber < 1 ? 1 : questionNumber;
    final total = current > estimatedQuestions ? current : estimatedQuestions;
    final value = progress.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: BloomSpacing.sm,
      children: [
        // Wraps the progress text under the brand when both do not fit on
        // one line (narrow phones, large text) instead of squeezing it into
        // a tall column.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: BloomSpacing.md,
          runSpacing: BloomSpacing.xs,
          children: [
            const BloomWordmark(),
            Text(
              l10n.patientChatProgress(current, total),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Semantics(
          label: l10n.patientChatProgressSemantics((value * 100).round()),
          excludeSemantics: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(BloomRadius.full),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: value),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                color: BloomColors.actionPrimary,
                backgroundColor: BloomColors.bgBrandMuted,
                borderRadius: BorderRadius.circular(BloomRadius.full),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
