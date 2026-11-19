import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core_domain/core_domain.dart';
import 'package:equatable/equatable.dart';

part 'brief_event.dart';
part 'brief_state.dart';

/// D02 physician brief. Loads `GET /api/sessions/{id}/brief` (404 =
/// still generating, re-checked every [pollInterval]), and records Confirm /
/// Edit / Reject with `POST /api/briefs/{id}/decision`. Every brief is a
/// draft until a decision is stored on the server.
class BriefBloc extends Bloc<BriefEvent, BriefState> {
  new({
    required BriefRepository briefRepository,
    required SessionRepository sessionRepository,
    required this.sessionId,
    SessionSummary? summary,
    this.pollInterval,
  }) : _briefs = briefRepository,
       _sessions = sessionRepository,
       super(BriefState(session: summary)) {
    on<BriefRequested>(_onRequested);
    on<BriefPolled>(_onPolled);
    on<BriefEditStarted>(
      (_, emit) => emit(state.copyWith(isEditing: true, decisionFailure: null)),
    );
    on<BriefEditCancelled>((_, emit) => emit(state.copyWith(isEditing: false)));
    on<BriefDecisionSubmitted>(_onDecision);
  }

  final BriefRepository _briefs;
  final SessionRepository _sessions;
  final String sessionId;
  final Duration? pollInterval;
  Timer? _poll;

  Future<void> _onRequested(
    BriefRequested event,
    Emitter<BriefState> emit,
  ) async {
    emit(state.copyWith(status: BriefStatus.loading, failure: null));
    await _load(emit);
  }

  Future<void> _onPolled(BriefPolled event, Emitter<BriefState> emit) =>
      _load(emit);

  Future<void> _load(Emitter<BriefState> emit) async {
    _poll?.cancel();
    final results = await Future.wait([
      _briefs.getBrief(sessionId),
      if (state.session == null) _sessions.listSessions(),
    ]);
    final brief = results[0] as Result<BriefBundle>;
    var session = state.session;
    if (results.length > 1) {
      final list = (results[1] as Result<List<SessionSummary>>).valueOrNull;
      session = list?.where((s) => s.id == sessionId).firstOrNull;
    }

    switch (brief) {
      case Ok(:final value):
        emit(
          state.copyWith(
            status: BriefStatus.ready,
            bundle: value,
            session: session,
            failure: null,
          ),
        );
      case Err(failure: NotFoundFailure()):
        emit(
          state.copyWith(
            status: BriefStatus.generating,
            session: session,
            failure: null,
          ),
        );
        if (pollInterval case final interval?) {
          _poll = Timer(interval, () {
            if (!isClosed) add(const BriefPolled());
          });
        }
      case Err(:final failure):
        emit(
          state.copyWith(
            status: BriefStatus.failure,
            session: session,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onDecision(
    BriefDecisionSubmitted event,
    Emitter<BriefState> emit,
  ) async {
    final bundle = state.bundle;
    if (bundle == null || state.submitting != null) return;
    emit(state.copyWith(submitting: event.decision, decisionFailure: null));
    final result = await _briefs.decide(
      briefId: bundle.briefId,
      decision: event.decision,
      reviewer: event.reviewer,
      edited: event.edited,
    );
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(bundle: value, submitting: null, isEditing: false));
      case Err(:final failure):
        emit(
          state.copyWith(
            submitting: null,
            decisionFailure: failure,
            isEditing: failure is! LockedFailure && state.isEditing,
          ),
        );
        // 409 already_decided: show the decision that is stored.
        if (failure is LockedFailure) await _load(emit);
    }
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
