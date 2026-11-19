import 'package:core_domain/src/entities/brief.dart';
import 'package:core_domain/src/entities/enums.dart';
import 'package:core_domain/src/entities/intake.dart';
import 'package:core_domain/src/entities/session.dart';
import 'package:core_domain/src/entities/trust.dart';
import 'package:core_domain/src/failures/app_failure.dart';
import 'package:core_domain/src/failures/result.dart';

/// Patient intake (P01-P04). Implemented in core_data.
abstract interface class IntakeRepository {
  /// Starts a session and returns Bloom's first question.
  Future<Result<StartedSession>> startSession({String? scenarioId});

  /// Sends one patient message. [LockedFailure] once the session is urgent or
  /// done (with `status` and `urgent` set); [RouteRefusedFailure] when private
  /// mode refuses.
  ///
  /// Pass the same [clientMessageId] when resending a turn (after a timeout or
  /// network error): the server then returns the first result instead of
  /// running the turn twice.
  Future<Result<IntakeTurn>> sendMessage({
    required String sessionId,
    required String text,
    String? clientMessageId,
  });
}

/// Physician brief (D02). Every brief is a draft until [decide] is called.
abstract interface class BriefRepository {
  /// [NotFoundFailure] until the brief has been generated.
  Future<Result<BriefBundle>> getBrief(String sessionId);

  /// Decides on the brief with [briefId] (`BriefBundle.briefId`).
  /// [LockedFailure] if it was already decided.
  Future<Result<BriefBundle>> decide({
    required String briefId,
    required BriefDecision decision,
    required String reviewer,
    Brief? edited,
  });
}

/// Privacy and Trust panel (D03), audit log (D04) and the negative test (D05).
abstract interface class TrustRepository {
  Future<Result<TrustReport>> getTrust(String sessionId);

  Future<Result<List<AuditRow>>> getAudit();

  /// Runs the private-mode negative test, attached to [sessionId]'s D03 panel
  /// if given. A refused [TrustEvent] is the expected success value.
  Future<Result<TrustEvent>> runNegativeTest({String? sessionId});
}

/// Sign-in, the queue (D01), red-flag summary (D06) and demo scenarios (D05).
abstract interface class SessionRepository {
  /// Demo role login. Not production auth.
  Future<Result<void>> login(BloomRole role);

  Future<Result<List<SessionSummary>>> listSessions();

  Future<Result<RedFlagSummary>> getRedFlag(String sessionId);

  /// Replays a synthetic scenario (S1-S10) up to urgent or ready.
  Future<Result<ScenarioRun>> runScenario(String scenarioId);

  Future<Result<HealthStatus>> health();
}
