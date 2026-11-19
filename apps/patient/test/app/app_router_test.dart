import 'package:bloc_test/bloc_test.dart';
import 'package:bloom_patient/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:bloom_patient/features/intake/domain/intake_conversation.dart';
import 'package:bloom_patient/features/intake/presentation/bloc/intake_bloc.dart';
import 'package:bloom_patient/features/intake/presentation/pages/intake_chat_page.dart';
import 'package:bloom_patient/features/urgent/presentation/pages/urgent_page.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_app.dart';

String _location(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold).first);
  return GoRouter.of(context).state.matchedLocation;
}

Future<void> _signIn(WidgetTester tester) async {
  await tester.tap(find.text('Continue as patient'));
  await tester.pumpAndSettle();
}

Future<void> _consentAndStart(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(Checkbox));
  await tester.tap(find.byType(Checkbox));
  await tester.pump();
  await tester.tap(find.text('Start'));
  await tester.pumpAndSettle();
}

Future<void> _answer(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.bySemanticsLabel('Send answer'));
  await tester.pumpAndSettle();
}

const _session = IntakeConversation(sessionId: 'synthetic');

void main() {
  setUpAll(registerPatientFallbacks);

  group('redirects', () {
    for (final path in ['/', '/chat', '/urgent', '/done']) {
      testWidgets('signed out: $path → A01', (tester) async {
        await tester.pumpApp(initialLocation: path);
        expect(_location(tester), '/sign-in');
        expect(find.text('Sign in to the demo'), findsOneWidget);
      });
    }

    testWidgets('signed in, no session: /chat → P01', (tester) async {
      final repos = BloomRepositories.fake();
      await tester.pumpApp(
        initialLocation: '/chat',
        repositories: repos,
        authCubit: AuthCubit(
          sessions: repos.session,
          initialState: const AuthState(status: AuthStatus.signedIn),
        ),
      );
      expect(_location(tester), '/');
      expect(find.text('Before your gynecology visit'), findsOneWidget);
    });

    testWidgets('urgent: / and /chat → P03; /done allowed', (tester) async {
      final repos = BloomRepositories.fake();
      final intake = MockIntakeBloc();
      const state = IntakeState.urgent(
        conversation: _session,
        message: IntakeBloc.fallbackUrgent,
      );
      when(() => intake.state).thenReturn(state);
      await tester.pumpApp(
        initialLocation: '/chat',
        repositories: repos,
        intakeBloc: intake,
        authCubit: AuthCubit(
          sessions: repos.session,
          initialState: const AuthState(status: AuthStatus.signedIn),
        ),
      );
      expect(_location(tester), UrgentPage.path);

      final router = GoRouter.of(tester.element(find.byType(Scaffold).first))
        ..go(IntakeChatPage.path);
      await tester.pumpAndSettle();
      expect(_location(tester), UrgentPage.path);

      router.goNamed('P04');
      await tester.pumpAndSettle();
      expect(_location(tester), '/done');
    });

    for (final path in ['/chat', '/urgent', '/done']) {
      testWidgets('reload on $path (token lost) → A01 → sign in → fresh P01', (
        tester,
      ) async {
        // A reload builds a new App: in-memory token and intake are gone.
        tester.useSize(phoneSize);
        await tester.pumpApp(initialLocation: path);
        expect(_location(tester), '/sign-in');
        expect(
          find.text('Your demo sign-in ended. Please sign in again.'),
          findsNothing,
        );
        await _signIn(tester);
        expect(_location(tester), '/');
        expect(find.text('Start'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('unknown paths show the not found page', (tester) async {
      await tester.pumpApp(initialLocation: '/no-such-screen');
      expect(find.text('Page not found'), findsOneWidget);
    });

    testWidgets('uses the Bloom theme', (tester) async {
      await tester.pumpApp();
      final context = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(context).colorScheme.primary, BloomColors.actionPrimary);
    });
  });

  group('end to end over the synthetic fakes', () {
    testWidgets('S1-style happy path: A01 → P01 → P02 → P04', (tester) async {
      tester.useSize(phoneSize);
      await tester.pumpApp();
      await _signIn(tester);
      expect(_location(tester), '/');

      await _consentAndStart(tester);
      expect(_location(tester), '/chat');
      expect(
        find.text('Hello, I am Bloom. What brings you in today?'),
        findsOneWidget,
      );

      await _answer(tester, 'I would like a checkup.');
      await _answer(tester, 'A few months.');
      expect(find.widgetWithText(ActionChip, 'Not sure'), findsOneWidget);
      await tester.tap(find.widgetWithText(ActionChip, 'No'));
      await tester.pumpAndSettle();

      expect(_location(tester), '/done');
      expect(find.text('Thank you'), findsOneWidget);

      // Back to the chat is not possible once finished.
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/chat');
      await tester.pumpAndSettle();
      expect(_location(tester), '/done');
    });

    testWidgets('urgent path: P02 → P03 → I understand → P04', (tester) async {
      tester.useSize(phoneSize);
      await tester.pumpApp();
      await _signIn(tester);
      await _consentAndStart(tester);

      await _answer(tester, 'Sharp pain and I feel dizzy.');
      expect(_location(tester), '/urgent');
      expect(find.text('Please get care now'), findsOneWidget);
      expect(find.text('Call 911'), findsOneWidget);

      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();
      expect(_location(tester), '/done');
    });

    testWidgets('401 sends the patient back to A01', (tester) async {
      final repos = BloomRepositories.fake();
      final intake = MockIntakeBloc();
      whenListen(
        intake,
        Stream.value(
          const IntakeState.error(
            conversation: IntakeConversation.empty,
            failure: AppFailure.server(statusCode: 401),
          ),
        ),
        initialState: const IntakeState.idle(),
      );
      await tester.pumpApp(
        repositories: repos,
        intakeBloc: intake,
        authCubit: AuthCubit(
          sessions: repos.session,
          initialState: const AuthState(status: AuthStatus.signedIn),
        ),
      );
      expect(_location(tester), '/sign-in');
      expect(
        find.text('Your demo sign-in ended. Please sign in again.'),
        findsOneWidget,
      );
      verify(() => intake.add(const IntakeReset())).called(1);
    });
  });
}
