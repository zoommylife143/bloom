import 'package:core_domain/src/failures/app_failure.dart';
import 'package:equatable/equatable.dart';

/// Result of a repository or API call: either [Ok] with a value or [Err] with
/// an [AppFailure]. Used instead of throwing into blocs.
sealed class Result<T> extends Equatable {
  const new();

  const factory ok(T value) = Ok<T>;
  const factory err(AppFailure failure) = Err<T>;

  bool get isOk => this is Ok<T>;

  /// The value, or null on failure.
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// The failure, or null on success.
  AppFailure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  R fold<R>(R Function(T value) onOk, R Function(AppFailure failure) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final failure) => onErr(failure),
      };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Result.ok(transform(value)),
    Err(:final failure) => Result.err(failure),
  };
}

final class Ok<T> extends Result<T> {
  const new(this.value);

  final T value;

  @override
  List<Object?> get props => [value];
}

final class Err<T> extends Result<T> {
  const new(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}
