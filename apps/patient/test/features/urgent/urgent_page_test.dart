import 'package:bloom_patient/features/intake/domain/intake_conversation.dart';
import 'package:bloom_patient/features/intake/presentation/bloc/intake_bloc.dart';
import 'package:bloom_patient/features/urgent/presentation/pages/urgent_page.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

// Shapes copied from server/app/safety.py URGENT_MESSAGES (fixed copy).
const _r1 = UrgentMessage(
  ruleId: RedFlagRule.r1,
  title: 'Please get care now',
  body: 'Synthetic R1 body.',
  actions: [
    UrgentAction(label: 'Call 911', tel: 'tel:911'),
    UrgentAction(label: 'Call or text 988', tel: 'tel:988'),
  ],
);

const _r5 = UrgentMessage(
  ruleId: RedFlagRule.r5,
  title: 'You are not alone',
  body: 'Synthetic R5 body.',
  actions: [
    UrgentAction(label: 'Call or text 988', tel: 'tel:988'),
    UrgentAction(label: 'Call 911', tel: 'tel:911'),
  ],
);

const _r6 = UrgentMessage(
  ruleId: RedFlagRule.r6,
  title: 'We are here for you',
  body: 'Synthetic R6 body.',
  support: 'Synthetic support line.',
  actions: [
    UrgentAction(label: 'Call 911', tel: 'tel:911'),
    UrgentAction(
      label: 'National Sexual Assault Hotline',
      tel: 'tel:18006564673',
    ),
    UrgentAction(label: 'Call or text 988', tel: 'tel:988'),
  ],
);

void main() {
  late MockIntakeBloc bloc;
  late List<Uri> launched;

  setUp(() {
    bloc = MockIntakeBloc();
    launched = [];
  });

  Future<void> pump(WidgetTester tester, UrgentMessage message) async {
    when(() => bloc.state).thenReturn(
      IntakeState.urgent(
        conversation: IntakeConversation.empty,
        message: message,
      ),
    );
    await tester.pumpPage(
      UrgentPage(launchTel: (uri) async => launched.add(uri)),
      intakeBloc: bloc,
    );
  }

  List<String> actionLabels(WidgetTester tester) {
    final labels = <String>[];
    for (var i = 0; ; i++) {
      final action = find.byKey(ValueKey('urgent-action-$i'));
      if (action.evaluate().isEmpty) return labels;
      labels.add(
        tester
            .widget<Text>(
              find.descendant(of: action, matching: find.byType(Text)),
            )
            .data!,
      );
    }
  }

  group('P03 UrgentPage', () {
    testWidgets('R1: 911 first, then 988, then I understand', (tester) async {
      await pump(tester, _r1);
      expect(find.text('Please get care now'), findsOneWidget);
      expect(find.text('Synthetic R1 body.'), findsOneWidget);
      expect(actionLabels(tester), ['Call 911', 'Call or text 988']);
      expect(find.text('I understand'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Call or text 988')).dy,
        lessThan(tester.getTopLeft(find.text('I understand')).dy),
      );
    });

    testWidgets('R5: 988 first, in the server’s order', (tester) async {
      await pump(tester, _r5);
      expect(actionLabels(tester), ['Call or text 988', 'Call 911']);
      expect(
        tester.getTopLeft(find.text('Call or text 988')).dy,
        lessThan(tester.getTopLeft(find.text('Call 911')).dy),
      );
    });

    testWidgets('R6 shows the support line and three actions', (tester) async {
      await pump(tester, _r6);
      expect(find.text('Synthetic support line.'), findsOneWidget);
      expect(actionLabels(tester), hasLength(3));
    });

    testWidgets('actions open tel: links', (tester) async {
      await pump(tester, _r5);
      await tester.tap(find.text('Call or text 988'));
      expect(launched, [Uri.parse('tel:988')]);
    });

    testWidgets('reading order: title, body, actions', (tester) async {
      await pump(tester, _r1);
      final title = tester.getTopLeft(find.text('Please get care now')).dy;
      final body = tester.getTopLeft(find.text('Synthetic R1 body.')).dy;
      final action = tester.getTopLeft(find.text('Call 911')).dy;
      expect(title, lessThan(body));
      expect(body, lessThan(action));
    });

    testWidgets('no chat composer on this screen', (tester) async {
      await pump(tester, _r1);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
