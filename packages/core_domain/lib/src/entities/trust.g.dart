// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trust.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrustEvent _$TrustEventFromJson(Map<String, dynamic> json) => _TrustEvent(
  node: json['node'] as String,
  mode: $enumDecode(_$RouteModeEnumMap, json['mode']),
  policyRequired: json['policy_required'] as String,
  outcome: $enumDecode(_$TrustOutcomeEnumMap, json['outcome']),
  sessionId: json['session_id'] as String?,
  modelId: json['model_id'] as String?,
  route: json['route'] as String?,
  evidence:
      json['evidence'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  requestId: json['request_id'] as String?,
  latencyMs: (json['latency_ms'] as num?)?.toInt(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$TrustEventToJson(_TrustEvent instance) =>
    <String, dynamic>{
      'node': instance.node,
      'mode': _$RouteModeEnumMap[instance.mode]!,
      'policy_required': instance.policyRequired,
      'outcome': _$TrustOutcomeEnumMap[instance.outcome]!,
      'session_id': instance.sessionId,
      'model_id': instance.modelId,
      'route': instance.route,
      'evidence': instance.evidence,
      'request_id': instance.requestId,
      'latency_ms': instance.latencyMs,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$RouteModeEnumMap = {RouteMode.dev: 'dev', RouteMode.private: 'private'};

const _$TrustOutcomeEnumMap = {
  TrustOutcome.ok: 'ok',
  TrustOutcome.refused: 'refused',
  TrustOutcome.error: 'error',
};

_TrustReport _$TrustReportFromJson(Map<String, dynamic> json) => _TrustReport(
  sessionId: json['session_id'] as String?,
  mode: $enumDecodeNullable(_$RouteModeEnumMap, json['mode']),
  events:
      (json['events'] as List<dynamic>?)
          ?.map((e) => TrustEvent.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <TrustEvent>[],
  attestation:
      json['attestation'] as Map<String, dynamic>? ?? const <String, dynamic>{},
);

Map<String, dynamic> _$TrustReportToJson(_TrustReport instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'mode': _$RouteModeEnumMap[instance.mode],
      'events': instance.events.map((e) => e.toJson()).toList(),
      'attestation': instance.attestation,
    };

_AuditRow _$AuditRowFromJson(Map<String, dynamic> json) => _AuditRow(
  action: json['action'] as String,
  id: (json['id'] as num?)?.toInt(),
  sessionId: json['session_id'] as String?,
  actor: json['actor'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$AuditRowToJson(_AuditRow instance) => <String, dynamic>{
  'action': instance.action,
  'id': instance.id,
  'session_id': instance.sessionId,
  'actor': instance.actor,
  'created_at': instance.createdAt?.toIso8601String(),
};
