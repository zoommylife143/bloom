import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core_domain/core_domain.dart';
import 'package:equatable/equatable.dart';

enum QueueStatus { loading, loaded, failure }

class QueueState extends Equatable {
  const new({
    this.status = QueueStatus.loading,
    this.sessions = const [],
    this.failure,
    this.isRefreshing = false,
  });

  final QueueStatus status;

  /// Red-flag sessions first, then newest first (server order, re-applied
  /// here so fakes and older servers sort the same).
  final List<SessionSummary> sessions;
  final AppFailure? failure;

  /// A refresh is running while the old list stays on screen.
  final bool isRefreshing;

  bool get isEmpty => status == QueueStatus.loaded && sessions.isEmpty;

  @override
  List<Object?> get props => [status, sessions, failure, isRefreshing];
}

/// D01 patient queue. Loads `GET /api/sessions`, refreshes on demand and
/// polls quietly every `pollInterval` (null = no polling).
class QueueCubit extends Cubit<QueueState> {
  new(this._sessions, {Duration? pollInterval}) : super(const QueueState()) {
    if (pollInterval != null) {
      _timer = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
    }
  }

  final SessionRepository _sessions;
  Timer? _timer;

  /// First load: shows the skeleton.
  Future<void> load() async {
    emit(const QueueState());
    await _fetch();
  }

  /// Keeps the current rows visible while reloading.
  Future<void> refresh() async {
    if (state.isRefreshing) return;
    if (state.status != QueueStatus.loaded) {
      await load();
      return;
    }
    emit(
      QueueState(
        status: state.status,
        sessions: state.sessions,
        isRefreshing: true,
      ),
    );
    await _fetch();
  }

  Future<void> _fetch() async {
    final result = await _sessions.listSessions();
    if (isClosed) return;
    emit(
      result.fold(
        (list) =>
            QueueState(status: QueueStatus.loaded, sessions: sortQueue(list)),
        (failure) => QueueState(status: QueueStatus.failure, failure: failure),
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

/// Red flags first, then most recently updated first.
List<SessionSummary> sortQueue(List<SessionSummary> sessions) {
  DateTime at(SessionSummary s) =>
      s.updatedAt ?? s.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final sorted = [...sessions]
    ..sort((a, b) {
      final flagA = a.status == SessionStatus.urgent ? 0 : 1;
      final flagB = b.status == SessionStatus.urgent ? 0 : 1;
      if (flagA != flagB) return flagA - flagB;
      return at(b).compareTo(at(a));
    });
  return List.unmodifiable(sorted);
}

/// What the ACTION column offers for a row.
enum QueueAction { viewSummary, openBrief, none }

QueueAction queueActionFor(SessionSummary s) {
  if (s.status == SessionStatus.urgent) return QueueAction.viewSummary;
  if (s.status == SessionStatus.inProgress && s.briefId == null) {
    return QueueAction.none;
  }
  return QueueAction.openBrief;
}
