import 'package:bloc_test/bloc_test.dart';
import 'package:bloom_clinic/features/brief/presentation/pages/brief_page.dart';
import 'package:bloom_clinic/features/queue/presentation/cubit/queue_cubit.dart';
import 'package:bloom_clinic/features/queue/presentation/pages/queue_page.dart';
import 'package:bloom_clinic/features/red_flag/presentation/pages/red_flag_page.dart';
import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/display_size.dart';
import '../../helpers/pump_app.dart';

/// Synthetic queue where the server sends the red flag last, to prove the
/// client re-sorts.
class _UnsortedSessions extends FakeSessionRepository {
  @override
  Future<Result<List<SessionSummary>>> listSessions() async => Result.ok([
    SessionSummary(
      id: 'fake-ready',
      status: SessionStatus.ready,
      scenarioId: 'S1',
      ageBand: '30-39',
      reasonForVisit: 'Annual visit',
      briefId: 'brief-fake-ready',
      reviewStatus: ReviewStatus.draft,
      updatedAt: DateTime.utc(2026, 11, 19, 10),
    ),
    SessionSummary(
      id: 'fake-urgent',
      status: SessionStatus.urgent,
      redFlag: RedFlagRule.r1,
      scenarioId: 'S6',
      ageBand: '25-29',
      reasonForVisit: 'Pelvic pain',
      updatedAt: DateTime.utc(2026, 11, 19, 9),
    ),
  ]);
}

BloomRepositories _repos() {
  final fake = BloomRepositories.fake();
  return BloomRepositories(
    intake: fake.intake,
    brief: fake.brief,
    trust: fake.trust,
    session: _UnsortedSessions(),
  );
}

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .state
        .matchedLocation;

void main() {
  group('sortQueue', () {
    test('puts red flags first, then newest first', () {
      final old = SessionSummary(
        id: 'a',
        status: SessionStatus.ready,
        updatedAt: DateTime.utc(2026),
      );
      final newer = SessionSummary(
        id: 'b',
        status: SessionStatus.ready,
        updatedAt: DateTime.utc(2026, 2),
      );
      final flag = SessionSummary(
        id: 'c',
        status: SessionStatus.urgent,
        updatedAt: DateTime.utc(2025),
      );
      expect(sortQueue([old, newer, flag]).map((s) => s.id), ['c', 'b', 'a']);
    });
  });

  group('QueueCubit', () {
    blocTest<QueueCubit, QueueState>(
      'load emits loading then the sorted sessions',
      build: () => QueueCubit(_UnsortedSessions()),
      act: (cubit) => cubit.load(),
      expect: () => [
        const QueueState(),
        isA<QueueState>()
            .having((s) => s.status, 'status', QueueStatus.loaded)
            .having((s) => s.sessions.map((e) => e.id).toList(), 'ids', [
              'fake-urgent',
              'fake-ready',
            ]),
      ],
    );
  });

  group('D01 queue', () {
    testWidgets('lists sessions with the red flag first', (tester) async {
      tester.setDisplaySize(DisplaySizes.desktop);
      await tester.pumpApp(repositories: _repos());

      expect(find.byType(QueuePage), findsOneWidget);
      final flagged = find.text('S6 · 25–29');
      final ready = find.text('S1 · 30–39');
      expect(flagged, findsOneWidget);
      expect(ready, findsOneWidget);
      expect(
        tester.getTopLeft(flagged).dy,
        lessThan(tester.getTopLeft(ready).dy),
      );
      expect(find.text('RED FLAG'), findsOneWidget);
    });

    testWidgets('red-flag row opens D06', (tester) async {
      tester.setDisplaySize(DisplaySizes.desktop);
      await tester.pumpApp(repositories: _repos());

      await tester.tap(find.text('View summary'));
      await tester.pumpAndSettle();

      expect(find.byType(RedFlagPage), findsOneWidget);
      expect(_location(tester), '/flag/fake-urgent');
    });

    testWidgets('ready row opens D02', (tester) async {
      tester.setDisplaySize(DisplaySizes.desktop);
      await tester.pumpApp(repositories: _repos());

      await tester.tap(find.text('Open brief'));
      await tester.pumpAndSettle();

      expect(find.byType(BriefPage), findsOneWidget);
      expect(_location(tester), '/brief/fake-ready');
    });

    testWidgets('works on a phone (table scrolls sideways)', (tester) async {
      tester.setDisplaySize(DisplaySizes.phone);
      await tester.pumpApp(repositories: _repos());

      expect(tester.takeException(), isNull);
      expect(find.text('S6 · 25–29'), findsOneWidget);
    });
  });
}
