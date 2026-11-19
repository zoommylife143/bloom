import 'package:bloom_ui/bloom_ui.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Every Figma StatusChip variant (component set 4:27) used on D screens.
enum ClinicStatus {
  inProgress,
  redFlag,
  ready,
  approved,
  refused,
  verified,
  devMode,
  draft,
  rejected,
}

/// Figma "StatusChip" as drawn on the clinic screens: an UPPERCASE overline
/// label in a pill, no icon. Session, brief and route status. Red/critical is
/// reserved for red flags and refused routes; green only for verified routes
/// and approvals. The label text always carries the meaning, never colour
/// alone.
class StatusTag extends StatelessWidget {
  const new({required this.status, this.label, super.key});

  final ClinicStatus status;

  /// Overrides the default label (still shown uppercase).
  final String? label;

  static String labelFor(BloomLocalizations l10n, ClinicStatus status) =>
      switch (status) {
        ClinicStatus.inProgress => l10n.clinicStatusInProgress,
        ClinicStatus.redFlag => l10n.clinicStatusRedFlag,
        ClinicStatus.ready => l10n.clinicStatusReady,
        ClinicStatus.approved => l10n.clinicStatusApproved,
        ClinicStatus.refused => l10n.clinicStatusRefused,
        ClinicStatus.verified => l10n.clinicStatusVerified,
        ClinicStatus.devMode => l10n.clinicStatusDevMode,
        ClinicStatus.draft => l10n.clinicStatusDraft,
        ClinicStatus.rejected => l10n.clinicStatusRejected,
      };

  @override
  Widget build(BuildContext context) {
    final tokens = BloomTokens.of(context);
    final (Color bg, Color fg) = switch (status) {
      ClinicStatus.inProgress => (BloomColors.bgSubtle, tokens.textSecondary),
      ClinicStatus.ready ||
      ClinicStatus.draft => (tokens.brandMuted, BloomColors.textBrand),
      ClinicStatus.approved ||
      ClinicStatus.verified => (tokens.verifiedSubtle, tokens.verified),
      ClinicStatus.redFlag ||
      ClinicStatus.refused ||
      ClinicStatus.rejected => (tokens.criticalSubtle, tokens.critical),
      ClinicStatus.devMode => (tokens.warningSubtle, tokens.warning),
    };
    final text = label ?? labelFor(context.l10n, status);

    return Semantics(
      label: context.l10n.clinicStatusSemantics(text),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(BloomRadius.full),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BloomSpacing.md,
            vertical: BloomSpacing.xs,
          ),
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            style: BloomTextStyles.overline.copyWith(color: fg),
          ),
        ),
      ),
    );
  }
}
