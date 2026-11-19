import 'package:bloc/bloc.dart';
import 'package:core_domain/core_domain.dart';
import 'package:equatable/equatable.dart';

/// One scenario card's run state.
class ScenarioRunState extends Equatable {
  const new({this.isRunning = false, this.run, this.failure});

  final bool isRunning;
  final ScenarioRun? run;
  final AppFailure? failure;

  @override
  List<Object?> get props => [isRunning, run, failure];
}

class DemoState extends Equatable {
  const new({
    this.runs = const {},
    this.negativeRunning = false,
    this.negativeResult,
    this.negativeFailure,
  });

  /// Keyed by scenario ID (S1-S10).
  final Map<String, ScenarioRunState> runs;
  final bool negativeRunning;

  /// The refused TrustEvent (expected), or an error event if the gateway
  /// served the request.
  final TrustEvent? negativeResult;
  final AppFailure? negativeFailure;

  ScenarioRunState runOf(String id) => runs[id] ?? const ScenarioRunState();

  DemoState withRun(String id, ScenarioRunState run) => DemoState(
    runs: {...runs, id: run},
    negativeRunning: negativeRunning,
    negativeResult: negativeResult,
    negativeFailure: negativeFailure,
  );

  @override
  List<Object?> get props => [
    runs,
    negativeRunning,
    negativeResult,
    negativeFailure,
  ];
}

/// D05 demo scenarios: replays S1-S10 through the real graph
/// (`POST /api/demo/scenarios/{id}/run`) and runs the private-mode negative
/// test (`POST /api/demo/negative-test`), whose expected result is a
/// refused TrustEvent with no fallback model call.
class DemoCubit extends Cubit<DemoState> {
  new(this._sessions, this._trust) : super(const DemoState());

  final SessionRepository _sessions;
  final TrustRepository _trust;

  Future<void> runScenario(String id) async {
    if (state.runOf(id).isRunning) return;
    emit(state.withRun(id, const ScenarioRunState(isRunning: true)));
    final result = await _sessions.runScenario(id);
    if (isClosed) return;
    emit(
      state.withRun(
        id,
        result.fold(
          (run) => ScenarioRunState(run: run),
          (failure) => ScenarioRunState(failure: failure),
        ),
      ),
    );
  }

  Future<void> runNegativeTest() async {
    if (state.negativeRunning) return;
    emit(DemoState(runs: state.runs, negativeRunning: true));
    final result = await _trust.runNegativeTest();
    if (isClosed) return;
    emit(
      result.fold(
        (event) => DemoState(runs: state.runs, negativeResult: event),
        (failure) => DemoState(runs: state.runs, negativeFailure: failure),
      ),
    );
  }
}
