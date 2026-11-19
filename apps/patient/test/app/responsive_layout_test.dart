import 'package:bloom_patient/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:bloom_patient/features/intake/domain/intake_conversation.dart';
import 'package:bloom_patient/features/intake/presentation/bloc/intake_bloc.dart';
import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_app.dart';

/// Pumps every patient route through the real router, theme and strings at
/// the sizes the demo runs on, and fails on any exception (RenderFlex
/// overflow included). Synthetic data only.

const _sizes = <String, Size>{
  'phone 360x640': Size(360, 640),
  'phone 390x844': Size(390, 844),
  'tablet 768x1024': Size(768, 1024),
  'desktop 1440x900': Size(1440, 900),
};

const _longAnswer =
    'It started about three weeks ago, mostly in the evenings, and it gets '
    'worse after exercise. I have tried resting and drinking more water but '
    'it has not really changed much since then.';

final IntakeConversation _conversation = IntakeConversation(
  sessionId: 'synthetic',
  mode: RouteMode.private,
  progress: 0.4,
  messages: [
    const IntakeMessage.bloom('Hello, I am Bloom. What brings you in today?'),
    const IntakeMessage.patient(_longAnswer),
    const IntakeMessage.bloom('When did it start?'),
    const IntakeMessage.patient('A few months ago.'),
    const IntakeMessage.bloom(
      'Is there any chance you could be pregnant? You can skip this.',
    ),
    for (var i = 0; i < 6; i++) ...[
      const IntakeMessage.patient('Not sure.'),
      const IntakeMessage.bloom(
        'Is there any chance you could be pregnant? You can skip this.',
      ),
    ],
  ],
);

final IntakeConversation _answered = _conversation.addMessage(
  const IntakeMessage.patient(_longAnswer),
);

const _urgent = UrgentMessage(
  title: 'Please get care now',
  body:
      'What you describe can be a sign of a problem that needs care today. '
      'Please call 911 or go to the nearest emergency department now. Do not '
      'wait for your appointment.',
  support:
      'If you are thinking about harming yourself, you can call or text 988 '
      'at any time to reach the Suicide and Crisis Lifeline.',
  actions: [
    UrgentAction(label: 'Call or text 988', tel: 'tel:988'),
    UrgentAction(label: 'Call 911', tel: 'tel:911'),
    UrgentAction(label: 'Call your clinic', tel: 'tel:5550100'),
  ],
);

class _Case {
  const new(this.name, this.path, this.auth, this.intake);

  final String name;
  final String path;
  final AuthState auth;
  final IntakeState intake;
}

const _signedIn = AuthState(
  status: AuthStatus.signedIn,
  mode: RouteMode.private,
);

final _cases = <_Case>[
  const _Case('A01 sign-in', '/sign-in', AuthState(), IntakeState.idle()),
  const _Case(
    'A01 expired + network error',
    '/sign-in',
    AuthState(expired: true, failure: AppFailure.network()),
    IntakeState.idle(),
  ),
  const _Case(
    'A01 signing in',
    '/sign-in',
    AuthState(status: AuthStatus.signingIn),
    IntakeState.idle(),
  ),
  const _Case('P01 welcome', '/', _signedIn, IntakeState.idle()),
  const _Case('P01 starting', '/', _signedIn, IntakeState.sending()),
  const _Case(
    'P01 start failed',
    '/',
    _signedIn,
    IntakeState.error(
      conversation: IntakeConversation.empty,
      failure: AppFailure.network(),
    ),
  ),
  _Case(
    'P02 chat idle (quick replies)',
    '/chat',
    _signedIn,
    IntakeState.idle(conversation: _conversation),
  ),
  _Case(
    'P02 typing',
    '/chat',
    _signedIn,
    IntakeState.waiting(conversation: _answered, pendingText: _longAnswer),
  ),
  _Case(
    'P02 model error',
    '/chat',
    _signedIn,
    IntakeState.error(
      conversation: _answered,
      failure: const AppFailure.server(statusCode: 502, message: 'model_error'),
      pendingText: _longAnswer,
    ),
  ),
  _Case(
    'P02 network error',
    '/chat',
    _signedIn,
    IntakeState.error(
      conversation: _answered,
      failure: const AppFailure.network(),
      pendingText: _longAnswer,
    ),
  ),
  _Case(
    'P02 session lost',
    '/chat',
    _signedIn,
    IntakeState.error(
      conversation: _answered,
      failure: const AppFailure.notFound('session_not_found'),
      pendingText: _longAnswer,
    ),
  ),
  _Case(
    'P02 refused',
    '/chat',
    _signedIn,
    IntakeState.routeRefused(conversation: _answered, pendingText: _longAnswer),
  ),
  _Case(
    'P03 urgent',
    '/urgent',
    _signedIn,
    IntakeState.urgent(conversation: _answered, message: _urgent),
  ),
  _Case(
    'P04 done',
    '/done',
    _signedIn,
    IntakeState.done(conversation: _answered),
  ),
];

void main() {
  setUpAll(registerPatientFallbacks);

  Future<void> pumpCase(WidgetTester tester, _Case c) async {
    final repos = BloomRepositories.fake();
    final intake = MockIntakeBloc();
    when(() => intake.state).thenReturn(c.intake);
    final auth = AuthCubit(sessions: repos.session, initialState: c.auth);
    addTearDown(auth.close);
    await tester.pumpApp(
      initialLocation: c.path,
      repositories: repos,
      authCubit: auth,
      intakeBloc: intake,
      settle: false,
    );
    // The typing indicator and progress bar animate; pump past them
    // without waiting for an idle frame.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    final location = GoRouter.of(tester.element(find.byType(Scaffold).first))
        .state
        .matchedLocation;
    expect(location, c.path, reason: 'router must stay on ${c.name}');
  }

  for (final MapEntry(key: sizeName, value: size) in _sizes.entries) {
    group(sizeName, () {
      for (final c in _cases) {
        testWidgets('${c.name} renders without overflow', (tester) async {
          tester.useSize(size);
          await pumpCase(tester, c);
          expect(tester.takeException(), isNull);
        });
      }
    });
  }

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    group(
      'phone ${size.width.toInt()}x${size.height.toInt()} at 200% text',
      () {
        for (final c in _cases) {
          testWidgets('${c.name} renders without overflow', (tester) async {
            tester
              ..useSize(size)
              ..platformDispatcher.textScaleFactorTestValue = 2;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await pumpCase(tester, c);
            expect(tester.takeException(), isNull);
          });
        }
      },
    );
  }

  group('phone 360x640 with the on-screen keyboard open', () {
    for (final scale in const [1.0, 2.0]) {
      for (final c in _cases.where((c) => c.path == '/chat')) {
        testWidgets('${c.name} at ${scale}x text renders without overflow', (
          tester,
        ) async {
          tester
            ..useSize(const Size(360, 640))
            ..view.viewInsets = const FakeViewPadding(bottom: 300)
            ..platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetViewInsets);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pumpCase(tester, c);
          expect(tester.takeException(), isNull);
          // The answer field stays on screen above the keyboard.
          final field = tester.getRect(find.byType(TextField));
          expect(field.bottom, lessThanOrEqualTo(640 - 300));
        });
      }
    }
  });
}
