import 'dart:async';

import 'package:bloc_test/bloc_test.dart';

import 'package:bloom_clinic/features/brief/presentation/pages/brief_page.dart';
import 'package:bloom_clinic/features/demo/domain/negative_test.dart';
import 'package:bloom_clinic/features/demo/domain/scenarios.dart';
import 'package:bloom_clinic/features/demo/presentation/cubit/demo_cubit.dart';
import 'package:bloom_clinic/features/demo/presentation/pages/demo_page.dart';
import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/display_size.dart';
import '../../helpers/pump_app.dart';

const _refused =
    'Request refused before inference: no route met the confidential '
    'privacy floor. No fallback model was called.';

const _providerError =
    'Provider error (HTTP 502), not a refusal. The test did not reach a '
    'routing decision. Run it again.';

TrustEvent _event(TrustOutcome outcome, Map<String, dynamic> evidence) =>
    TrustEvent(
      node: 'negative_test',
      mode: RouteMode.private,
      policyRequired: 'confidential',
      outcome: outcome,
      evidence: evidence,
    );

final TrustEvent _refusedEvent = _event(TrustOutcome.refused, const {
  'http_status': 400,
  'error_code': 'confidential_privacy_required',
});
final TrustEvent _providerErrorEvent = _event(TrustOutcome.error, const {
  'http_status': 502,
});

/// Synthetic negative test that returns [event].
class _TrustRepository extends FakeTrustRepository {
  new(this.event);

  final TrustEvent event;

  @override
  Future<Result<TrustEvent>> runNegativeTest({String? sessionId}) async =>
      Result.ok(event);
}

/// Synthetic scenario run that hits the client timeout.
class _TimeoutSessionRepository extends FakeSessionRepository {
  @override
  Future<Result<ScenarioRun>> runScenario(String scenarioId) async =>
      const Result.err(AppFailure.network('timeout'));
}

/// Synthetic scenario run that completes when the test says so.
class _SlowSessionRepository extends FakeSessionRepository {
  final completer = Completer<Result<ScenarioRun>>();

  @override
  Future<Result<ScenarioRun>> runScenario(String scenarioId) =>
      completer.future;
}

