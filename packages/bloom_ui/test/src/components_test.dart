import 'package:bloom_ui/bloom_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_bloom.dart';

void main() {
  group('BloomButton', () {
    testWidgets('renders, has a label and a 44 px target', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpBloom(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BloomButton(label: 'Start', onPressed: () => taps++),
            BloomButton.secondary(label: 'Back', onPressed: () {}),
            BloomButton.text(label: 'Skip', icon: Icons.east, onPressed: () {}),
          ],
        ),
      );

      expect(find.bySemanticsLabel('Start'), findsOneWidget);
      expectMinTapTarget(tester, find.byType(FilledButton));
      expectMinTapTarget(tester, find.byType(OutlinedButton));
      expectMinTapTarget(tester, find.byType(TextButton));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tester.tap(find.text('Start'));
      expect(taps, 1);
      semantics.dispose();
    });

    testWidgets('loading shows a spinner and ignores taps', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpBloom(
        BloomButton(label: 'Send', isLoading: true, onPressed: () => taps++),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Send, loading'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
      semantics.dispose();
    });
  });

  group('StatusChip', () {
    for (final status in BloomStatus.values) {
      testWidgets('$status shows icon and text', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpBloom(StatusChip(status: status));

        final label = StatusChip.defaultLabel(status);
        expect(find.text(label), findsOneWidget);
        expect(find.byIcon(StatusChip.iconFor(status)), findsOneWidget);
        expect(find.bySemanticsLabel('Status: $label'), findsOneWidget);
        semantics.dispose();
      });
    }
  });

  group('ChatBubble', () {
    testWidgets('Bloom bubble sits left with the optional marker', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpBloom(
        const SizedBox(
          width: 600,
          child: ChatBubble(
            text: 'Any allergies?',
            author: ChatAuthor.bloom,
            isOptional: true,
          ),
        ),
      );

      expect(find.text('Any allergies?'), findsOneWidget);
      expect(find.text('OPTIONAL QUESTION'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Optional question. Bloom said: Any allergies?'),
        findsOneWidget,
      );
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
      semantics.dispose();
    });

    testWidgets('patient bubble sits right without a marker', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpBloom(
        const ChatBubble(text: 'Three days', author: ChatAuthor.patient),
      );

      expect(find.text('OPTIONAL QUESTION'), findsNothing);
      expect(find.bySemanticsLabel('You said: Three days'), findsOneWidget);
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerRight);
      semantics.dispose();
    });
  });

  group('QuickReply', () {
    testWidgets('renders chips, reports taps, 44 px targets', (tester) async {
      final semantics = tester.ensureSemantics();
      final picked = <String>[];
      await tester.pumpBloom(
        QuickReply(
          options: const ['Yes', 'No', 'Not sure'],
          onSelected: picked.add,
        ),
      );

      expect(find.byType(ActionChip), findsNWidgets(3));
      expect(find.bySemanticsLabel('Quick replies'), findsOneWidget);
      expectMinTapTarget(tester, find.byType(ActionChip));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      await tester.tap(find.text('Not sure'));
      expect(picked, ['Not sure']);
      semantics.dispose();
    });

    testWidgets('disabled chips ignore taps', (tester) async {
      final picked = <String>[];
      await tester.pumpBloom(
        QuickReply(
          options: const ['Yes'],
          onSelected: picked.add,
          enabled: false,
        ),
      );
      await tester.tap(find.text('Yes'));
      expect(picked, isEmpty);
    });
  });

  group('BloomBanner', () {
    testWidgets('demo banner shows the literal warning', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpBloom(const BloomBanner.demo());

      expect(
        find.text('Demo only. Do not enter real health information.'),
        findsOneWidget,
      );
      expect(
        find.byIcon(BloomBanner.iconFor(BloomBannerVariant.warning)),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Do not enter real health information')),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('route refused is critical and says no fallback', (
      tester,
    ) async {
      await tester.pumpBloom(const BloomBanner.routeRefused());
      expect(find.text('Route refused'), findsOneWidget);
      expect(
        find.textContaining('No fallback model was called'),
        findsOneWidget,
      );
      expect(
        find.byIcon(BloomBanner.iconFor(BloomBannerVariant.critical)),
        findsOneWidget,
      );
    });

    testWidgets('model error action is tappable with a 44 px target', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpBloom(BloomBanner.modelError(onAction: () => retries++));

      expectMinTapTarget(tester, find.byType(TextButton));
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('verified and info variants render', (tester) async {
      await tester.pumpBloom(
        const Column(
          children: [
            BloomBanner(message: 'Info', title: 'Note'),
            BloomBanner(message: 'OK', variant: BloomBannerVariant.verified),
          ],
        ),
      );
      expect(find.text('Info'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    });
  });

  group('CitationLink', () {
    testWidgets('shows title and host, opens the URL, 44 px target', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final opened = <Uri>[];
      await tester.pumpBloom(
        CitationLink(
          title: 'Cervical cancer screening',
          url: 'https://www.uspreventiveservicestaskforce.org/page',
          onOpen: opened.add,
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Source: Cervical cancer screening, '
          'uspreventiveservicestaskforce.org',
        ),
        findsOneWidget,
      );
      expectMinTapTarget(tester, find.byType(InkWell));

      await tester.tap(find.byType(InkWell));
      expect(opened.single.host, 'www.uspreventiveservicestaskforce.org');
      semantics.dispose();
    });

    testWidgets('none variant says No guideline retrieved', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpBloom(const CitationLink.none());

      expect(find.text('No guideline retrieved'), findsOneWidget);
      expect(find.bySemanticsLabel('No guideline retrieved'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
      semantics.dispose();
    });
  });

  group('TrustRow', () {
    for (final status in TrustRowStatus.values) {
      testWidgets('$status shows literal wording and an icon', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpBloom(
          TrustRow(label: 'Route', value: 'glm-zdr', status: status),
        );

        final wording = TrustRow.defaultStatusText(status);
        expect(find.text(wording), findsOneWidget);
        expect(find.byIcon(TrustRow.iconFor(status)), findsOneWidget);
        expect(
          find.bySemanticsLabel('Route: glm-zdr. $wording'),
          findsOneWidget,
        );
        expect(find.textContaining('Secure'), findsNothing);
        semantics.dispose();
      });
    }

    test('not exposed wording is literal', () {
      expect(
        TrustRow.defaultStatusText(TrustRowStatus.notExposed),
        'Evidence not exposed by provider',
      );
    });
  });

  group('DecisionBar', () {
    testWidgets('shows the draft label and enabled buttons until decided', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpBloom(
        DecisionBar(onConfirm: () {}, onEdit: () {}, onReject: () {}),
      );

      expect(find.text('Draft, needs your review'), findsOneWidget);
      expect(find.bySemanticsLabel('Draft, needs your review'), findsOneWidget);
      expectMinTapTarget(tester, find.byType(FilledButton));
      expectMinTapTarget(tester, find.byType(OutlinedButton));
      expectMinTapTarget(tester, find.byType(TextButton));
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      semantics.dispose();
    });

    testWidgets('disables every button after a decision', (tester) async {
      BloomDecision? decision;
      var confirms = 0;
      await tester.pumpBloom(
        StatefulBuilder(
          builder: (context, setState) => DecisionBar(
            decision: decision,
            onConfirm: () => setState(() {
              confirms++;
              decision = BloomDecision.confirmed;
            }),
            onEdit: () {},
            onReject: () {},
          ),
        ),
      );

      await tester.tap(find.text('Confirm'));
      await tester.pump();

      expect(confirms, 1);
      expect(find.text('Draft, needs your review'), findsNothing);
      expect(find.text('Approved'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );

      await tester.tap(find.text('Confirm'), warnIfMissed: false);
      expect(confirms, 1);
    });

    testWidgets('edited and rejected show their chips', (tester) async {
      for (final (decision, label) in [
        (BloomDecision.edited, 'Edited'),
        (BloomDecision.rejected, 'Rejected'),
      ]) {
        await tester.pumpBloom(
          DecisionBar(
            decision: decision,
            onConfirm: () {},
            onEdit: () {},
            onReject: () {},
          ),
        );
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('busy disables the buttons', (tester) async {
      await tester.pumpBloom(
        DecisionBar(
          isBusy: true,
          onConfirm: () {},
          onEdit: () {},
          onReject: () {},
        ),
      );
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
    });
  });
}
