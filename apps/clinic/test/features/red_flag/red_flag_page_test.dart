import 'package:bloom_clinic/features/queue/presentation/pages/queue_page.dart';
import 'package:bloom_clinic/features/red_flag/presentation/pages/red_flag_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/display_size.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('D06 red flag', () {
    for (final (name, size) in [
      ('desktop', DisplaySizes.desktop),
      ('phone', DisplaySizes.phone),
    ]) {
      testWidgets('shows the rule, what the patient saw, no brief on $name', (
        tester,
      ) async {
        tester.setDisplaySize(size);
        await tester.pumpApp(initialLocation: '/flag/fake-urgent');

        expect(find.byType(RedFlagPage), findsOneWidget);
        expect(find.text('RED FLAG'), findsOneWidget);
        expect(
          find.textContaining('urgent-care screen (911 and 988)'),
          findsOneWidget,
        );
        expect(
          find.textContaining('deterministic server rule'),
          findsOneWidget,
        );
        expect(find.text('Please get care now'), findsOneWidget);
        expect(
          find.textContaining('No AI brief was generated'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Back to queue returns to D01', (tester) async {
      tester.setDisplaySize(DisplaySizes.desktop);
      await tester.pumpApp(initialLocation: '/flag/fake-urgent');

      await tester.ensureVisible(find.text('Back to queue'));
      await tester.tap(find.text('Back to queue'));
      await tester.pumpAndSettle();

      expect(find.byType(QueuePage), findsOneWidget);
    });
  });
}
