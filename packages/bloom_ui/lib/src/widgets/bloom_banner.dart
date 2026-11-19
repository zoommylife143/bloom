import 'package:bloom_ui/src/theme/bloom_tokens.dart';
import 'package:bloom_ui/src/tokens/bloom_spacing.dart';
import 'package:material_ui/material_ui.dart';

enum BloomBannerVariant { info, warning, critical, verified }

/// Figma component "Banner": an icon, an optional title, a message and an
/// optional action. Critical banners are announced as a live region.
class BloomBanner extends StatelessWidget {
  const new({
    required this.message,
    this.variant = BloomBannerVariant.info,
    this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// The demo banner shown on every patient screen.
  const new demo({
    this.message = 'Demo only. Do not enter real health information.',
    super.key,
  }) : variant = BloomBannerVariant.warning,
       title = null,
       actionLabel = null,
       onAction = null;

  /// Private mode refused the request (HTTP 502). Wording is literal: there
  /// was no inference and no fallback.
  const new routeRefused({
    this.message =
        'Request refused before inference: no route met the confidential '
        'privacy floor. No fallback model was called.',
    this.title = 'Route refused',
    this.actionLabel,
    this.onAction,
    super.key,
  }) : variant = BloomBannerVariant.critical;

  /// The model call failed for another reason.
  const new modelError({
    this.message = 'Bloom could not reply just now. Please try again.',
    this.title,
    this.actionLabel = 'Try again',
    this.onAction,
    super.key,
  }) : variant = BloomBannerVariant.warning;

  final String message;
  final BloomBannerVariant variant;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  static IconData iconFor(BloomBannerVariant variant) => switch (variant) {
    BloomBannerVariant.info => Icons.info_outline,
    BloomBannerVariant.warning => Icons.warning_amber_outlined,
    BloomBannerVariant.critical => Icons.error_outline,
    BloomBannerVariant.verified => Icons.verified_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = BloomTokens.of(context);
    final (Color bg, Color fg) = switch (variant) {
      BloomBannerVariant.info => (
        tokens.brandSubtle,
        theme.colorScheme.primary,
      ),
      BloomBannerVariant.warning => (tokens.warningSubtle, tokens.warning),
      BloomBannerVariant.critical => (tokens.criticalSubtle, tokens.critical),
      BloomBannerVariant.verified => (tokens.verifiedSubtle, tokens.verified),
    };
    final action = actionLabel;

    return Semantics(
      container: true,
      liveRegion: variant == BloomBannerVariant.critical,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: fg.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(tokens.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(BloomSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconFor(variant), color: fg, size: 20),
              const SizedBox(width: BloomSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title case final title?)
                      Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(color: fg),
                      ),
                    Text(message, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              if (action != null && onAction != null) ...[
                const SizedBox(width: BloomSpacing.sm),
                TextButton(onPressed: onAction, child: Text(action)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
