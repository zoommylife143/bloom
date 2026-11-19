import 'package:bloom_ui/bloom_ui.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Temporary page for a screen that is not built yet. Shows the screen ID
/// (= Figma frame name = go_router route name) so routing can be checked.
class ScreenPlaceholder extends StatelessWidget {
  const new({
    required this.screenId,
    required this.title,
    this.detail,
    super.key,
  });

  final String screenId;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('$screenId $title')),
      body: ListView(
        padding: const EdgeInsets.all(BloomSpacing.xl),
        children: [
          Text(screenId, style: theme.textTheme.displaySmall),
          const SizedBox(height: BloomSpacing.sm),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: BloomSpacing.lg),
          Text(
            context.l10n.placeholderBody(screenId),
            style: theme.textTheme.bodyLarge,
          ),
          if (detail case final detail?) ...[
            const SizedBox(height: BloomSpacing.sm),
            Text(detail, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
