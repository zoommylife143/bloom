import 'package:bloom_patient/app/view/widgets/content_column.dart';
import 'package:bloom_patient/features/intake/domain/intake_conversation.dart';
import 'package:bloom_patient/features/intake/domain/question_hints.dart';
import 'package:bloom_patient/features/intake/presentation/bloc/intake_bloc.dart';
import 'package:bloom_patient/features/intake/presentation/widgets/intake_error_card.dart';
import 'package:bloom_patient/features/intake/presentation/widgets/intake_header.dart';
import 'package:bloom_patient/features/intake/presentation/widgets/message_composer.dart';
import 'package:bloom_patient/features/intake/presentation/widgets/trust_note.dart';
import 'package:bloom_patient/features/intake/presentation/widgets/typing_indicator.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// P02 Intake chat (Figma 6:40; waiting 10:23, route refused 6:87, model
/// error 23:71, tablet 23:108). The router leaves this page for P03 or P04
/// as soon as the bloc reports urgent, done or locked.
class IntakeChatPage extends StatefulWidget {
  const new({super.key});

  /// Screen ID = Figma frame name = go_router route name.
  static const screenId = 'P02';

  /// Path inside the app. Public URL: `/intake/chat` (base href
  /// `/intake/`).
  static const path = '/chat';

  @override
  State<IntakeChatPage> createState() => _IntakeChatPageState();
}

class _IntakeChatPageState extends State<IntakeChatPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToEnd();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
        return;
      }
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IntakeBloc, IntakeState>(
      listener: (context, state) => _scrollToEnd(),
      builder: (context, state) {
        final conversation = state.conversation;
        final bloc = context.read<IntakeBloc>();
        final paused = state is IntakeError || state is IntakeRouteRefused;
        final header = _clampText(
          IntakeHeader(
            questionNumber: conversation.questionNumber,
            progress: conversation.progress,
          ),
        );
        final trustNote = _clampText(TrustNote(mode: conversation.mode));
        return Scaffold(
          body: SafeArea(
            child: ContentColumn(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Short viewports (on-screen keyboard open, landscape
                  // phones, large text) scroll the header and trust note with
                  // the transcript so the answer field and the latest message
                  // stay visible instead of overflowing.
                  final compact =
                      constraints.maxHeight < _compactBelow(context);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: BloomSpacing.lg,
                    children: [
                      if (!compact) header,
                      Expanded(
                        child: _MessageList(
                          state: state,
                          controller: _scroll,
                          leading: compact ? header : null,
                          trailing: compact ? trustNote : null,
                          onQuickReply: (text) =>
                              bloc.add(IntakeMessageSubmitted(text)),
                          onRetry: () => bloc.add(const IntakeRetried()),
                          onStartAgain: () => bloc.add(const IntakeReset()),
                        ),
                      ),
                      _clampText(
                        MessageComposer(
                          paused: paused,
                          canSend: state is IntakeIdle,
                          onSend: (text) =>
                              bloc.add(IntakeMessageSubmitted(text)),
                        ),
                      ),
                      if (!compact) trustNote,
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Chrome (header, composer, trust note) grows with the text scale up to
  /// 1.5x; the transcript itself scales without limit.
  static const _chromeMaxTextScale = 1.5;

  static Widget _clampText(Widget child) => Builder(
    builder: (context) => MediaQuery.withClampedTextScaling(
      maxScaleFactor: _chromeMaxTextScale,
      child: child,
    ),
  );

  /// Height under which the header and trust note scroll with the
  /// transcript: room for the pinned chrome plus about four lines of chat.
  static double _compactBelow(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: _chromeMaxTextScale)
        .scale(1);
    return 200 * scale + 160;
  }
}

class _MessageList extends StatelessWidget {
  const new({
    required this.state,
    required this.controller,
    required this.onQuickReply,
    required this.onRetry,
    required this.onStartAgain,
    this.leading,
    this.trailing,
  });

  /// `NetworkFailure.message` core_data uses for a client-side timeout.
  static const _timeoutCode = 'timeout';

  /// Figma ChatBubble width.
  static const bubbleWidth = 280.0;

  final IntakeState state;
  final ScrollController controller;

  /// Scrolls above the transcript (compact layout: the header).
  final Widget? leading;

  /// Scrolls below the transcript (compact layout: the trust note).
  final Widget? trailing;
  final ValueChanged<String> onQuickReply;
  final VoidCallback onRetry;
  final VoidCallback onStartAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final messages = state.conversation.messages;
    final question = state.conversation.pendingQuestion;
    final hints = question == null ? null : QuestionHints.of(question);
    final lastBloom = messages.lastIndexWhere(
      (m) => m.author == IntakeAuthor.bloom,
    );

    final children = <Widget>[
      ?leading,
      for (final (i, message) in messages.indexed)
        _Bubble(
          message: message,
          isOptional: i == lastBloom && (hints?.isOptional ?? false),
          optionalLabel: l10n.patientChatOptional,
        ),
      if (state is IntakeIdle && (hints?.quickReplies.isNotEmpty ?? false))
        Align(
          alignment: Alignment.centerLeft,
          child: QuickReply(
            options: hints!.quickReplies,
            semanticLabel: l10n.patientChatQuickReplies,
            onSelected: onQuickReply,
          ),
        ),
      if (state is IntakeWaiting) const TypingIndicator(),
      ?_errorCard(context),
      ?trailing,
    ];

    // The transcript is short (about ten questions), so build it all: screen
    // readers and find-in-page see every line.
    return SingleChildScrollView(
      controller: controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: BloomSpacing.md,
        children: children,
      ),
    );
  }

  Widget? _errorCard(BuildContext context) {
    final l10n = context.l10n;
    return switch (state) {
      IntakeRouteRefused() => IntakeErrorCard(
        title: l10n.patientChatRefusedTitle,
        body: l10n.patientChatRefusedBody,
        actionLabel: l10n.patientChatTryAgain,
        onAction: onRetry,
      ),
      IntakeError(failure: NotFoundFailure()) => IntakeErrorCard(
        title: l10n.patientChatSessionLostTitle,
        body: l10n.patientChatSessionLostBody,
        actionLabel: l10n.patientChatStartAgain,
        onAction: onStartAgain,
      ),
      IntakeError(:final failure) => IntakeErrorCard(
        title: l10n.patientChatErrorTitle,
        // A client timeout means the model was slow, not that the patient
        // is offline: say "try again in a moment", not "check your
        // connection".
        body: failure is NetworkFailure && failure.message != _timeoutCode
            ? l10n.patientChatNetworkErrorBody
            : l10n.patientChatErrorBody,
        actionLabel: l10n.patientChatTryAgain,
        onAction: onRetry,
      ),
      _ => null,
    };
  }
}

class _Bubble extends StatelessWidget {
  const new({
    required this.message,
    required this.isOptional,
    required this.optionalLabel,
  });

  final IntakeMessage message;
  final bool isOptional;
  final String optionalLabel;

  @override
  Widget build(BuildContext context) {
    final isBloom = message.author == IntakeAuthor.bloom;
    return Align(
      alignment: isBloom ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _MessageList.bubbleWidth),
        child: ChatBubble(
          text: message.text,
          author: isBloom ? ChatAuthor.bloom : ChatAuthor.patient,
          isOptional: isOptional,
          optionalLabel: optionalLabel,
        ),
      ),
    );
  }
}
