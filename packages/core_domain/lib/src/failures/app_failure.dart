import 'package:core_domain/src/entities/enums.dart';
import 'package:core_domain/src/entities/intake.dart';
import 'package:equatable/equatable.dart';

/// Every failure a repository can return. Blocs switch on this exhaustively;
/// no exception crosses the data layer.
sealed class AppFailure extends Equatable {
  const new([this.message]);

  /// No connection, timeout or an unreadable response.
  const factory network([String? message]) = NetworkFailure;

  /// The server answered with an unexpected error (5xx other than a refusal).
  const factory server({int? statusCode, String? message}) = ServerFailure;

  /// Private mode: no route met the confidential privacy floor (HTTP 502
  /// `confidential_route_unavailable`). No fallback model was called.
  const factory routeRefused([String? message]) = RouteRefusedFailure;

  /// The session or brief is locked (HTTP 409): urgent, done or already
  /// decided. For `session_locked` the server also sends the session [status]
  /// and, when urgent, the [urgent] message (show P03, not P04).
  const factory locked([
    String? message,
    SessionStatus? status,
    UrgentMessage? urgent,
  ]) = LockedFailure;

  /// The resource does not exist yet (HTTP 404), e.g. a brief still drafting.
  const factory notFound([String? message]) = NotFoundFailure;

  /// Developer-facing detail. Never shown raw to patients.
  final String? message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends AppFailure {
  const new([super.message]);
}

final class ServerFailure extends AppFailure {
  const new({this.statusCode, String? message}) : super(message);

  final int? statusCode;

  @override
  List<Object?> get props => [statusCode, message];
}

final class RouteRefusedFailure extends AppFailure {
  const new([super.message]);
}

final class LockedFailure extends AppFailure {
  const new([super.message, this.status, this.urgent]);

  /// Session status from a 409 `session_locked` body; null for other 409s.
  final SessionStatus? status;

  /// The fixed urgent message when [status] is urgent.
  final UrgentMessage? urgent;

  @override
  List<Object?> get props => [message, status, urgent];
}

final class NotFoundFailure extends AppFailure {
  const new([super.message]);
}
