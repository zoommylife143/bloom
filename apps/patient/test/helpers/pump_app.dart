import 'package:bloc_test/bloc_test.dart';
import 'package:bloom_patient/app/view/app.dart';
import 'package:bloom_patient/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:bloom_patient/features/intake/presentation/bloc/intake_bloc.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockIntakeRepository extends Mock implements IntakeRepository;

class MockSessionRepository extends Mock implements SessionRepository;

class MockIntakeBloc extends MockBloc<IntakeEvent, IntakeState>
    implements IntakeBloc;

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit;

/// Call once per test file that verifies `bloc.add(any())`.
void registerPatientFallbacks() {
  registerFallbackValue(const IntakeReset());
}

/// Phone frame from Figma (390 x 844).
const phoneSize = Size(390, 844);

/// Tablet frame from Figma (768 x 1024).
const tabletSize = Size(768, 1024);

extension PumpApp on WidgetTester {
  /// Sets the logical screen size for this test.
  void useSize(Size size) {
    view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
  }

  /// Pumps the real app over synthetic in-memory repositories.
  Future<void> pumpApp({
    String? initialLocation,
    BloomRepositories? repositories,
    AuthCubit? authCubit,
    IntakeBloc? intakeBloc,
    bool settle = true,
  }) async {
    await pumpWidget(
      App(
        repositories: repositories ?? BloomRepositories.fake(),
        initialLocation: initialLocation,
        authCubit: authCubit,
        intakeBloc: intakeBloc,
      ),
    );
    if (settle) {
      await pumpAndSettle();
    } else {
      await pump();
    }
  }

  /// Pumps one page with the patient theme, strings and the given blocs.
  Future<void> pumpPage(
    Widget page, {
    IntakeBloc? intakeBloc,
    AuthCubit? authCubit,
    bool settle = true,
  }) async {
    final auth = authCubit ?? MockAuthCubit();
    if (authCubit == null) {
      when(() => auth.state).thenReturn(
        const AuthState(status: AuthStatus.signedIn, mode: RouteMode.dev),
      );
    }
    if (view.physicalSize != tabletSize) useSize(phoneSize);
    await pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          if (intakeBloc != null)
            BlocProvider<IntakeBloc>.value(value: intakeBloc),
        ],
        child: MaterialApp(
          theme: BloomTheme.patient(),
          localizationsDelegates: BloomLocalizations.localizationsDelegates,
          supportedLocales: BloomLocalizations.supportedLocales,
          // Static typing indicator so pumpAndSettle can finish.
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: page,
            ),
          ),
        ),
      ),
    );
    if (settle) {
      await pumpAndSettle();
    } else {
      await pump();
    }
  }
}
