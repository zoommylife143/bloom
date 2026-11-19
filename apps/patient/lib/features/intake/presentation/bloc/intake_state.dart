part of 'intake_bloc.dart';

/// P01-P04 intake state. Every variant carries the [conversation] so the chat
/// keeps its transcript through waiting, errors and the urgent hand-off.
@freezed
sealed class IntakeState with _$IntakeState {
  /// No request in flight. Before Start the conversation has no session.
  const factory idle({
    @Default(IntakeConversation.empty) IntakeConversation conversation,
  }) = IntakeIdle;

  /// Creating the session (P01 "Starting…").
  const factory sending({
    @Default(IntakeConversation.empty) IntakeConversation conversation,
  }) = IntakeSending;

  /// The patient's answer is in the transcript; waiting for Bloom's reply
  /// (P02 typing indicator, state 10:23).
  const factory waiting({
    required IntakeConversation conversation,
    required String pendingText,
  }) = IntakeWaiting;

  /// Start or send failed (P02 model error 23:71, network, expired sign-in).
  /// [pendingText] is the unsaved answer to resend; null if starting failed.
  const factory error({
    required IntakeConversation conversation,
    required AppFailure failure,
    String? pendingText,
  }) = IntakeError;

  /// Private mode refused before inference; no fallback model was called
  /// (P02 route refused 6:87). [pendingText] is resent on "Try again".
  const factory routeRefused({
    required IntakeConversation conversation,
    String? pendingText,
  }) = IntakeRouteRefused;

  /// A server red-flag rule fired. The chat is locked; show P03.
  const factory urgent({
    required IntakeConversation conversation,
    required UrgentMessage message,
  }) = IntakeUrgent;

  /// Intake finished; show P04.
  const factory done({required IntakeConversation conversation}) = IntakeDone;

  /// The server says the session no longer takes messages (HTTP 409); show
  /// P04.
  const factory locked({required IntakeConversation conversation}) =
      IntakeLocked;
}

extension IntakeStateX on IntakeState {
  /// The patient flow has ended; the chat must not reopen.
  bool get isFinished => switch (this) {
    IntakeUrgent() || IntakeDone() || IntakeLocked() => true,
    _ => false,
  };
}
