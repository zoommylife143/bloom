import 'package:bloom_patient/features/done/presentation/pages/done_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('P04 DonePage', () {
    testWidgets('thank-you copy, no buttons', (tester) async {
      await tester.pumpPage(const DonePage());
      expect(find.text('Thank you'), findsOneWidget);
      expect(
        find.text('Your doctor will review your answers before your visit.'),
        findsOneWidget,
      );
      expect(find.byType(ButtonStyleButton), findsNothing);
    });

    testWidgets('has no clinical content', (tester) async {
      await tester.pumpPage(const DonePage());
      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ')
          .toLowerCase();
      for (final word in [
        'diagnos',
        'pregnan',
        'bleeding',
        'pain',
        'screening',
        'brief',
        'red flag',
        'infection',
      ]) {
        expect(text, isNot(contains(word)), reason: word);
      }
    });
  });
}
