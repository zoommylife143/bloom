// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intake.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StartedSession _$StartedSessionFromJson(Map<String, dynamic> json) =>
    _StartedSession(
      sessionId: json['session_id'] as String,
      mode: $enumDecode(_$RouteModeEnumMap, json['mode']),
      status:
          $enumDecodeNullable(_$SessionStatusEnumMap, json['status']) ??
          SessionStatus.inProgress,
      reply: json['reply'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$StartedSessionToJson(_StartedSession instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'mode': _$RouteModeEnumMap[instance.mode]!,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'reply': instance.reply,
      'progress': instance.progress,
    };

const _$RouteModeEnumMap = {RouteMode.dev: 'dev', RouteMode.private: 'private'};

const _$SessionStatusEnumMap = {
  SessionStatus.inProgress: 'in_progress',
  SessionStatus.urgent: 'urgent',
  SessionStatus.ready: 'ready',
  SessionStatus.approved: 'approved',
  SessionStatus.edited: 'edited',
  SessionStatus.rejected: 'rejected',
};

_UrgentAction _$UrgentActionFromJson(Map<String, dynamic> json) =>
    _UrgentAction(label: json['label'] as String, tel: json['tel'] as String);

Map<String, dynamic> _$UrgentActionToJson(_UrgentAction instance) =>
    <String, dynamic>{'label': instance.label, 'tel': instance.tel};

_UrgentMessage _$UrgentMessageFromJson(Map<String, dynamic> json) =>
    _UrgentMessage(
      title: json['title'] as String,
      body: json['body'] as String,
      actions:
          (json['actions'] as List<dynamic>?)
              ?.map((e) => UrgentAction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <UrgentAction>[],
      ruleId: $enumDecodeNullable(_$RedFlagRuleEnumMap, json['rule_id']),
      support: json['support'] as String?,
    );

Map<String, dynamic> _$UrgentMessageToJson(_UrgentMessage instance) =>
    <String, dynamic>{
      'title': instance.title,
      'body': instance.body,
      'actions': instance.actions.map((e) => e.toJson()).toList(),
      'rule_id': _$RedFlagRuleEnumMap[instance.ruleId],
      'support': instance.support,
    };

const _$RedFlagRuleEnumMap = {
  RedFlagRule.r1: 'R1',
  RedFlagRule.r2: 'R2',
  RedFlagRule.r3: 'R3',
  RedFlagRule.r4: 'R4',
  RedFlagRule.r5: 'R5',
  RedFlagRule.r6: 'R6',
};

_IntakeTurn _$IntakeTurnFromJson(Map<String, dynamic> json) => _IntakeTurn(
  reply: json['reply'] as String,
  status: $enumDecode(_$SessionStatusEnumMap, json['status']),
  progress: (json['progress'] as num?)?.toDouble() ?? 0,
  done: json['done'] as bool? ?? false,
  urgent: json['urgent'] == null
      ? null
      : UrgentMessage.fromJson(json['urgent'] as Map<String, dynamic>),
  parsePath: $enumDecodeNullable(
    _$ParsePathEnumMap,
    json['parse_path'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  briefParsePath: $enumDecodeNullable(
    _$ParsePathEnumMap,
    json['brief_parse_path'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
);

Map<String, dynamic> _$IntakeTurnToJson(_IntakeTurn instance) =>
    <String, dynamic>{
      'reply': instance.reply,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'done': instance.done,
      'urgent': instance.urgent?.toJson(),
      'parse_path': _$ParsePathEnumMap[instance.parsePath],
      'brief_parse_path': _$ParsePathEnumMap[instance.briefParsePath],
    };

const _$ParsePathEnumMap = {
  ParsePath.firstPass: 'first_pass',
  ParsePath.repair: 'repair',
  ParsePath.fallback: 'fallback',
  ParsePath.rule: 'rule',
};
