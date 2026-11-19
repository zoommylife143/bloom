import 'package:bloom_ui/bloom_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

extension PumpBloom on WidgetTester {
  /// Pumps [child] inside the given Bloom theme (clinic by default).
  Future<void> pumpBloom(Widget child, {ThemeData? theme}) => pumpWidget(
    MaterialApp(
      theme: theme ?? BloomTheme.clinic(),
      home: Scaffold(
        body: Center(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
}

/// Asserts every element found by [finder] is at least 44 x 44 px.
void expectMinTapTarget(WidgetTester tester, Finder finder) {
  for (final element in finder.evaluate()) {
    final size = tester.getSize(find.byWidget(element.widget).first);
    expect(size.height, greaterThanOrEqualTo(44), reason: '$size');
    expect(size.width, greaterThanOrEqualTo(44), reason: '$size');
  }
}
