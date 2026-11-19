import 'package:json_annotation/json_annotation.dart';

/// Mirrors `SessionStatus` in server/app/models.py and docs/api-contract.md.
@JsonEnum(fieldRename: FieldRename.snake)
enum SessionStatus {
  inProgress,
  urgent,
  ready,
  approved,
  edited,
  rejected;

  /// The server's value, e.g. `in_progress`.
  String get wire => this == inProgress ? 'in_progress' : name;

  /// Parses a server value; null when absent or unknown.
  static SessionStatus? tryParse(Object? wire) {
    for (final status in values) {
      if (status.wire == wire) return status;
    }
    return null;
  }
}

/// Mirrors `RedFlagRule` in server/app/models.py. Rule logic lives only on
/// the server.
enum RedFlagRule {
  @JsonValue('R1')
  r1,
  @JsonValue('R2')
  r2,
  @JsonValue('R3')
  r3,
  @JsonValue('R4')
  r4,
  @JsonValue('R5')
  r5,
  @JsonValue('R6')
  r6;

  /// The server's rule ID, e.g. `R1`.
  String get id => name.toUpperCase();
}

/// Mirrors `TrustOutcome` in server/app/models.py.
enum TrustOutcome { ok, refused, error }

/// Model routing mode. `private` fails closed.
enum RouteMode { dev, private }

/// Physician decision on a draft brief.
@JsonEnum(valueField: 'wire')
enum BriefDecision {
  approve('approve'),
  edit('edit'),
  reject('reject');

  new(this.wire);

  final String wire;
}

/// Mirrors `Provenance.review_status` in server/app/models.py.
enum ReviewStatus { draft, approved, edited, rejected }

/// Demo login role (`POST /api/login`).
enum BloomRole { patient, doctor }

/// Mirrors `Provenance.source`: who wrote a brief draft. `fallback` is a
/// deterministic DRAFT built from the intake answers without any model call.
enum BriefSource { model, fallback }

/// Optional diagnostics on `POST /api/sessions/{id}/messages`
/// (`parse_path`, `brief_parse_path`): how a turn's output was obtained.
@JsonEnum(fieldRename: FieldRename.snake)
enum ParsePath {
  /// Model JSON on the first call.
  firstPass,

  /// Model JSON after one repair call.
  repair,

  /// No usable model output: fixed question or deterministic DRAFT, no model.
  fallback,

  /// Red-flag rule, no model.
  rule,
}

/// Trust event nodes that are not model calls (`model_id` null,
/// `policy_required` [noModelCallPolicy]).
abstract final class TrustNodes {
  static const intakeFallback = 'intake_fallback';
  static const briefFallback = 'brief_fallback';

  /// `policy_required` of the fallback nodes.
  static const noModelCallPolicy = 'no_model_call';
}
