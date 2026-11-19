import 'package:bloom_patient/app/view/widgets/patient_button.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:material_ui/material_ui.dart';

/// P02 refused card (Figma 6:104, reused for model error 23:86):
/// critical-subtle bg, critical border, ban icon + Title, Body Small, and a
/// Secondary button. Announced to screen readers when it appears.
class IntakeErrorCard extends StatelessWidget {
  const new({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(BloomSpacing.lg),
        decoration: BoxDecoration(
          color: BloomColors.statusCriticalSubtle,
          border: Border.all(color: BloomColors.statusCritical),
          borderRadius: BorderRadius.circular(BloomRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: BloomSpacing.md,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: BloomSpacing.sm,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.block,
                    size: 20,
                    color: BloomColors.statusCritical,
                  ),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: BloomColors.statusCritical,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(body, style: theme.textTheme.bodyMedium),
            PatientButton(
              label: actionLabel,
              style: PatientButtonStyle.secondary,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }
}
