import 'package:core_domain/src/entities/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trust.freezed.dart';
part 'trust.g.dart';

/// One model or retrieval call (mirrors `TrustEvent`). Metadata only, never
/// clinical text.
@freezed
abstract class TrustEvent with _$TrustEvent {
  const factory({
    required String node,
    required RouteMode mode,
    required String policyRequired,
    required TrustOutcome outcome,
    String? sessionId,
    String? modelId,
    String? route,
    @Default(<String, dynamic>{}) Map<String, dynamic> evidence,
    String? requestId,
    int? latencyMs,
    DateTime? createdAt,
  }) = _TrustEvent;

  factory fromJson(Map<String, dynamic> json) => _$TrustEventFromJson(json);
}

/// Fallback rows (`intake_fallback`, `brief_fallback`) record that no model
/// was called.
extension TrustEventFallbackX on TrustEvent {
  bool get isNoModelCall =>
      policyRequired == TrustNodes.noModelCallPolicy ||
      node == TrustNodes.intakeFallback ||
      node == TrustNodes.briefFallback;
}

/// `GET /api/sessions/{id}/trust` (D03): events plus the gateway attestation
/// summary (`status`, `issuer`, `audience`, `verified_claims`, `fetched_at`;
/// kept as a map). `verified_claims` does not mean the JWT signature was
/// verified.
@freezed
abstract class TrustReport with _$TrustReport {
  const factory({
    String? sessionId,
    RouteMode? mode,
    @Default(<TrustEvent>[]) List<TrustEvent> events,
    @Default(<String, dynamic>{}) Map<String, dynamic> attestation,
  }) = _TrustReport;

  factory fromJson(Map<String, dynamic> json) => _$TrustReportFromJson(json);
}

/// One audit log row (D04). Metadata only.
@freezed
abstract class AuditRow with _$AuditRow {
  const factory({
    required String action,
    int? id,
    String? sessionId,
    String? actor,
    DateTime? createdAt,
  }) = _AuditRow;

  factory fromJson(Map<String, dynamic> json) => _$AuditRowFromJson(json);
}
