part of 'intake_bloc.dart';

sealed class IntakeEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// P01 Start: create the server session and show Bloom's first question.
final class IntakeStarted extends IntakeEvent {
  const new();
}

/// The patient sends an answer (typed or a quick reply).
final class IntakeMessageSubmitted extends IntakeEvent {
  const new(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// "Try again" after a route refusal or a model error. Resends the same
/// answer (the server did not save it), or restarts the session if starting
/// failed.
final class IntakeRetried extends IntakeEvent {
  const new();
}

/// Forget the session (sign-out, expired sign-in, or "Start again").
final class IntakeReset extends IntakeEvent {
  const new();
}
