import 'package:bloom_ui/bloom_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('BloomTheme', () {
    for (final (name, theme, radius) in [
      ('patient', BloomTheme.patient(), BloomRadius.lg),
      ('clinic', BloomTheme.clinic(), BloomRadius.md),
    ]) {
      group(name, () {
        test('uses Material 3 and maps tokens into the ColorScheme', () {
          expect(theme.useMaterial3, isTrue);
          expect(theme.colorScheme.primary, const Color(0xff6b2d5c));
          expect(theme.colorScheme.error, const Color(0xffb42318));
          expect(theme.colorScheme.surface, const Color(0xffffffff));
          expect(theme.scaffoldBackgroundColor, const Color(0xfffbf8f4));
        });

        test('carries the status colours in BloomTokens', () {
          final tokens = theme.extension<BloomTokens>()!;
          expect(tokens.verified, const Color(0xff2f6b52));
          expect(tokens.verifiedSubtle, const Color(0xffe3f0e8));
          expect(tokens.warning, const Color(0xffb54708));
          expect(tokens.warningSubtle, const Color(0xfffffaeb));
          expect(tokens.critical, const Color(0xffb42318));
          expect(tokens.criticalSubtle, const Color(0xfffef3f2));
          expect(tokens.cardRadius, radius);
        });

        test('cards use the app radius', () {
          final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
          expect(shape.borderRadius, BorderRadius.circular(radius));
        });
      });
    }

    test('text styles match the tokens', () {
      final text = BloomTheme.patient().textTheme;
      expect(text.displaySmall?.fontSize, 32);
      expect(text.headlineSmall?.fontSize, 24);
      expect(text.titleMedium?.fontWeight, FontWeight.w600);
      expect(text.bodyLarge?.height, 24 / 16);
      expect(text.labelLarge?.fontWeight, FontWeight.w500);
    });

    test('BloomTokens lerp and copyWith', () {
      final mid = BloomTokens.patient.lerp(BloomTokens.clinic, 0.5);
      expect(mid.cardRadius, 14);
      expect(BloomTokens.patient.copyWith(cardRadius: 1).cardRadius, 1);
      expect(BloomTokens.patient.lerp(null, 0.5), BloomTokens.patient);
    });
  });
}
