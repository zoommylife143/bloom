import 'package:bloc/bloc.dart';
import 'package:core_domain/core_domain.dart';
import 'package:equatable/equatable.dart';

enum AuthStatus { signedOut, signingIn, signedIn }

/// Demo sign-in state (A01). Not production auth: the token lives in the API
/// client's memory only, so a page reload signs the patient out.
class AuthState extends Equatable {
  const new({
    this.status = AuthStatus.signedOut,
    this.failure,
    this.expired = false,
    this.mode,
  });

  final AuthStatus status;

  /// Why the last sign-in failed, if it did.
  final AppFailure? failure;

  /// The server rejected the token (HTTP 401) and the patient was sent back
  /// to A01.
  final bool expired;

  /// Routing mode from `GET /healthz`, if the server answered. P01 words the
  /// privacy summary from it.
  final RouteMode? mode;

  bool get isSignedIn => status == AuthStatus.signedIn;

  @override
  List<Object?> get props => [status, failure, expired, mode];
}

class AuthCubit extends Cubit<AuthState> {
  new({required this._sessions, AuthState? initialState})
    : super(initialState ?? const AuthState());

  final SessionRepository _sessions;

  /// A01 "Continue as patient": `POST /api/login {role: patient}`.
  Future<void> signIn() async {
    if (state.status == AuthStatus.signingIn) return;
    emit(const AuthState(status: AuthStatus.signingIn));
    final result = await _sessions.login(BloomRole.patient);
    if (result case Err(:final failure)) {
      emit(AuthState(failure: failure));
      return;
    }
    final mode = (await _sessions.health()).valueOrNull?.mode;
    emit(AuthState(status: AuthStatus.signedIn, mode: mode));
  }

  /// The server answered 401: back to A01 with a short note.
  void expire() => emit(const AuthState(expired: true));
}
