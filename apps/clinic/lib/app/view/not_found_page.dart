import 'package:bloom_ui/bloom_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// go_router error page for unknown paths.
class NotFoundPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.notFoundTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: BloomSpacing.lg),
          BloomButton.secondary(
            label: 'Home',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
    ),
  );
}
