import 'package:bloc_test/bloc_test.dart';
import 'package:bloom_clinic/features/audit/presentation/pages/audit_page.dart';
import 'package:bloom_clinic/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bloom_clinic/features/auth/presentation/pages/sign_in_page.dart';
import 'package:bloom_clinic/features/queue/presentation/pages/queue_page.dart';
import 'package:core_data/core_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/display_size.dart';
import '../../helpers/pump_app.dart';

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .state
        .matchedLocation;

void main() {
  group('AuthCubit', () {
    blocTest<AuthCubit, AuthState>(
      'signIn with a blank name uses the synthetic reviewer',
      build: () => AuthCubit(FakeSessionRepository()),
      act: (cubit) => cubit.signIn(reviewerName: '  '),
      expect: () => const [
        AuthState(status: AuthStatus.signingIn),
        AuthState(status: AuthStatus.signedIn),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'signOut keeps the reviewer name',
      build: () => AuthCubit(FakeSessionRepository(), signedIn: true),
      act: (cubit) => cubit.signOut(),
      expect: () => const [AuthState()],
    );
  });

  group('A01 sign in', () {
    for (final (name, size) in [
      ('desktop', DisplaySizes.desktop),
      ('phone', DisplaySizes.phone),
    ]) {
      testWidgets('signs in and lands on D01 on $name', (tester) async {
        tester.setDisplaySize(size);
        await tester.pumpApp(signedIn: false);
        expect(find.byType(SignInPage), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Dr. Synthetic');
        await tester.tap(find.text('Continue as clinician'));
        await tester.pumpAndSettle();

        expect(find.byType(QueuePage), findsOneWidget);
        expect(_location(tester), '/');
        final auth = tester
            .element(find.byType(QueuePage))
            .read<AuthCubit>()
            .state;
        expect(auth.isSignedIn, isTrue);
        expect(auth.reviewerName, 'Dr. Synthetic');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('returns to the deep link after sign-in', (tester) async {
      tester.setDisplaySize(DisplaySizes.desktop);
      await tester.pumpApp(initialLocation: AuditPage.path, signedIn: false);

      await tester.tap(find.text('Continue as clinician'));
      await tester.pumpAndSettle();

      expect(find.byType(AuditPage), findsOneWidget);
      expect(_location(tester), AuditPage.path);
    });
  });
}
