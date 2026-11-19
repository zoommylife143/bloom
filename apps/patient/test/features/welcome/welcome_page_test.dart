import 'package:bloom_patient/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:bloom_patient/features/intake/domain/intake_conversation.dart';
import 'package:bloom_patient/features/intake/presentation/bloc/intake_bloc.dart';
import 'package:bloom_patient/features/welcome/presentation/pages/welcome_page.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(registerPatientFallbacks);

  late MockIntakeBloc bloc;

  setUp(() => bloc = MockIntakeBloc());

  Future<void> pump(
    WidgetTester tester,
    IntakeState state, {
    RouteMode mode = RouteMode.dev,
  }) async {
    when(() => bloc.state).thenReturn(state);
    final auth = MockAuthCubit();
    when(() => auth.state)
        .thenReturn(AuthState(status: AuthStatus.signedIn, mode: mode));
    await tester.pumpPage(
      const WelcomePage(),
      intakeBloc: bloc,
      authCubit: auth,
    );
  }

  group('P01 WelcomePage', () {
    testWidgets('Figma copy and demo banner', (tester) async {
      await pump(tester, const IntakeState.idle());
      expect(find.text('Before your gynecology visit'), findsOneWidget);
      expect(
        find.text('Demo · do not enter real health information'),
        findsOneWidget,
      );
      expect(find.text('How this conversation is protected'), findsOneWidget);
      expect(
        find.text(
          'Guideline lookups never include your name or personal details.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('never says HIPAA or secure', (tester) async {
      await pump(tester, const IntakeState.idle());
      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ')
          .toLowerCase();
      expect(text, isNot(contains('hipaa')));
      expect(text, isNot(contains('secure')));
    });

    testWidgets('privacy point 1 is literal per mode', (tester) async {
      await pump(tester, const IntakeState.idle());
      expect(find.textContaining('zero data retention'), findsOneWidget);
      expect(find.textContaining('confidential AI'), findsNothing);

      await pump(tester, const IntakeState.idle(), mode: RouteMode.private);
      expect(
        find.text(
          'Your answers are processed on confidential AI infrastructure.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Start is disabled until consent is given', (tester) async {
      await pump(tester, const IntakeState.idle());
      await tester.tap(find.text('Start'));
      verifyNever(() => bloc.add(any()));

      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Start'));
      verify(() => bloc.add(const IntakeStarted())).called(1);
    });

    testWidgets('loading shows Starting…', (tester) async {
      await pump(tester, const IntakeState.sending());
      expect(find.text('Starting…'), findsOneWidget);
    });

    testWidgets('start failure shows an error and Start retries', (
      tester,
    ) async {
      await pump(
        tester,
        const IntakeState.error(
          conversation: IntakeConversation.empty,
          failure: AppFailure.server(statusCode: 500),
        ),
      );
      expect(
        find.text('Something went wrong on our side. Please try again.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Start'));
      verify(() => bloc.add(const IntakeRetried())).called(1);
    });
  });
}
