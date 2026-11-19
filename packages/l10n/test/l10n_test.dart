import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('English strings resolve through context.l10n', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: BloomLocalizations.localizationsDelegates,
        supportedLocales: BloomLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Text(context.l10n.placeholderBody('P02')),
        ),
      ),
    );
    expect(find.text('Screen P02 is not built yet.'), findsOneWidget);
  });

  test('the demo banner wording is literal', () {
    expect(
      lookupBloomLocalizations(const Locale('en')).demoBanner,
      'Demo only. Do not enter real health information.',
    );
  });

  test('the fallback draft label is literal', () {
    final l10n = lookupBloomLocalizations(const Locale('en'));
    expect(
      l10n.clinicFallbackDraftTitle,
      'Automatic draft, written without AI. Check every line.',
    );
    expect(l10n.clinicTrustNoModelCall, 'Fallback (no model call)');
  });

  test('the demo run and negative test strings take their values', () {
    final l10n = lookupBloomLocalizations(const Locale('en'));
    expect(l10n.clinicScenarioRunningElapsed(7), endsWith('(7 s)'));
    expect(
      l10n.clinicScenarioRunningElapsed(7),
      startsWith(l10n.clinicScenarioRunningLong),
    );
    expect(l10n.clinicNegativeProviderErrorHttp(503), contains('(HTTP 503)'));
    expect(l10n.clinicNegativeProviderError, isNot(contains('HTTP')));
    expect(l10n.clinicScenarioTimeout, startsWith('Still running'));
  });
}
