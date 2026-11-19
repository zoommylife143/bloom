import 'package:core_domain/src/entities/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

/// One row of the patient queue (D01). Synthetic sessions only.
@freezed
abstract class SessionSummary with _$SessionSummary {
  const factory({
    @JsonKey(readValue: _readId) required String id,
    required SessionStatus status,
    DateTime? createdAt,
    DateTime? updatedAt,
    @JsonKey(name: 'red_flag_rule') RedFlagRule? redFlag,
    String? scenarioId,
    String? briefId,

    /// Null until a brief exists.
    ReviewStatus? reviewStatus,
    String? ageBand,

    /// Truncated to 120 characters by the server.
    String? reasonForVisit,
    RouteMode? mode,
  }) = _SessionSummary;

  factory fromJson(Map<String, dynamic> json) => _$SessionSummaryFromJson(json);
}

// The server may call the key `id` or `session_id`; accept both.
Object? _readId(Map<dynamic, dynamic> json, String key) =>
    json['id'] ?? json['session_id'];

/// `GET /api/sessions/{id}/flag` (D06): which rule fired, on which fields,
/// and when. Matched values are keywords or field names, never free text.
@freezed
abstract class RedFlagSummary with _$RedFlagSummary {
  const factory({
    required String sessionId,
    required RedFlagRule ruleId,
    @Default(<String>[]) List<String> matched,
    String? source,
    DateTime? createdAt,
    String? title,
    String? body,
  }) = _RedFlagSummary;

  factory fromJson(Map<String, dynamic> json) => _$RedFlagSummaryFromJson(json);
}

/// `POST /api/demo/scenarios/{id}/run` (D05).
@freezed
abstract class ScenarioRun with _$ScenarioRun {
  const factory({
    required String sessionId,
    required SessionStatus status,
    String? scenarioId,
    @Default(0) int turnsRun,
    String? briefId,
  }) = _ScenarioRun;

  factory fromJson(Map<String, dynamic> json) => _$ScenarioRunFromJson(json);
}

/// `GET /api/healthz`. Never carries key values.
@freezed
abstract class HealthStatus with _$HealthStatus {
  const factory({
    required bool ok,
    required RouteMode mode,
    @Default(false) bool trustedrouterConfigured,
  }) = _HealthStatus;

  factory fromJson(Map<String, dynamic> json) => _$HealthStatusFromJson(json);
}
