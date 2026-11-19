import 'package:core_domain/src/entities/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'intake.freezed.dart';
part 'intake.g.dart';

/// `POST /api/sessions` response: the new session and Bloom's first question.
@freezed
abstract class StartedSession with _$StartedSession {
  const factory({
    required String sessionId,
    required RouteMode mode,
    @Default(SessionStatus.inProgress) SessionStatus status,
    @Default('') String reply,
    @Default(0) double progress,
  }) = _StartedSession;

  factory fromJson(Map<String, dynamic> json) => _$StartedSessionFromJson(json);
}

/// One button on the urgent care screen (P03), e.g. "Call 911".
@freezed
abstract class UrgentAction with _$UrgentAction {
  const factory({required String label, required String tel}) = _UrgentAction;

  factory fromJson(Map<String, dynamic> json) => _$UrgentActionFromJson(json);
}

/// Fixed server-side urgent message for a red-flag rule (`URGENT_MESSAGES`
/// in server/app/safety.py). No model wrote it.
@freezed
abstract class UrgentMessage with _$UrgentMessage {
  const factory({
    required String title,
    required String body,
    @Default(<UrgentAction>[]) List<UrgentAction> actions,
    RedFlagRule? ruleId,
    String? support,
  }) = _UrgentMessage;

  factory fromJson(Map<String, dynamic> json) => _$UrgentMessageFromJson(json);
}

/// `POST /api/sessions/{id}/messages` response: Bloom's reply to one patient
/// turn.
@freezed
abstract class IntakeTurn with _$IntakeTurn {
  const factory({
    required String reply,
    required SessionStatus status,
    @Default(0) double progress,

    /// True when the patient flow ends (urgent, or intake finished).
    @Default(false) bool done,
    UrgentMessage? urgent,

    /// Optional diagnostics: how this turn's intake output was obtained.
    /// Null when absent, null or an unknown value.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    ParsePath? parsePath,

    /// Optional diagnostics, set only on the turn that drafted the brief.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    ParsePath? briefParsePath,
  }) = _IntakeTurn;

  factory fromJson(Map<String, dynamic> json) => _$IntakeTurnFromJson(json);
}
