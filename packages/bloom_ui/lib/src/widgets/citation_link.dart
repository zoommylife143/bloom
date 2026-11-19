import 'package:bloom_ui/src/theme/bloom_tokens.dart';
import 'package:bloom_ui/src/tokens/bloom_spacing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Figma component "CitationLink": a guideline title and its host; tapping
/// opens the URL in a new tab. [CitationLink.none] is the "No guideline
/// retrieved" variant.
class CitationLink extends StatelessWidget {
  const new({
    required this.title,
    required String this.url,
    this.onOpen,
    super.key,
  }) : noneLabel = 'No guideline retrieved';

  const new none({this.noneLabel = 'No guideline retrieved', super.key})
    : title = null,
      url = null,
      onOpen = null;

  final String? title;
  final String? url;
  final String noneLabel;

  /// Overrides the default `launchUrl`, e.g. in tests.
  final ValueChanged<Uri>? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = BloomTokens.of(context);
    final link = url == null ? null : Uri.tryParse(url!);

    if (link == null) {
      return Semantics(
        label: noneLabel,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, size: 16, color: tokens.textSecondary),
            const SizedBox(width: BloomSpacing.xs),
            Flexible(
              child: Text(
                noneLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final host = link.host.replaceFirst(RegExp(r'^www\.'), '');
    final name = (title == null || title!.isEmpty) ? host : title!;

    return Semantics(
      link: true,
      label: 'Source: $name, $host',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(BloomSpacing.xs),
        onTap: () => _open(link),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: BloomSpacing.minTapTarget,
            minWidth: BloomSpacing.minTapTarget,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.open_in_new,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: BloomSpacing.xs),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: name,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(
                        text: '  $host',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(Uri link) {
    final handler = onOpen;
    if (handler != null) {
      handler(link);
    } else {
      launchUrl(link, webOnlyWindowName: '_blank').ignore();
    }
  }
}
