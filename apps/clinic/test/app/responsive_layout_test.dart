import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

// (label, logical size)
const _sizes = <(String, Size)>[
  ('phone', Size(390, 844)),
  ('tablet', Size(768, 1024)),
  ('desktop', Size(1440, 900)),
];

// (screen ID, path, signed in). Session IDs come from the synthetic fakes.
const _screens = <(String, String, bool)>[
  ('A01', '/sign-in', false),
  ('D01', '/', true),
  ('D02', '/brief/fake-ready', true),
  ('D02 not generated', '/brief/fake-progress', true),
  ('D03', '/brief/fake-ready/trust', true),
  ('D04', '/audit', true),
  ('D05', '/demo', true),
  ('D06', '/flag/fake-urgent', true),
  ('S01', '/settings', true),
  ('gallery', '/dev/gallery', true),
  ('not found', '/no-such-screen', true),
];

void main() {
  group('every screen lays out without exceptions', () {
    for (final (sizeName, size) in _sizes) {
      for (final (screenId, path, signedIn) in _screens) {
        testWidgets('$screenId at $sizeName ${size.width}x${size.height}', (
          tester,
        ) async {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          // Collect every layout error (not only the first) with a short
          // description, so a failure names what broke.
          final errors = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (details) =>
              errors.add(details.toString().split('\n').take(12).join('\n'));
          try {
            await tester.pumpApp(
              initialLocation: path,
              signedIn: signedIn,
              settle: false,
            );
            await tester.pump(const Duration(milliseconds: 500));
          } finally {
            FlutterError.onError = previous;
          }

          expect(errors, isEmpty, reason: errors.join('\n---\n'));
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
