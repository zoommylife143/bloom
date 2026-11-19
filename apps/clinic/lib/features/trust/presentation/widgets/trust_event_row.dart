import 'package:bloom_clinic/app/formatting.dart';
import 'package:bloom_clinic/features/trust/domain/trust_view.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Figma "TrustRow" (component 4:105) for one external call: call name and
/// mode, an outcome tag, then route, policy and model, evidence, request ID
/// and latency. Shows only fields the provider returned; never invents a
/// badge. Wording carries the meaning, not colour alone ("Evidence not
/// exposed by provider").
class TrustEventRow extends StatelessWidget {
  const new({required this.event, super.key});

  final TrustEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = BloomTokens.of(context);
    final e = event;
    final variant = trustVariantOf(e);

    final (
      Color bg,
      IconData icon,
      Color iconColor,
      String tag,
      Color tagColor,
    ) = switch (variant) {
      TrustVariant.verified => (
        BloomColors.bgSurface,
        Icons.verified_user_outlined,
        tokens.verified,
        l10n.clinicTrustTagOk,
        tokens.verified,
      ),
      TrustVariant.notExposed => (
        BloomColors.bgSurface,
        Icons.info_outline,
        tokens.textSecondary,
        l10n.clinicTrustTagOk,
        tokens.textSecondary,
      ),
      TrustVariant.refused => (
        tokens.criticalSubtle,
        Icons.block,
        tokens.critical,
        l10n.clinicTrustTagRefused,
        tokens.critical,
      ),
      TrustVariant.error => (
        tokens.criticalSubtle,
        Icons.error_outline,
        tokens.critical,
        l10n.clinicTrustTagError,
        tokens.critical,
      ),
      TrustVariant.dev => (
        tokens.warningSubtle,
        Icons.science_outlined,
        tokens.warning,
        l10n.clinicTrustTagDev,
        tokens.warning,
      ),
      TrustVariant.noModelCall => (
        BloomColors.bgSurface,
        Icons.rule,
        tokens.textSecondary,
        l10n.clinicTrustTagFallback,
        tokens.textSecondary,
      ),
    };

    final mode = e.mode == RouteMode.private
        ? l10n.clinicTrustModePrivate
        : l10n.clinicTrustModeDev;
    final noModelCall = variant == TrustVariant.noModelCall;
    final model = noModelCall
        ? l10n.clinicTrustNoModelCall
        : e.modelId ?? l10n.clinicTrustNoModel;
    final route = switch (e.policyRequired) {
      _ when variant == TrustVariant.refused => l10n.clinicTrustRouteNone,
      _ when noModelCall => l10n.clinicTrustRouteNoModelCall,
      'zdr' => l10n.clinicTrustRouteZdr(e.route ?? model),
      'confidential' =>
        e.route == null
            ? l10n.clinicTrustRouteConfidential
            : l10n.clinicTrustRouteConfidentialVia(e.route!),
      _ => l10n.clinicTrustRouteOther(e.route ?? e.policyRequired),
    };
    final receipt = receiptOf(e);
    final evidence = receipt == null
        ? l10n.clinicTrustEvidenceNotExposed
        : l10n.clinicTrustEvidenceReceipt;
    final lines = <String>[
      route,
      l10n.clinicTrustPolicyModel(e.policyRequired, model),
      ...switch (variant) {
        TrustVariant.refused => [l10n.clinicTrustRefusedLine],
        TrustVariant.error => [
          if (servedWhenShouldRefuse(e))
            l10n.clinicTrustServedWhenShouldRefuse
          else
            l10n.clinicTrustErrorLine(
              errorLabelOf(e) ?? l10n.clinicTrustUnknownError,
            ),
        ],
        TrustVariant.dev => [l10n.clinicTrustDevLine, evidence],
        TrustVariant.verified || TrustVariant.notExposed => [evidence],
        TrustVariant.noModelCall => [
          if (e.node == TrustNodes.intakeFallback)
            l10n.clinicTrustFallbackIntake
          else
            l10n.clinicTrustFallbackBrief,
          if (fallbackAfterErrorOf(e) case final error?)
            l10n.clinicTrustFallbackAfter(error),
        ],
      },
      l10n.clinicTrustRequestLine(
        e.requestId ?? l10n.clinicTrustNotReturned,
        e.latencyMs == null
            ? l10n.clinicTrustNotReturned
            : formatLatency(e.latencyMs!),
      ),
    ];
    final title = '${e.node} · $mode';

    return Semantics(
      container: true,
      label: '$title. $tag. ${lines.join('. ')}',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: BloomSpacing.lg,
          vertical: BloomSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: BloomColors.borderDefault),
          borderRadius: BorderRadius.circular(BloomRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: BloomSpacing.sm),
                Expanded(child: Text(title, style: BloomTextStyles.label)),
                const SizedBox(width: BloomSpacing.sm),
                Text(
                  tag,
                  style: BloomTextStyles.overline.copyWith(color: tagColor),
                ),
              ],
            ),
            for (final line in lines) ...[
              const SizedBox(height: BloomSpacing.xs),
              Text(line, style: BloomTextStyles.caption),
            ],
          ],
        ),
      ),
    );
  }
}
