import 'package:bloc_test/bloc_test.dart';
import 'package:bloom_clinic/features/brief/presentation/bloc/brief_bloc.dart';
import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/display_size.dart';
import '../../helpers/pump_app.dart';

const _readyPath = '/brief/fake-ready';
const _fallbackPath = '/brief/fake-fallback';
const _fallbackLabel = 'Automatic draft, written without AI. Check every line.';

void main() {
  group('BriefBloc', () {
    BriefBloc build() => BriefBloc(
      briefRepository: FakeBriefRepository(),
      sessionRepository: FakeSessionRepository(),
      sessionId: 'fake-ready',
    );

    blocTest<BriefBloc, BriefState>(
      'loads the draft for review',
      build: build,
      act: (bloc) => bloc.add(const BriefRequested()),
      wait: Duration.zero,
      verify: (bloc) {
        expect(bloc.state.view, BriefView.draft);
        expect(bloc.state.session?.scenarioId, 'S1');
      },
    );

    blocTest<BriefBloc, BriefState>(
      'Confirm stores an approved decision with the reviewer',
      build: build,
      act: (bloc) async {
        bloc.add(const BriefRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const BriefDecisionSubmitted(
            BriefDecision.approve,
            reviewer: 'Dr. Synthetic',
          ),
        );
      },
      wait: Duration.zero,
      verify: (bloc) {
        expect(bloc.state.view, BriefView.approved);
        expect(bloc.state.bundle?.provenance.reviewedBy, 'Dr. Synthetic');
        expect(bloc.state.submitting, isNull);
      },
    );

    blocTest<BriefBloc, BriefState>(
      'Edit then save stores an edited brief and keeps the original',
      build: build,
      act: (bloc) async {
        bloc.add(const BriefRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BriefEditStarted());
        final draft = bloc.state.bundle!.brief;
        bloc.add(
          BriefDecisionSubmitted(
            BriefDecision.edit,
            reviewer: 'Dr. Synthetic',
            edited: draft,
          ),
        );
      },
      wait: Duration.zero,
      verify: (bloc) {
        expect(bloc.state.view, BriefView.edited);
        expect(bloc.state.isEditing, isFalse);
        expect(bloc.state.bundle?.originalBrief, isNotNull);
      },
    );

    blocTest<BriefBloc, BriefState>(
      'a second decision is locked and shows the stored one',
      build: build,
      act: (bloc) async {
        bloc.add(const BriefRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const BriefDecisionSubmitted(BriefDecision.reject, reviewer: 'A'),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const BriefDecisionSubmitted(BriefDecision.approve, reviewer: 'B'),
        );
      },
      wait: Duration.zero,
      verify: (bloc) {
        expect(bloc.state.view, BriefView.rejected);
        expect(bloc.state.decisionFailure, isA<LockedFailure>());
      },
    );
  });

  group('D02 brief', () {
    for (final (name, size) in [
      ('desktop', DisplaySizes.desktop),
      ('phone', DisplaySizes.phone),
    ]) {
      group('on $name', () {
        testWidgets('shows the AI draft with Confirm / Edit / Reject', (
          tester,
        ) async {
          tester.setDisplaySize(size);
          await tester.pumpApp(initialLocation: _readyPath);

          expect(find.text('AI draft · needs your review'), findsOneWidget);
          expect(find.text('DRAFT'), findsWidgets);
          expect(find.text('Confirm'), findsOneWidget);
          expect(find.text('Edit'), findsOneWidget);
          expect(find.text('Reject'), findsOneWidget);
        });

        testWidgets('Confirm approves the brief', (tester) async {
          tester.setDisplaySize(size);
          await tester.pumpApp(initialLocation: _readyPath);

          await tester.ensureVisible(find.text('Confirm'));
          await tester.tap(find.text('Confirm'));
          await tester.pumpAndSettle();

          expect(find.textContaining('Approved by Dr. Demo'), findsOneWidget);
          expect(find.text('APPROVED'), findsWidgets);
          expect(find.text('Confirm'), findsNothing);
          expect(find.textContaining('reviewed by Dr. Demo'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('Edit, change a line, save records the edit', (
          tester,
        ) async {
          tester.setDisplaySize(size);
          await tester.pumpApp(initialLocation: _readyPath);

          await tester.ensureVisible(find.text('Edit'));
          await tester.tap(find.text('Edit'));
          await tester.pumpAndSettle();
          expect(find.textContaining('Editing the AI draft'), findsOneWidget);

          final plan = find.byKey(const ValueKey('edit-plan'));
          await tester.ensureVisible(plan);
          await tester.enterText(plan, 'Synthetic follow-up in one year');
          await tester.ensureVisible(find.text('Save edits'));
          await tester.tap(find.text('Save edits'));
          await tester.pumpAndSettle();

          expect(
            find.textContaining('Edited and approved by Dr. Demo'),
            findsOneWidget,
          );
          expect(find.text('Synthetic follow-up in one year'), findsWidgets);
          expect(tester.takeException(), isNull);
        });

        testWidgets('Edit can be cancelled', (tester) async {
          tester.setDisplaySize(size);
          await tester.pumpApp(initialLocation: _readyPath);

          await tester.ensureVisible(find.text('Edit'));
          await tester.tap(find.text('Edit'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Cancel'));
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();

          expect(find.text('AI draft · needs your review'), findsOneWidget);
        });

        testWidgets('Reject asks first, then rejects', (tester) async {
          tester.setDisplaySize(size);
          await tester.pumpApp(initialLocation: _readyPath);

          await tester.ensureVisible(find.text('Reject'));
          await tester.tap(find.text('Reject'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);

          await tester.tap(find.text('Reject draft'));
          await tester.pumpAndSettle();

          expect(find.textContaining('Rejected by Dr. Demo'), findsOneWidget);
          expect(find.text('REJECTED'), findsWidgets);
          expect(tester.takeException(), isNull);
        });
      });
    }

    testWidgets('Reject dialog Cancel keeps the draft', (tester) async {
      tester.setDisplaySize(DisplaySizes.desktop);
      await tester.pumpApp(initialLocation: _readyPath);

      await tester.ensureVisible(find.text('Reject'));
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancel'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('AI draft · needs your review'), findsOneWidget);
    });

    testWidgets('D03 shows the Privacy & Trust calls', (tester) async {
      tester.setDisplaySize(DisplaySizes.desktop);
      await tester.pumpApp(initialLocation: '$_readyPath/trust');

      expect(find.text('Physician approval'), findsOneWidget);
      expect(find.textContaining('req-fake-0002'), findsWidgets);
    });
  });

  group('D02/D03 fallback draft (no AI)', () {
    for (final (name, size) in [
      ('desktop', DisplaySizes.desktop),
      ('phone', DisplaySizes.phone),
    ]) {
      group('on $name', () {
        testWidgets('labels the draft and keeps Confirm / Edit / Reject', (
          tester,
        ) async {
          final semantics = tester.ensureSemantics();
          tester.setDisplaySize(size);
          await tester.pumpApp(initialLocation: _fallbackPath);

          final banner = find.byKey(const Key('brief-fallback-banner'));
          expect(banner, findsOneWidget);
          expect(find.text(_fallbackLabel), findsOneWidget);
          expect(
            find.bySemanticsLabel(RegExp('written without AI')),
            findsWidgets,
          );
          // Above the regular draft banner.
          expect(
            tester.getTopLeft(banner).dy,
            lessThan(
              tester.getTopLeft(find.text('AI draft · needs your review')).dy,
            ),
          );
          expect(
            find.textContaining('DRAFT (automatic fallback'),
            findsWidgets,
          );
          expect(find.textContaining('deterministic-fallback'), findsWidgets);
          expect(find.text('Confirm'), findsOneWidget);
          expect(find.text('Edit'), findsOneWidget);
          expect(find.text('Reject'), findsOneWidget);
          expect(tester.takeException(), isNull);
          semantics.dispose();
        });

        testWidgets('Confirm still works and the label stays', (tester) async {
          tester.setDisplaySize(size);
          await tester.pumpApp(initialLocation: _fallbackPath);

          await tester.ensureVisible(find.text('Confirm'));
          await tester.tap(find.text('Confirm'));
          await tester.pumpAndSettle();

          expect(find.textContaining('Approved by Dr. Demo'), findsOneWidget);
          expect(find.text(_fallbackLabel), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('D03 shows fallback rows as no model call', (tester) async {
          tester.setDisplaySize(size);
          await tester.pumpApp(initialLocation: '$_fallbackPath/trust');

          expect(find.textContaining('intake_fallback'), findsOneWidget);
          expect(find.textContaining('brief_fallback'), findsOneWidget);
          expect(
            find.textContaining('model: Fallback (no model call)'),
            findsNWidgets(2),
          );
          expect(find.text('Route: none · no model called'), findsNWidgets(2));
          expect(
            find.text('Intake fallback: fixed question asked, no AI'),
            findsOneWidget,
          );
          expect(
            find.textContaining('Brief fallback: deterministic draft'),
            findsOneWidget,
          );
          expect(
            find.text('Used after: schema_validation_failed'),
            findsOneWidget,
          );
          expect(find.text('No model'), findsNWidgets(2));
          // A fallback row is never shown as a model with "none".
          expect(find.textContaining('model: none'), findsNothing);
          expect(tester.takeException(), isNull);
        });
      });
    }

    testWidgets('a model-written draft has no fallback label', (tester) async {
      tester.setDisplaySize(DisplaySizes.desktop);
      await tester.pumpApp(initialLocation: _readyPath);
      expect(find.byKey(const Key('brief-fallback-banner')), findsNothing);
      expect(find.text(_fallbackLabel), findsNothing);
    });
  });
}
