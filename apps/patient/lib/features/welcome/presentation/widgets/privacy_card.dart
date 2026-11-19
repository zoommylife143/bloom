import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// P01 privacy card (Figma 6:16). Literal wording: the first point says
/// "confidential" only when the server reports private mode; otherwise it
/// describes the zero-data-retention route.
class PrivacyCard extends StatelessWidget {
  const new({required this.mode, super.key});

  /// From `GET /healthz`; null if unknown.
  final RouteMode? mode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BloomSpacing.lg),
      decoration: BoxDecoration(
        color: BloomColors.bgSurface,
        border: Border.all(color: BloomColors.borderDefault),
        borderRadius: BorderRadius.circular(BloomRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: BloomSpacing.md,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.patientWelcomePrivacyTitle,
              style: theme.textTheme.titleLarge,
            ),
          ),
          _Point(
            icon: Icons.lock_outline,
            text: mode == RouteMode.private
                ? l10n.patientWelcomePrivacyRoutePrivate
                : l10n.patientWelcomePrivacyRouteDev,
          ),
          _Point(
            icon: Icons.verified_user_outlined,
            text: l10n.patientWelcomePrivacySearch,
          ),
          // TODO(figma): Figma uses a stethoscope icon (6:28); Material has
          // none.
          _Point(
            icon: Icons.medical_services_outlined,
            text: l10n.patientWelcomePrivacyReview,
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: BloomSpacing.md,
    children: [
      ExcludeSemantics(
        child: Icon(icon, size: 20, color: BloomColors.textBrand),
      ),
      Expanded(
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}