void main() {
  group('negativeTestVerdictOf', () {
    test('refused → refused', () {
      expect(negativeTestVerdictOf(_refusedEvent), NegativeTestVerdict.refused);
    });

    test('error with a provider 5xx → providerError, not refused', () {
      expect(
        negativeTestVerdictOf(_providerErrorEvent),
        NegativeTestVerdict.providerError,
      );
      expect(httpStatusOf(_providerErrorEvent), 502);
    });

    test('served when it should refuse → served', () {
      expect(
        negativeTestVerdictOf(
          _event(TrustOutcome.error, const {
            'error': 'expected_refusal_but_served',
          }),
        ),
        NegativeTestVerdict.served,
      );
    });

    test('ok → unexpected', () {
      expect(
        negativeTestVerdictOf(_event(TrustOutcome.ok, const {})),
        NegativeTestVerdict.unexpected,
      );
    });

    test('httpStatusOf reads ints and numeric strings only', () {
      expect(httpStatusOf(_event(TrustOutcome.error, const {})), isNull);
      expect(
        httpStatusOf(_event(TrustOutcome.error, const {'http_status': '503'})),
        503,
      );
    });
  });

  test('isRunTimeout: client timeout and proxy 504 only', () {
    expect(isRunTimeout(const AppFailure.network('timeout')), isTrue);
    expect(isRunTimeout(const AppFailure.server(statusCode: 504)), isTrue);
    expect(isRunTimeout(const AppFailure.server(statusCode: 502)), isFalse);
    expect(isRunTimeout(const AppFailure.network()), isFalse);
  });

  group('DemoCubit', () {
    blocTest<DemoCubit, DemoState>(
      'negative test ends refused',
      build: () => DemoCubit(FakeSessionRepository(), FakeTrustRepository()),
      act: (cubit) => cubit.runNegativeTest(),
      verify: (cubit) {
        expect(cubit.state.negativeRunning, isFalse);
        expect(cubit.state.negativeResult?.outcome, TrustOutcome.refused);
        expect(cubit.state.negativeFailure, isNull);
      },
    );

    blocTest<DemoCubit, DemoState>(
      'negative test keeps a provider error event as the result',
      build: () => DemoCubit(
        FakeSessionRepository(),
        _TrustRepository(_providerErrorEvent),
      ),
      act: (cubit) => cubit.runNegativeTest(),
      expect: () => [
        const DemoState(negativeRunning: true),
        DemoState(negativeResult: _providerErrorEvent),
      ],
    );

    blocTest<DemoCubit, DemoState>(
      'scenario timeout → failure on that card, running cleared',
      build: () =>
          DemoCubit(_TimeoutSessionRepository(), FakeTrustRepository()),
      act: (cubit) => cubit.runScenario('S3'),
      expect: () => const [
        DemoState(runs: {'S3': ScenarioRunState(isRunning: true)}),
        DemoState(
          runs: {
            'S3': ScenarioRunState(failure: AppFailure.network('timeout')),
          },
        ),
      ],
    );
  });

  group('D05 demo', () {
    for (final (name, size) in [
      ('desktop', DisplaySizes.desktop),
      ('phone', DisplaySizes.phone),
    ]) {
      testWidgets('negative test shows Refused on $name', (tester) async {
        tester.setDisplaySize(size);
        await tester.pumpApp(initialLocation: DemoPage.path);

        final run = find.text('Run negative test');
        await tester.ensureVisible(run);
        await tester.tap(run);
        await tester.pumpAndSettle();

        expect(find.text(_refused), findsOneWidget);
        expect(find.text('Refused'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('provider 5xx shows a provider error, not Refused', (
      tester,
    ) async {
      tester.setDisplaySize(DisplaySizes.desktop);
      final fake = BloomRepositories.fake();
      await tester.pumpApp(
        initialLocation: DemoPage.path,
        repositories: BloomRepositories(
          intake: fake.intake,
          brief: fake.brief,
          session: fake.session,
          trust: _TrustRepository(_providerErrorEvent),
        ),
      );

      final run = find.text('Run negative test');
      await tester.ensureVisible(run);
      await tester.tap(run);
      await tester.pumpAndSettle();

      expect(find.text(_providerError), findsOneWidget);
      expect(find.text(_refused), findsNothing);
      expect(find.text('Refused'), findsNothing);
      expect(find.text('Error'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long scenario run shows progress, then a clean timeout', (
      tester,
    ) async {
      tester.setDisplaySize(DisplaySizes.desktop);
      final fake = BloomRepositories.fake();
      final sessions = _SlowSessionRepository();
      await tester.pumpApp(
        initialLocation: DemoPage.path,
        repositories: BloomRepositories(
          intake: fake.intake,
          brief: fake.brief,
          session: sessions,
          trust: fake.trust,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Run scenario S1').first);
      await tester.pump();
      expect(find.textContaining('a minute or two'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.textContaining('(3 s)'), findsOneWidget);

      sessions.completer.complete(
        const Result.err(AppFailure.network('timeout')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('a minute or two'), findsNothing);
      expect(
        find.textContaining('Still running after the app stopped waiting'),
        findsOneWidget,
      );
      expect(find.text('Run'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('running a scenario offers its brief', (tester) async {
      tester.setDisplaySize(DisplaySizes.desktop);
      await tester.pumpApp(initialLocation: DemoPage.path);

      await tester.tap(find.bySemanticsLabel('Run scenario S1').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Brief ready'), findsOneWidget);

      await tester.tap(find.text('Open brief'));
      await tester.pumpAndSettle();
      expect(find.byType(BriefPage), findsOneWidget);
    });
  });

  test('negativeProviderErrorText words both HTTP and unknown status', () {
    final l10n = lookupBloomLocalizations(const Locale('en'));
    expect(negativeProviderErrorText(l10n, 502), _providerError);
    expect(
      negativeProviderErrorText(l10n, null),
      'Provider error, not a refusal. The test did not reach a routing '
      'decision. Run it again.',
    );
  });
}
