// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionSummary _$SessionSummaryFromJson(Map<String, dynamic> json) =>
    _SessionSummary(
      id: _readId(json, 'id') as String,
      status: $enumDecode(_$SessionStatusEnumMap, json['status']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      redFlag: $enumDecodeNullable(_$RedFlagRuleEnumMap, json['red_flag_rule']),
      scenarioId: json['scenario_id'] as String?,
      briefId: json['brief_id'] as String?,
      reviewStatus: $enumDecodeNullable(
        _$ReviewStatusEnumMap,
        json['review_status'],
      ),
      ageBand: json['age_band'] as String?,
      reasonForVisit: json['reason_for_visit'] as String?,
      mode: $enumDecodeNullable(_$RouteModeEnumMap, json['mode']),
    );

Map<String, dynamic> _$SessionSummaryToJson(_SessionSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'red_flag_rule': _$RedFlagRuleEnumMap[instance.redFlag],
      'scenario_id': instance.scenarioId,
      'brief_id': instance.briefId,
      'review_status': _$ReviewStatusEnumMap[instance.reviewStatus],
      'age_band': instance.ageBand,
      'reason_for_visit': instance.reasonForVisit,
      'mode': _$RouteModeEnumMap[instance.mode],
    };

const _$SessionStatusEnumMap = {
  SessionStatus.inProgress: 'in_progress',
  SessionStatus.urgent: 'urgent',
  SessionStatus.ready: 'ready',
  SessionStatus.approved: 'approved',
  SessionStatus.edited: 'edited',
  SessionStatus.rejected: 'rejected',
};

const _$RedFlagRuleEnumMap = {
  RedFlagRule.r1: 'R1',
  RedFlagRule.r2: 'R2',
  RedFlagRule.r3: 'R3',
  RedFlagRule.r4: 'R4',
  RedFlagRule.r5: 'R5',
  RedFlagRule.r6: 'R6',
};

const _$ReviewStatusEnumMap = {
  ReviewStatus.draft: 'draft',
  ReviewStatus.approved: 'approved',
  ReviewStatus.edited: 'edited',
  ReviewStatus.rejected: 'rejected',
};

const _$RouteModeEnumMap = {RouteMode.dev: 'dev', RouteMode.private: 'private'};

_RedFlagSummary _$RedFlagSummaryFromJson(Map<String, dynamic> json) =>
    _RedFlagSummary(
      sessionId: json['session_id'] as String,
      ruleId: $enumDecode(_$RedFlagRuleEnumMap, json['rule_id']),
      matched:
          (json['matched'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      source: json['source'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      title: json['title'] as String?,
      body: json['body'] as String?,
    );

Map<String, dynamic> _$RedFlagSummaryToJson(_RedFlagSummary instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'rule_id': _$RedFlagRuleEnumMap[instance.ruleId]!,
      'matched': instance.matched,
      'source': instance.source,
      'created_at': instance.createdAt?.toIso8601String(),
      'title': instance.title,
      'body': instance.body,
    };

_ScenarioRun _$ScenarioRunFromJson(Map<String, dynamic> json) => _ScenarioRun(
  sessionId: json['session_id'] as String,
  status: $enumDecode(_$SessionStatusEnumMap, json['status']),
  scenarioId: json['scenario_id'] as String?,
  turnsRun: (json['turns_run'] as num?)?.toInt() ?? 0,
  briefId: json['brief_id'] as String?,
);

Map<String, dynamic> _$ScenarioRunToJson(_ScenarioRun instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'scenario_id': instance.scenarioId,
      'turns_run': instance.turnsRun,
      'brief_id': instance.briefId,
    };

_HealthStatus _$HealthStatusFromJson(Map<String, dynamic> json) =>
    _HealthStatus(
      ok: json['ok'] as bool,
      mode: $enumDecode(_$RouteModeEnumMap, json['mode']),
      trustedrouterConfigured:
          json['trustedrouter_configured'] as bool? ?? false,
    );

Map<String, dynamic> _$HealthStatusToJson(_HealthStatus instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'mode': _$RouteModeEnumMap[instance.mode]!,
      'trustedrouter_configured': instance.trustedrouterConfigured,
    };
