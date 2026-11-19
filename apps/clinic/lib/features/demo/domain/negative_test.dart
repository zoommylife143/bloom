import 'package:bloom_clinic/features/trust/domain/trust_view.dart';
import 'package:core_domain/core_domain.dart';

/// How to read the D05 negative-test result (`POST /demo/negative-test`).
enum NegativeTestVerdict {
  /// Expected: refused before inference, no fallback model called.
  refused,

  /// The provider failed (e.g. HTTP 5xx) before it could refuse. Not a
  /// refusal and not a pass: the test did not run to a decision.
  providerError,

  /// The gateway served a request it should have refused. A real failure.
  served,

  /// Anything else (e.g. `ok`): not refused.
  unexpected,
}

NegativeTestVerdict negativeTestVerdictOf(TrustEvent e) => switch (e.outcome) {
  TrustOutcome.refused => NegativeTestVerdict.refused,
  TrustOutcome.error when servedWhenShouldRefuse(e) =>
    NegativeTestVerdict.served,
  TrustOutcome.error => NegativeTestVerdict.providerError,
  TrustOutcome.ok => NegativeTestVerdict.unexpected,
};

/// The provider's HTTP status from the event evidence, if it sent one.
int? httpStatusOf(TrustEvent e) => switch (e.evidence['http_status']) {
  final int status => status,
  final String status => int.tryParse(status),
  _ => null,
};
