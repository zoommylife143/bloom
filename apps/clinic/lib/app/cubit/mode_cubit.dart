import 'package:bloc/bloc.dart';
import 'package:core_domain/core_domain.dart';

/// Server routing mode from `GET /api/healthz` (sidebar Mode card). Null
/// until known or when the server is unreachable; the card then says so
/// instead of guessing.
class ModeCubit extends Cubit<RouteMode?> {
  new(this._sessions) : super(null);

  final SessionRepository _sessions;

  Future<void> load() async {
    final result = await _sessions.health();
    if (isClosed) return;
    emit(result.valueOrNull?.mode);
  }
}
