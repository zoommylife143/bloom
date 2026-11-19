import 'package:bloom_ui/src/theme/bloom_tokens.dart';
import 'package:bloom_ui/src/tokens/bloom_spacing.dart';
import 'package:material_ui/material_ui.dart';

enum TrustRowStatus { verified, notExposed, refused, devWarning }

/// Figma component "TrustRow" (D03): a label, a value and a status in
/// literal wording. Never says "Secure"; a missing receipt is "Evidence not
/// exposed by provider".
class TrustRow extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.status,
    this.statusText,
    super.key,
  });

  final String label;
  final String value;
  final TrustRowStatus status;

  /// Overrides the default wording for [status].
  final String? statusText;

  static String defaultStatusText(TrustRowStatus status) => switch (status) {
    TrustRowStatus.verified => 'Verified',
    TrustRowStatus.notExposed => 'Evidence not exposed by provider',
    TrustRowStatus.refused => 'Refused before inference',
    TrustRowStatus.devWarning => 'Dev mode: not a confidential route',
  };

  static IconData iconFor(TrustRowStatus status) => switch (status) {
    TrustRowStatus.verified => Icons.verified_outlined,
    TrustRowStatus.notExposed => Icons.visibility_off_outlined,
    TrustRowStatus.refused => Icons.block,
    TrustRowStatus.devWarning => Icons.warning_amber_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = BloomTokens.of(context);
    final color = switch (status) {
      TrustRowStatus.verified => tokens.verified,
      TrustRowStatus.notExposed => tokens.textSecondary,
      TrustRowStatus.refused => tokens.critical,
      TrustRowStatus.devWarning => tokens.warning,
    };
    final wording = statusText ?? defaultStatusText(status);

    return Semantics(
      label: '$label: $value. $wording',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BloomSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
                const SizedBox(width: BloomSpacing.md),
                Flexible(
                  flex: 2,
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BloomSpacing.xs),
            Row(
              children: [
                Icon(iconFor(status), size: 16, color: color),
                const SizedBox(width: BloomSpacing.xs),
                Flexible(
                  child: Text(
                    wording,
                    style: theme.textTheme.bodySmall?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
