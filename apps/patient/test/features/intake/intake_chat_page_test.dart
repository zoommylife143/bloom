import 'package:bloom_patient/features/intake/domain/intake_conversation.dart';
import 'package:bloom_patient/features/intake/presentation/bloc/intake_bloc.dart';
import 'package:bloom_patient/features/intake/presentation/pages/intake_chat_page.dart';
import 'package:bloom_patient/features/intake/presentation/widgets/typing_indicator.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

// Synthetic transcript.
const _question =
    'Is there any chance you could be pregnant? You can skip this.';
const _answer = 'About three weeks ago.';
const _slowReply = 'Still working on it. This can take up to a minute.';

const _conversation = IntakeConversation(
  sessionId: 'synthetic',
  mode: RouteMode.private,
  progress: 0.5,
  messages: [
    IntakeMessage.bloom('Hi, I am Bloom. What brings you in today?'),
    IntakeMessage.patient('A checkup.'),
    IntakeMessage.bloom(_question),
  ],
);

final IntakeConversation _answered = _conversation.addMessage(
  const IntakeMessage.patient(_answer),
);

void main() {
  setUpAll(registerPatientFallbacks);

  late MockIntakeBloc bloc;

  setUp(() => bloc = MockIntakeBloc());

  Future<void> pump(
    WidgetTester tester,
    IntakeState state, {
    bool settle = true,
  }) async {
    when(() => bloc.state).thenReturn(state);
    await tester.pumpPage(
      const IntakeChatPage(),
      intakeBloc: bloc,
      settle: settle,
    );
  }

  group('P02 IntakeChatPage', () {
    testWidgets('default: transcript, progress, quick replies, trust note', (
      tester,
    ) async {
      await pump(tester, const IntakeState.idle(conversation: _conversation));

      expect(find.text('Question 2 of about 10'), findsOneWidget);
      expect(find.byType(ChatBubble), findsNWidgets(3));
      expect(find.text('OPTIONAL QUESTION'), findsOneWidget);
      for (final chip in ['Yes', 'No', 'Not sure', 'Skip']) {
        expect(find.widgetWithText(ActionChip, chip), findsOneWidget);
      }
      expect(
        find.text('Confidential inference · private demo mode'),
        findsOneWidget,
      );
      expect(find.text('Type your answer'), findsOneWidget);
      expect(find.byType(TypingIndicator), findsNothing);
    });

    testWidgets('dev mode trust note never says confidential', (tester) async {
      await pump(
        tester,
        IntakeState.idle(
          conversation: _conversation.copyWith(mode: RouteMode.dev),
        ),
      );
      expect(
        find.text('Dev mode · zero-data-retention AI route, not confidential'),
        findsOneWidget,
      );
    });

    testWidgets('quick reply sends its text', (tester) async {
      await pump(tester, const IntakeState.idle(conversation: _conversation));
      await tester.tap(find.widgetWithText(ActionChip, 'Not sure'));
      verify(() => bloc.add(const IntakeMessageSubmitted('Not sure')))
          .called(1);
    });

    testWidgets('typing and Send submits the answer', (tester) async {
      await pump(tester, const IntakeState.idle(conversation: _conversation));
      await tester.enterText(find.byType(TextField), 'No');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Send answer'));
      verify(() => bloc.add(const IntakeMessageSubmitted('No'))).called(1);
    });

    testWidgets('waiting: typing indicator, no chips, send disabled', (
      tester,
    ) async {
      await pump(
        tester,
        IntakeState.waiting(conversation: _answered, pendingText: _answer),
      );
      expect(find.byType(TypingIndicator), findsOneWidget);
      expect(
        find.bySemanticsLabel('Bloom is writing the next question'),
        findsOneWidget,
      );
      expect(find.byType(ActionChip), findsNothing);
      expect(find.text(_answer), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'More');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Send answer'));
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('route refused: paused card, composer paused, Try again', (
      tester,
    ) async {
      await pump(
        tester,
        IntakeState.routeRefused(conversation: _answered, pendingText: _answer),
      );
      expect(find.text('Paused to protect your privacy'), findsOneWidget);
      expect(
        find.textContaining('paused instead of using a less private one'),
        findsOneWidget,
      );
      expect(find.text('Paused'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);

      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const IntakeRetried())).called(1);
    });

    testWidgets('model error: error card with Try again', (tester) async {
      await pump(
        tester,
        IntakeState.error(
          conversation: _answered,
          failure: const AppFailure.server(
            statusCode: 502,
            message: 'model_error',
          ),
          pendingText: _answer,
        ),
      );
      expect(find.text('Something went wrong on our side'), findsOneWidget);
      expect(
        find.text('Your answers are saved. Please try again in a moment.'),
        findsOneWidget,
      );
      expect(find.text('Paused'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const IntakeRetried())).called(1);
    });

    testWidgets('lost session (404) offers Start again', (tester) async {
      await pump(
        tester,
        IntakeState.error(
          conversation: _answered,
          failure: const AppFailure.notFound('session_not_found'),
          pendingText: _answer,
        ),
      );
      await tester.tap(find.text('Start again'));
      verify(() => bloc.add(const IntakeReset())).called(1);
    });

    testWidgets('slow reply: a still-working note after 12 s', (tester) async {
      await pump(
        tester,
        IntakeState.waiting(conversation: _answered, pendingText: _answer),
      );
      expect(find.text(_slowReply), findsNothing);
      await tester.pump(const Duration(seconds: 13));
      expect(find.text(_slowReply), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('client timeout says try again, not check your connection', (
      tester,
    ) async {
      await pump(
        tester,
        IntakeState.error(
          conversation: _answered,
          failure: const AppFailure.network('timeout'),
          pendingText: _answer,
        ),
      );
      expect(
        find.text('Your answers are saved. Please try again in a moment.'),
        findsOneWidget,
      );
      expect(find.byType(TypingIndicator), findsNothing);
    });

    testWidgets('network failure says check your connection', (tester) async {
      await pump(
        tester,
        IntakeState.error(
          conversation: _answered,
          failure: const AppFailure.network('XMLHttpRequest error'),
          pendingText: _answer,
        ),
      );
      expect(find.textContaining('Check your connection'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const IntakeRetried())).called(1);
    });

    testWidgets('double tap on Send submits once', (tester) async {
      await pump(tester, const IntakeState.idle(conversation: _conversation));
      await tester.enterText(find.byType(TextField), 'No');
      await tester.pump();
      final send = find.bySemanticsLabel('Send answer');
      await tester.tap(send);
      await tester.tap(send);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      verify(() => bloc.add(const IntakeMessageSubmitted('No'))).called(1);
    });

    testWidgets('tablet keeps a centered 480 column', (tester) async {
      tester.useSize(tabletSize);
      when(() => bloc.state)
          .thenReturn(const IntakeState.idle(conversation: _conversation));
      await tester.pumpPage(const IntakeChatPage(), intakeBloc: bloc);
      final header = tester.getRect(find.text('Question 2 of about 10'));
      expect(header.right, lessThanOrEqualTo(768 - 144 + 1));
    });

    testWidgets('tap targets are at least 44 px', (tester) async {
      await pump(tester, const IntakeState.idle(conversation: _conversation));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });
}
