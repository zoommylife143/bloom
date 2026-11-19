import 'package:bloom_ui/bloom_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('gallery shows every component and DecisionBar locks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpApp(initialLocation: '/dev/gallery', settle: false);

    for (final type in [
      BloomButton,
      StatusChip,
      ChatBubble,
      QuickReply,
      BloomBanner,
      CitationLink,
      TrustRow,
      DecisionBar,
    ]) {
      expect(find.byType(type), findsWidgets, reason: '$type');
    }

    await tester.tap(find.text('Confirm'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Draft, needs your review'), findsNothing);
    final confirm = find.ancestor(
      of: find.text('Confirm'),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
  });
}
