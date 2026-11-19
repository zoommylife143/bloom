import 'package:bloom_ui/bloom_ui.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// P04 Done (Figma 6:143). Terminal: no buttons, no clinical content, nothing
/// from the conversation.
class DonePage extends StatelessWidget {
  const new({super.key});

  /// Screen ID = Figma frame name = go_router route name.
  static const screenId = 'P04';

  /// Path inside the app. Public URL: `/intake/done` (base href
  /// `/intake/`).
  static const path = '/done';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BloomSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: BloomSpacing.lg,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: BloomColors.bgBrandMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 32,
                        color: BloomColors.textBrand,
                      ),
                    ),
                  ),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.patientDoneTitle,
                      style: theme.textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    l10n.patientDoneBody,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: BloomColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    l10n.patientDoneNote,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
