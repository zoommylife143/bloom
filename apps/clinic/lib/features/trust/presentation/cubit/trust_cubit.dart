import 'package:bloc/bloc.dart';
import 'package:core_domain/core_domain.dart';
import 'package:equatable/equatable.dart';

enum TrustStatus { loading, loaded, failure }

class TrustState extends Equatable {
  const new({this.status = TrustStatus.loading, this.report, this.failure});

  final TrustStatus status;
  final TrustReport? report;
  final AppFailure? failure;

  @override
  List<Object?> get props => [status, report, failure];
}

/// D03 Privacy & Trust: `GET /api/sessions/{id}/trust`. Reloads keep the
/// last report on screen.
class TrustCubit extends Cubit<TrustState> {
  new(this._trust, this.sessionId) : super(const TrustState());

  final TrustRepository _trust;
  final String sessionId;

  Future<void> load() async {
    if (state.report == null) emit(const TrustState());
    final result = await _trust.getTrust(sessionId);
    if (isClosed) return;
    emit(
      result.fold(
        (report) => TrustState(status: TrustStatus.loaded, report: report),
        (failure) => state.report == null
            ? TrustState(status: TrustStatus.failure, failure: failure)
            : state,
      ),
    );
  }
}
