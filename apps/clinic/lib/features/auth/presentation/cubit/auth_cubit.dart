import 'package:bloc/bloc.dart';
import 'package:core_domain/core_domain.dart';
import 'package:equatable/equatable.dart';

enum AuthStatus { signedOut, signingIn, signedIn }

class AuthState extends Equatable {
  const new({
    this.status = AuthStatus.signedOut,
    this.reviewerName = AuthState.defaultReviewer,
    this.failure,
  });

  /// Synthetic reviewer shown on decisions when none was entered.
  static const defaultReviewer = 'Dr. Demo';

  final AuthStatus status;

  /// Name stored as `reviewed_by` on Confirm / Edit / Reject.
  final String reviewerName;

  /// Last sign-in failure, cleared on the next attempt.
  final AppFailure? failure;

  bool get isSignedIn => status == AuthStatus.signedIn;

  @override
  List<Object?> get props => [status, reviewerName, failure];
}

/// Demo role login (A01): `POST /api/login {role: doctor}`. Not production
/// auth. The token lives in the API client's memory, so a page reload signs
/// out.
class AuthCubit extends Cubit<AuthState> {
  new(this._sessions, {bool signedIn = false})
    : super(
        AuthState(
          status: signedIn ? AuthStatus.signedIn : AuthStatus.signedOut,
        ),
      );

  final SessionRepository _sessions;

  Future<void> signIn({String? reviewerName}) async {
    final name = reviewerName?.trim();
    final reviewer = (name == null || name.isEmpty)
        ? AuthState.defaultReviewer
        : name;
    emit(AuthState(status: AuthStatus.signingIn, reviewerName: reviewer));
    final result = await _sessions.login(BloomRole.doctor);
    emit(
      result.fold(
        (_) => AuthState(status: AuthStatus.signedIn, reviewerName: reviewer),
        (failure) => AuthState(reviewerName: reviewer, failure: failure),
      ),
    );
  }

  void signOut() => emit(AuthState(reviewerName: state.reviewerName));
}
