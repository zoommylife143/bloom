import 'package:bloc/bloc.dart';
import 'package:core_domain/core_domain.dart';
import 'package:equatable/equatable.dart';

enum AuditStatus { loading, loaded, failure }

class AuditState extends Equatable {
  const new({
    this.status = AuditStatus.loading,
    this.rows = const [],
    this.failure,
  });

  final AuditStatus status;
  final List<AuditRow> rows;
  final AppFailure? failure;

  @override
  List<Object?> get props => [status, rows, failure];
}

/// D04 audit log: `GET /api/audit`, newest first, metadata only.
class AuditCubit extends Cubit<AuditState> {
  new(this._trust) : super(const AuditState());

  final TrustRepository _trust;

  Future<void> load() async {
    emit(const AuditState());
    final result = await _trust.getAudit();
    if (isClosed) return;
    emit(
      result.fold(
        (rows) => AuditState(status: AuditStatus.loaded, rows: rows),
        (failure) => AuditState(status: AuditStatus.failure, failure: failure),
      ),
    );
  }
}
