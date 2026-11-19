import 'package:bloom_clinic/app/widgets/status_tag.dart';
import 'package:core_domain/core_domain.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

/// Clock time in the viewer's zone, e.g. `9:42 AM`.
String formatClock(DateTime time) => DateFormat.jm().format(time.toLocal());

/// `2 min ago`, `3 h ago`, else the clock time with the date.
String formatRelative(
  BloomLocalizations l10n,
  DateTime? time, {
  DateTime? now,
}) {
  if (time == null) return '—';
  final diff = (now ?? DateTime.now()).difference(time.toLocal());
  if (diff.inMinutes < 1) return l10n.clinicJustNow;
  if (diff.inMinutes < 60) return l10n.clinicMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.clinicHoursAgo(diff.inHours);
  return DateFormat.MMMd().add_jm().format(time.toLocal());
}

/// `1.8 s` or `340 ms`.
String formatLatency(int ms) =>
    ms < 1000 ? '$ms ms' : '${(ms / 1000).toStringAsFixed(1)} s';

/// First characters of an opaque session ID.
String shortId(String id) => id.length <= 6 ? id : id.substring(0, 6);

/// Synthetic patient label: `S6 · 25–29`, or `Patient a2fce7 · 30–39`.
String patientLabel(BloomLocalizations l10n, SessionSummary? s, String id) {
  final band = s?.ageBand?.replaceAll('-', '–');
  final who = s?.scenarioId ?? l10n.clinicPatientShort(shortId(id));
  return band == null ? who : '$who · $band';
}

/// Host without `www.`, for citations and banners.
String hostOf(String url) =>
    (Uri.tryParse(url)?.host ?? url).replaceFirst(RegExp(r'^www\.'), '');

/// Queue / header status for a session (Figma has no "Edited" chip: an
/// edited brief shows Approved).
ClinicStatus statusOfSession(SessionSummary s) => switch (s.status) {
  SessionStatus.urgent => ClinicStatus.redFlag,
  SessionStatus.inProgress => ClinicStatus.inProgress,
  SessionStatus.ready => ClinicStatus.ready,
  SessionStatus.approved || SessionStatus.edited => ClinicStatus.approved,
  SessionStatus.rejected => ClinicStatus.rejected,
};

/// Status for a brief's review state.
ClinicStatus statusOfReview(ReviewStatus review) => switch (review) {
  ReviewStatus.draft => ClinicStatus.draft,
  ReviewStatus.approved || ReviewStatus.edited => ClinicStatus.approved,
  ReviewStatus.rejected => ClinicStatus.rejected,
};

/// Human name for a deterministic red-flag rule (server/app/safety.py).
String ruleName(BloomLocalizations l10n, RedFlagRule rule) => switch (rule) {
  RedFlagRule.r1 => l10n.clinicRuleR1,
  RedFlagRule.r2 => l10n.clinicRuleR2,
  RedFlagRule.r3 => l10n.clinicRuleR3,
  RedFlagRule.r4 => l10n.clinicRuleR4,
  RedFlagRule.r5 => l10n.clinicRuleR5,
  RedFlagRule.r6 => l10n.clinicRuleR6,
};
