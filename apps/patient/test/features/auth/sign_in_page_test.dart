import 'package:bloc_test/bloc_test.dart';
import 'package:bloom_patient/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:bloom_patient/features/auth/presentation/pages/sign_in_page.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

void main() {
  late MockSessionRepository sessions;

  setUp(() {
    sessions = MockSessionRepository();
    when(() => sessions.health()).thenAnswer(
      (_) async => const Result.ok(HealthStatus(ok: true, mode: RouteMode.dev)),
    );
  });

  group('AuthCubit', () {
    blocTest<AuthCubit, AuthState>(
      'signIn logs in as patient and reads the mode',
      setUp: () =>
          when(() => sessions.login(BloomRole.patient))
              .thenAnswer((_) async => const Result.ok(null)),
      build: () => AuthCubit(sessions: sessions),
      act: (cubit) => cubit.signIn(),
      expect: () => const [
        AuthState(status: AuthStatus.signingIn),
        AuthState(status: AuthStatus.signedIn, mode: RouteMode.dev),
      ],
      verify: (_) => verify(() => sessions.login(BloomRole.patient)).called(1),
    );

    blocTest<AuthCubit, AuthState>(
      'signIn failure keeps the patient signed out',
      setUp: () =>
          when(() => sessions.login(BloomRole.patient))
              .thenAnswer((_) async => const Result.err(AppFailure.network())),
      build: () => AuthCubit(sessions: sessions),
      act: (cubit) => cubit.signIn(),
      expect: () => const [
        AuthState(status: AuthStatus.signingIn),
        AuthState(failure: AppFailure.network()),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'expire signs out with a note',
      build: () => AuthCubit(
        sessions: sessions,
        initialState: const AuthState(status: AuthStatus.signedIn),
      ),
      act: (cubit) => cubit.expire(),
      expect: () => const [AuthState(expired: true)],
    );
  });

  group('A01 SignInPage', () {
    testWidgets('Figma copy and demo banner', (tester) async {
      await tester.pumpPage(
        const SignInPage(),
        authCubit: AuthCubit(sessions: sessions),
      );
      expect(find.text('Sign in to the demo'), findsOneWidget);
      expect(
        find.text('Demo · do not enter real health information'),
        findsOneWidget,
      );
      expect(find.text('Continue as patient'), findsOneWidget);
      expect(find.text('Continue as clinician'), findsOneWidget);
      expect(
        find.text(
          'Demo login only. This is not production authentication. '
          'Synthetic data only.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Continue as patient signs in', (tester) async {
      when(() => sessions.login(BloomRole.patient))
          .thenAnswer((_) async => const Result.ok(null));
      final cubit = AuthCubit(sessions: sessions);
      await tester.pumpPage(const SignInPage(), authCubit: cubit);
      await tester.tap(find.text('Continue as patient'));
      await tester.pumpAndSettle();
      expect(cubit.state.isSignedIn, isTrue);
    });

    testWidgets('Continue as clinician opens the clinic app', (tester) async {
      var opened = false;
      await tester.pumpPage(
        SignInPage(openClinic: () => opened = true),
        authCubit: AuthCubit(sessions: sessions),
      );
      await tester.tap(find.text('Continue as clinician'));
      expect(opened, isTrue);
    });

    testWidgets('shows the expired and error notes', (tester) async {
      await tester.pumpPage(
        const SignInPage(),
        authCubit: AuthCubit(
          sessions: sessions,
          initialState: const AuthState(
            expired: true,
            failure: AppFailure.server(statusCode: 500),
          ),
        ),
      );
      expect(
        find.text('Your demo sign-in ended. Please sign in again.'),
        findsOneWidget,
      );
      expect(
        find.text('Something went wrong on our side. Please try again.'),
        findsOneWidget,
      );
    });
  });
}
