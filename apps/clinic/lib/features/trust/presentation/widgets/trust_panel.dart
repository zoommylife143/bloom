import 'package:bloom_clinic/app/widgets/clinic_widgets.dart';
import 'package:bloom_clinic/app/widgets/status_tag.dart';
import 'package:bloom_clinic/features/trust/domain/trust_view.dart';
import 'package:bloom_clinic/features/trust/presentation/cubit/trust_cubit.dart';
import 'package:bloom_clinic/features/trust/presentation/widgets/trust_event_row.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// D03 Privacy & Trust panel (Figma 7:224): one row per external call for
/// this session, the Context.dev de-identification block, the gateway
/// attestation summary and the physician approval status. Every value comes
/// from the server's TrustEvents; nothing is inferred.
class TrustPanel extends StatelessWidget {
  const new({
    required this.state,
    required this.approval,
    this.generating = false,
    this.sampleQuery,
    super.key,
  });

  final TrustState state;

  /// Physician approval tag (follows the D02 state).
  final ClinicStatus approval;

  /// D02 is still generating (guideline search may be running).
  final bool generating;

  /// One de-identified query from the brief's evidence, shown quoted.
  final String? sampleQuery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final report = state.report;
    final events = report?.events ?? const <TrustEvent>[];
    final calls = events.where((e) => !isRetrieval(e)).toList();
    final isDev =
        report?.mode == RouteMode.dev ||
        events.any((e) => e.mode == RouteMode.dev);

    return ClinicCard(
      width: double.infinity,
      padding: const EdgeInsets.all(BloomSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 20,
                color: BloomTokens.of(context).verified,
              ),
              const SizedBox(width: BloomSpacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.clinicTrustTitle,
                    style: BloomTextStyles.title,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BloomSpacing.md),
          Text(l10n.clinicTrustNote, style: BloomTextStyles.caption),
          ..._gap(switch (state.status) {
            TrustStatus.loading => [
              const SkeletonBar(width: double.infinity, height: 90),
            ],
            TrustStatus.failure => [
              ClinicBanner(
                type: ClinicBannerType.urgent,
                text: failureMessage(l10n, state.failure!),
              ),
            ],
            TrustStatus.loaded => [
              if (isDev)
                TrustRow(
                  label: l10n.clinicTrustModeLabel,
                  value: l10n.clinicTrustModeDevValue,
                  status: TrustRowStatus.devWarning,
                  statusText: l10n.clinicTrustDevWarning,
                ),
              if (calls.isEmpty)
                Text(l10n.clinicTrustNoCalls, style: BloomTextStyles.caption),
              for (final e in calls) TrustEventRow(event: e),
              _DeidBlock(
                summary: RetrievalSummary.fromEvents(events),
                generating: generating,
                sampleQuery: sampleQuery,
              ),
              _AttestationBlock(attestation: report!.attestation),
            ],
          }),
          const SizedBox(height: BloomSpacing.md),
          // Wrap, not Row: the tag drops below the label when the panel is
          // narrow instead of overflowing.
          Wrap(
            spacing: BloomSpacing.sm,
            runSpacing: BloomSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.clinicTrustApproval, style: BloomTextStyles.label),
              StatusTag(status: approval),
            ],
          ),
        ],
      ),
    );
  }

  static List<Widget> _gap(List<Widget> children) => [
    for (final c in children) ...[const SizedBox(height: BloomSpacing.md), c],
  ];
}

class _SubtleBlock extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.lines,
    this.extra = const [],
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: BloomSpacing.lg,
      vertical: BloomSpacing.md,
    ),
    decoration: BoxDecoration(
      color: BloomColors.bgSubtle,
      borderRadius: BorderRadius.circular(BloomRadius.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: BloomTokens.of(context).verified),
            const SizedBox(width: BloomSpacing.sm),
            Expanded(child: Text(title, style: BloomTextStyles.label)),
          ],
        ),
        for (final line in lines) ...[
          const SizedBox(height: BloomSpacing.xs),
          Text(line, style: BloomTextStyles.caption),
        ],
        ...extra,
      ],
    ),
  );
}

class _DeidBlock extends StatelessWidget {
  const new({
    required this.summary,
    required this.generating,
    this.sampleQuery,
  });

  final RetrievalSummary summary;
  final bool generating;
  final String? sampleQuery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (String title, List<String> lines) = switch (summary) {
      RetrievalSummary(queries: 0) when generating => (
        l10n.clinicDeidSearching,
        [l10n.clinicDeidSearchingBody],
      ),
      RetrievalSummary(queries: 0) => (
        l10n.clinicDeidNone,
        [l10n.clinicDeidNoneBody],
      ),
      RetrievalSummary(noPassages: true) => (
        l10n.clinicDeidFailed(summary.error ?? l10n.clinicDeidNoResults),
        [l10n.clinicDeidFailedBody],
      ),
      _ => (
        l10n.clinicDeidQueries(summary.queries),
        [
          l10n.clinicDeidQueriesBody(summary.passages),
          if (sampleQuery case final q?) '"$q"',
        ],
      ),
    };
    return _SubtleBlock(icon: Icons.check, title: title, lines: lines);
  }
}

class _AttestationBlock extends StatelessWidget {
  const new({required this.attestation});

  final Map<String, dynamic> attestation;

  static String _short(Object? v) {
    final s = '$v';
    return s.length > 20 ? '${s.substring(0, 20)}…' : s;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ok = attestation['status'] == 'ok';
    final matched = attestation['verified_claims'] == true;
    final issuer = attestation['issuer'];
    final audience = attestation['audience'];
    final digest = attestation['image_digest'];
    final commit = attestation['source_commit'];
    return _SubtleBlock(
      icon: Icons.fact_check_outlined,
      title: l10n.clinicAttestationTitle,
      lines: [
        if (!ok) l10n.clinicAttestationUnavailable,
        if (issuer != null) l10n.clinicAttestationIssuer('$issuer'),
        if (audience != null) l10n.clinicAttestationAudience('$audience'),
        if (digest != null) l10n.clinicAttestationDigest(_short(digest)),
        if (commit != null) l10n.clinicAttestationCommit(_short(commit)),
        l10n.clinicAttestationSignatureNote,
      ],
      extra: [
        if (ok)
          TrustRow(
            label: l10n.clinicAttestationClaims,
            value: matched
                ? l10n.clinicAttestationMatch
                : l10n.clinicAttestationNoMatch,
            status: matched
                ? TrustRowStatus.verified
                : TrustRowStatus.notExposed,
            statusText: matched
                ? l10n.clinicAttestationMatchStatus
                : l10n.clinicAttestationNoMatchStatus,
          ),
      ],
    );
  }
}
