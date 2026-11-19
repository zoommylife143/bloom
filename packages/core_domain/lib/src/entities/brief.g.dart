// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brief.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScreeningLine _$ScreeningLineFromJson(Map<String, dynamic> json) =>
    _ScreeningLine(
      text: json['text'] as String,
      sourceUrl: json['source_url'] as String?,
    );

Map<String, dynamic> _$ScreeningLineToJson(_ScreeningLine instance) =>
    <String, dynamic>{'text': instance.text, 'source_url': instance.sourceUrl};

_Brief _$BriefFromJson(Map<String, dynamic> json) => _Brief(
  subjective: json['subjective'] as String,
  objective: json['objective'] as String,
  assessmentConsiderations: json['assessment_considerations'] as String,
  planConsiderations: json['plan_considerations'] as String,
  flags:
      (json['flags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  screeningsPossiblyDue:
      (json['screenings_possibly_due'] as List<dynamic>?)
          ?.map((e) => ScreeningLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ScreeningLine>[],
  suggestedQuestions:
      (json['suggested_questions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$BriefToJson(_Brief instance) => <String, dynamic>{
  'subjective': instance.subjective,
  'objective': instance.objective,
  'assessment_considerations': instance.assessmentConsiderations,
  'plan_considerations': instance.planConsiderations,
  'flags': instance.flags,
  'screenings_possibly_due': instance.screeningsPossiblyDue
      .map((e) => e.toJson())
      .toList(),
  'suggested_questions': instance.suggestedQuestions,
};

_Provenance _$ProvenanceFromJson(Map<String, dynamic> json) => _Provenance(
  generatedBy: json['generated_by'] as String,
  evidenceUrls:
      (json['evidence_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  reviewStatus:
      $enumDecodeNullable(_$ReviewStatusEnumMap, json['review_status']) ??
      ReviewStatus.draft,
  reviewedBy: json['reviewed_by'] as String?,
  reviewedAt: json['reviewed_at'] == null
      ? null
      : DateTime.parse(json['reviewed_at'] as String),
  source: $enumDecodeNullable(
    _$BriefSourceEnumMap,
    json['source'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
);

Map<String, dynamic> _$ProvenanceToJson(_Provenance instance) =>
    <String, dynamic>{
      'generated_by': instance.generatedBy,
      'evidence_urls': instance.evidenceUrls,
      'created_at': instance.createdAt?.toIso8601String(),
      'review_status': _$ReviewStatusEnumMap[instance.reviewStatus]!,
      'reviewed_by': instance.reviewedBy,
      'reviewed_at': instance.reviewedAt?.toIso8601String(),
      'source': _$BriefSourceEnumMap[instance.source],
    };

const _$ReviewStatusEnumMap = {
  ReviewStatus.draft: 'draft',
  ReviewStatus.approved: 'approved',
  ReviewStatus.edited: 'edited',
  ReviewStatus.rejected: 'rejected',
};

const _$BriefSourceEnumMap = {
  BriefSource.model: 'model',
  BriefSource.fallback: 'fallback',
};

_EvidenceItem _$EvidenceItemFromJson(Map<String, dynamic> json) =>
    _EvidenceItem(
      url: json['url'] as String,
      query: json['query'] as String? ?? '',
      title: json['title'] as String?,
      passage: json['passage'] as String? ?? '',
      retrievedAt: json['retrieved_at'] == null
          ? null
          : DateTime.parse(json['retrieved_at'] as String),
    );

Map<String, dynamic> _$EvidenceItemToJson(_EvidenceItem instance) =>
    <String, dynamic>{
      'url': instance.url,
      'query': instance.query,
      'title': instance.title,
      'passage': instance.passage,
      'retrieved_at': instance.retrievedAt?.toIso8601String(),
    };

_BriefBundle _$BriefBundleFromJson(Map<String, dynamic> json) => _BriefBundle(
  briefId: json['brief_id'] as String,
  sessionId: json['session_id'] as String,
  brief: Brief.fromJson(json['brief'] as Map<String, dynamic>),
  provenance: Provenance.fromJson(json['provenance'] as Map<String, dynamic>),
  originalBrief: json['original_brief'] == null
      ? null
      : Brief.fromJson(json['original_brief'] as Map<String, dynamic>),
  edited: json['edited'] as bool? ?? false,
  evidence:
      (json['evidence'] as List<dynamic>?)
          ?.map((e) => EvidenceItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <EvidenceItem>[],
  guidelineUpdates:
      (json['guideline_updates'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$BriefBundleToJson(_BriefBundle instance) =>
    <String, dynamic>{
      'brief_id': instance.briefId,
      'session_id': instance.sessionId,
      'brief': instance.brief.toJson(),
      'provenance': instance.provenance.toJson(),
      'original_brief': instance.originalBrief?.toJson(),
      'edited': instance.edited,
      'evidence': instance.evidence.map((e) => e.toJson()).toList(),
      'guideline_updates': instance.guidelineUpdates,
    };
