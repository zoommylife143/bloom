import 'package:core_domain/core_domain.dart';
import 'package:equatable/equatable.dart';

/// Who wrote a line of the intake chat.
enum IntakeAuthor { bloom, patient }

/// One line of the intake chat as the patient sees it. Lives only in memory.
class IntakeMessage extends Equatable {
  const new({required this.author, required this.text});

  const new bloom(this.text) : author = IntakeAuthor.bloom;

  const new patient(this.text) : author = IntakeAuthor.patient;

  final IntakeAuthor author;
  final String text;

  @override
  List<Object?> get props => [author, text];
}

/// The running intake: the server session, the transcript and progress.
/// Carried by every `IntakeState`.
class IntakeConversation extends Equatable {
  const new({
    this.sessionId,
    this.mode,
    this.messages = const [],
    this.progress = 0,
  });

  /// No session yet (P01).
  static const empty = IntakeConversation();

  final String? sessionId;

  /// Routing mode the server reported when the session started.
  final RouteMode? mode;
  final List<IntakeMessage> messages;

  /// 0-1, from the server (`progress`). Never goes backwards.
  final double progress;

  bool get hasSession => sessionId != null;

  /// How many questions Bloom has asked so far (its messages).
  int get questionNumber =>
      messages.where((m) => m.author == IntakeAuthor.bloom).length;

  /// Bloom's latest message if it is the last line, else null.
  String? get pendingQuestion {
    if (messages.isEmpty) return null;
    final last = messages.last;
    return last.author == IntakeAuthor.bloom ? last.text : null;
  }

  IntakeConversation addMessage(IntakeMessage message) =>
      copyWith(messages: [...messages, message]);

  IntakeConversation copyWith({
    String? sessionId,
    RouteMode? mode,
    List<IntakeMessage>? messages,
    double? progress,
  }) => IntakeConversation(
    sessionId: sessionId ?? this.sessionId,
    mode: mode ?? this.mode,
    messages: messages ?? this.messages,
    progress: progress == null
        ? this.progress
        : (progress > this.progress ? progress : this.progress).clamp(0, 1),
  );

  @override
  List<Object?> get props => [sessionId, mode, messages, progress];
}
