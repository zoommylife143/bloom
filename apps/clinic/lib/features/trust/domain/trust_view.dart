import 'package:core_domain/core_domain.dart';

/// Figma TrustRow outcome variants (D03 row states), plus an error row.
enum TrustVariant {
  /// OK, and the gateway returned receipt evidence.
  verified,

  /// OK, but the provider exposed no evidence.
  notExposed,

  /// Refused before inference; no fallback model was called.
  refused,

  /// The call failed.
  error,

  /// Dev mode: GLM route, zero data retention (operator-declared), not
  /// confidential.
  dev,

  /// Deterministic fallback (`intake_fallback`, `brief_fallback`): no model
  /// was called, so there is no model, route or receipt to show.
  noModelCall,
}

/// Retrieval (Context.dev, de-identified queries) rather than a model call.
bool isRetrieval(TrustEvent e) =>
    e.node == 'retrieve' || e.policyRequired == 'deidentified_query';

/// Decoded gateway receipt, if the provider returned one.
Map<String, dynamic>? receiptOf(TrustEvent e) {
  final receipt = e.evidence['receipt'];
  return receipt is Map ? receipt.cast<String, dynamic>() : null;
}

/// The negative test was served when it should have been refused.
bool servedWhenShouldRefuse(TrustEvent e) =>
    e.evidence['error'] == 'expected_refusal_but_served';

TrustVariant trustVariantOf(TrustEvent e) {
  if (e.outcome == TrustOutcome.refused) return TrustVariant.refused;
  if (e.outcome == TrustOutcome.error) return TrustVariant.error;
  if (e.isNoModelCall) return TrustVariant.noModelCall;
  if (e.mode == RouteMode.dev || e.policyRequired == 'zdr') {
    return TrustVariant.dev;
  }
  return receiptOf(e) == null ? TrustVariant.notExposed : TrustVariant.verified;
}

/// The format error a fallback row was used after (`evidence.after_error`).
String? fallbackAfterErrorOf(TrustEvent e) {
  final v = e.evidence['after_error'];
  return v is String && v.isNotEmpty ? v : null;
}

/// Short error label from the evidence, never a raw body.
String? errorLabelOf(TrustEvent e) {
  final ev = e.evidence;
  for (final key in ['error_code', 'error', 'error_type']) {
    final v = ev[key];
    if (v is String && v.isNotEmpty) return v;
  }
  final status = ev['http_status'];
  return status == null ? null : 'HTTP $status';
}

/// Summary of the retrieval calls for the De-identification block.
class RetrievalSummary {
  const new({
    required this.queries,
    required this.passages,
    required this.failed,
    this.error,
  });

  factory fromEvents(Iterable<TrustEvent> events) {
    final list = events.where(isRetrieval).toList();
    var passages = 0;
    String? error;
    var failed = 0;
    for (final e in list) {
      final count = e.evidence['result_count'];
      if (count is int) passages += count;
      if (e.outcome != TrustOutcome.ok) {
        failed++;
        error ??= errorLabelOf(e);
      }
    }
    return RetrievalSummary(
      queries: list.length,
      passages: passages,
      failed: failed,
      error: error,
    );
  }

  final int queries;
  final int passages;
  final int failed;
  final String? error;

  /// Every query failed or none returned a passage.
  bool get noPassages => queries > 0 && passages == 0;
}
