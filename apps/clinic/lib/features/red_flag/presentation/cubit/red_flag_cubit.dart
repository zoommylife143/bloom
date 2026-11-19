import 'package:bloc/bloc.dart';
import 'package:core_domain/core_domain.dart';
import 'package:equatable/equatable.dart';

enum RedFlagStatus { loading, loaded, failure }

class RedFlagState extends Equatable {
  const new({
    this.status = RedFlagStatus.loading,
    this.flag,
    this.failure,
    this.session,
  });

  final RedFlagStatus status;
  final RedFlagSummary? flag;
  final AppFailure? failure;

  /// Queue row for the header (scenario, age band). Optional.
  final SessionSummary? session;

  @override
  List<Object?> get props => [status, flag, failure, session];
}

/// D06 red-flag summary: `GET /api/sessions/{id}/flag`. No brief exists for
/// these sessions.
class RedFlagCubit extends Cubit<RedFlagState> {
  new(this._sessions, this.sessionId, {SessionSummary? summary})
    : super(RedFlagState(session: summary));

  final SessionRepository _sessions;
  final String sessionId;

  Future<void> load() async {
    final session = state.session;
    emit(RedFlagState(session: session));
    final results = await Future.wait([
      _sessions.getRedFlag(sessionId),
      if (session == null) _sessions.listSessions(),
    ]);
    if (isClosed) return;
    var summary = session;
    if (results.length > 1) {
      final list = (results[1] as Result<List<SessionSummary>>).valueOrNull;
      summary = list?.where((s) => s.id == sessionId).firstOrNull;
    }
    final flag = results[0] as Result<RedFlagSummary>;
    emit(
      flag.fold(
        (f) => RedFlagState(
          status: RedFlagStatus.loaded,
          flag: f,
          session: summary,
        ),
        (failure) => RedFlagState(
          status: RedFlagStatus.failure,
          failure: failure,
          session: summary,
        ),
      ),
    );
  }
}
