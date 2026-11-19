import 'package:bloc/bloc.dart';
import 'package:bloom_patient/features/intake/domain/intake_conversation.dart';
import 'package:core_domain/core_domain.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'intake_bloc.freezed.dart';
part 'intake_event.dart';
part 'intake_state.dart';

/// Drives P01-P04: starts the session, sends answers and moves to urgent or
/// done from the server's reply. Red-flag rules run only on the server; this
/// bloc only follows `status` and `urgent`.
class IntakeBloc extends Bloc<IntakeEvent, IntakeState> {
  new({required this._repository, String Function()? clientMessageIdFactory})
    : _newClientMessageId =
          clientMessageIdFactory ?? _defaultClientMessageIdFactory(),
      super(const IntakeState.idle()) {
    on<IntakeStarted>(_onStarted);
    on<IntakeMessageSubmitted>(_onSubmitted);
    on<IntakeRetried>(_onRetried);
    on<IntakeReset>((event, emit) {
      _generation++;
      _clientMessageId = null;
      emit(const IntakeState.idle());
    });
  }

  /// Used only if the server says `urgent` without a payload (contract says
  /// it always sends one). Fixed copy, no model involved.
  static const fallbackUrgent = UrgentMessage(
    title: 'Please get care now',
    body: 'Please call 911 or go to the nearest emergency department now.',
    actions: [
      UrgentAction(label: 'Call 911', tel: 'tel:911'),
      UrgentAction(label: 'Call or text 988', tel: 'tel:988'),
    ],
  );

  final IntakeRepository _repository;

  /// Makes one id per patient turn. Not derived from the answer (no PHI).
  final String Function() _newClientMessageId;

  /// The id of the turn in flight or awaiting "Try again". Resent unchanged
  /// on retry so the server returns its stored reply instead of calling the
  /// model twice (e.g. the reply landed after the client timed out).
  String? _clientMessageId;

  /// `<microseconds since epoch>-<counter>`: unique per tab, no content.
  static String Function() _defaultClientMessageIdFactory() {
    var counter = 0;
    return () => 'c${DateTime.now().microsecondsSinceEpoch}-${counter++}';
  }

  /// Bumped by [IntakeReset]. A reply that arrives after a reset (sign-out,
  /// expired sign-in, "Start again") belongs to a conversation the patient
  /// left, even if a new request is in flight by then, so it is dropped.
  int _generation = 0;

  Future<void> _onStarted(
    IntakeStarted event,
    Emitter<IntakeState> emit,
  ) async {
    if (state is IntakeSending || state.conversation.hasSession) return;
    await _start(emit);
  }

  Future<void> _start(Emitter<IntakeState> emit) async {
    final generation = _generation;
    emit(const IntakeState.sending());
    final result = await _repository.startSession();
    if (generation != _generation || state is! IntakeSending) return;
    switch (result) {
      case Ok(:final value):
        emit(
          IntakeState.idle(
            conversation: IntakeConversation(
              sessionId: value.sessionId,
              mode: value.mode,
              progress: value.progress,
              messages: [
                if (value.reply.isNotEmpty) IntakeMessage.bloom(value.reply),
              ],
            ),
          ),
        );
      case Err(:final failure):
        emit(
          IntakeState.error(
            conversation: IntakeConversation.empty,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onSubmitted(
    IntakeMessageSubmitted event,
    Emitter<IntakeState> emit,
  ) async {
    final text = event.text.trim();
    // Only from idle: one answer in flight at a time, nothing after the end,
    // and errors are cleared with "Try again" (the unsaved answer is resent).
    if (text.isEmpty || state is! IntakeIdle) return;
    if (!state.conversation.hasSession) return;
    final conversation = state.conversation.addMessage(
      IntakeMessage.patient(text),
    );
    _clientMessageId = _newClientMessageId();
    await _send(conversation, text, emit);
  }

  Future<void> _onRetried(
    IntakeRetried event,
    Emitter<IntakeState> emit,
  ) async {
    final (conversation, pending) = switch (state) {
      IntakeError(:final conversation, :final pendingText) => (
        conversation,
        pendingText,
      ),
      IntakeRouteRefused(:final conversation, :final pendingText) => (
        conversation,
        pendingText,
      ),
      _ => (null, null),
    };
    if (conversation == null) return;
    if (!conversation.hasSession) {
      await _start(emit);
      return;
    }
    if (pending == null) {
      emit(IntakeState.idle(conversation: conversation));
      return;
    }
    // The answer is already in the transcript; resend without repeating it,
    // under the same client message id so the retry is idempotent.
    _clientMessageId ??= _newClientMessageId();
    await _send(conversation, pending, emit);
  }

  Future<void> _send(
    IntakeConversation conversation,
    String text,
    Emitter<IntakeState> emit,
  ) async {
    final generation = _generation;
    emit(IntakeState.waiting(conversation: conversation, pendingText: text));
    final result = await _repository.sendMessage(
      sessionId: conversation.sessionId!,
      text: text,
      clientMessageId: _clientMessageId,
    );
    // A reset (sign-out) while waiting wins over a late reply.
    if (generation != _generation || state is! IntakeWaiting) return;

    // Every outcome except a retryable error ends this turn.
    if (result case Ok() || Err(failure: LockedFailure())) {
      _clientMessageId = null;
    }

    switch (result) {
      case Ok(value: final turn):
        final next = conversation.copyWith(progress: turn.progress);
        switch (turn.status) {
          case SessionStatus.urgent:
            emit(
              IntakeState.urgent(
                conversation: next,
                message: turn.urgent ?? fallbackUrgent,
              ),
            );
          case SessionStatus.inProgress when !turn.done:
            emit(IntakeState.idle(conversation: _withReply(next, turn.reply)));
          case _:
            emit(IntakeState.done(conversation: _withReply(next, turn.reply)));
        }
      case Err(failure: RouteRefusedFailure()):
        emit(
          IntakeState.routeRefused(
            conversation: conversation,
            pendingText: text,
          ),
        );
      // The session already ended urgent (e.g. a red flag fired on a turn
      // whose reply was lost to a timeout). Show P03, never P04 "Thank you".
      case Err(
        failure: LockedFailure(status: SessionStatus.urgent, :final urgent),
      ):
        emit(
          IntakeState.urgent(
            conversation: conversation,
            message: urgent ?? fallbackUrgent,
          ),
        );
      // Done, brief ready or reviewed, or an older 409 without a status: P04.
      case Err(failure: LockedFailure()):
        emit(IntakeState.locked(conversation: conversation));
      case Err(:final failure):
        emit(
          IntakeState.error(
            conversation: conversation,
            failure: failure,
            pendingText: text,
          ),
        );
    }
  }

  /// Adds Bloom's reply, skipping an empty one (no blank bubble).
  static IntakeConversation _withReply(IntakeConversation c, String reply) =>
      reply.trim().isEmpty ? c : c.addMessage(IntakeMessage.bloom(reply));
}
