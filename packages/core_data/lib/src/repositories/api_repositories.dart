import 'package:core_data/src/api/bloom_api_client.dart';
import 'package:core_domain/core_domain.dart';

/// [IntakeRepository] backed by the Bloom API.
class ApiIntakeRepository implements IntakeRepository {
  const new(this._api);

  final BloomApiClient _api;

  @override
  Future<Result<StartedSession>> startSession({String? scenarioId}) =>
      _api.createSession(scenarioId: scenarioId);

  @override
  Future<Result<IntakeTurn>> sendMessage({
    required String sessionId,
    required String text,
    String? clientMessageId,
  }) => _api.sendMessage(sessionId, text, clientMessageId: clientMessageId);
}

/// [BriefRepository] backed by the Bloom API.
class ApiBriefRepository implements BriefRepository {
  const new(this._api);

  final BloomApiClient _api;

  @override
  Future<Result<BriefBundle>> getBrief(String sessionId) =>
      _api.getBrief(sessionId);

  @override
  Future<Result<BriefBundle>> decide({
    required String briefId,
    required BriefDecision decision,
    required String reviewer,
    Brief? edited,
  }) => _api.decideBrief(
    briefId,
    decision: decision,
    reviewer: reviewer,
    edited: edited,
  );
}

/// [TrustRepository] backed by the Bloom API.
class ApiTrustRepository implements TrustRepository {
  const new(this._api);

  final BloomApiClient _api;

  @override
  Future<Result<TrustReport>> getTrust(String sessionId) =>
      _api.getTrust(sessionId);

  @override
  Future<Result<List<AuditRow>>> getAudit() => _api.getAudit();

  @override
  Future<Result<TrustEvent>> runNegativeTest({String? sessionId}) =>
      _api.runNegativeTest(sessionId: sessionId);
}

/// [SessionRepository] backed by the Bloom API.
class ApiSessionRepository implements SessionRepository {
  const new(this._api);

  final BloomApiClient _api;

  @override
  Future<Result<void>> login(BloomRole role) => _api.login(role);

  @override
  Future<Result<List<SessionSummary>>> listSessions() => _api.listSessions();

  @override
  Future<Result<RedFlagSummary>> getRedFlag(String sessionId) =>
      _api.getRedFlag(sessionId);

  @override
  Future<Result<ScenarioRun>> runScenario(String scenarioId) =>
      _api.runScenario(scenarioId);

  @override
  Future<Result<HealthStatus>> health() => _api.health();
}
