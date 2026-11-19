import 'package:core_domain/src/entities/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'brief.freezed.dart';
part 'brief.g.dart';

/// One "screening possibly due" line. A null [sourceUrl] means
/// "No guideline retrieved".
@freezed
abstract class ScreeningLine with _$ScreeningLine {
  const factory({required String text, String? sourceUrl}) = _ScreeningLine;

  factory fromJson(Map<String, dynamic> json) => _$ScreeningLineFromJson(json);
}

/// AI-drafted physician brief (mirrors `Brief` in server/app/models.py).
/// Always a draft until a physician decides.
@freezed
abstract class Brief with _$Brief {
  const factory({
    required String subjective,
    required String objective,
    required String assessmentConsiderations,
    required String planConsiderations,
    @Default(<String>[]) List<String> flags,
    @Default(<ScreeningLine>[]) List<ScreeningLine> screeningsPossiblyDue,
    @Default(<String>[]) List<String> suggestedQuestions,
  }) = _Brief;

  factory fromJson(Map<String, dynamic> json) => _$BriefFromJson(json);
}

/// Who or what produced a draft and who reviewed it (mirrors `Provenance`).
@freezed
abstract class Provenance with _$Provenance {
  const factory({
    required String generatedBy,
    @Default(<String>[]) List<String> evidenceUrls,
    DateTime? createdAt,
    @Default(ReviewStatus.draft) ReviewStatus reviewStatus,
    String? reviewedBy,
    DateTime? reviewedAt,

    /// `model` or `fallback` (deterministic DRAFT, no AI). Null when absent
    /// (older servers, read as model) or an unknown value.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    BriefSource? source,
  }) = _Provenance;

  factory fromJson(Map<String, dynamic> json) => _$ProvenanceFromJson(json);
}

/// True when the server wrote the draft without AI (`source: "fallback"`).
extension ProvenanceSourceX on Provenance {
  bool get isFallback => source == BriefSource.fallback;
}

/// One retrieved guideline passage (mirrors `EvidenceItem`).
@freezed
abstract class EvidenceItem with _$EvidenceItem {
  const factory({
    required String url,
    @Default('') String query,
    String? title,
    @Default('') String passage,
    DateTime? retrievedAt,
  }) = _EvidenceItem;

  factory fromJson(Map<String, dynamic> json) => _$EvidenceItemFromJson(json);
}

/// `GET /api/sessions/{id}/brief` and the decision response.
@freezed
abstract class BriefBundle with _$BriefBundle {
  const factory({
    required String briefId,
    required String sessionId,

    /// What to display: the edited version after an edit, else the draft.
    required Brief brief,
    required Provenance provenance,

    /// The AI draft, never overwritten.
    Brief? originalBrief,
    @Default(false) bool edited,
    @Default(<EvidenceItem>[]) List<EvidenceItem> evidence,

    /// Optional: cited evidence URLs whose guideline page changed recently
    /// (Context.dev Monitor). Absent from older servers.
    @Default(<String>[]) List<String> guidelineUpdates,
  }) = _BriefBundle;

  factory fromJson(Map<String, dynamic> json) => _$BriefBundleFromJson(json);
}
