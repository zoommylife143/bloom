import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Logical sizes the clinic app is checked at.
abstract final class DisplaySizes {
  static const phone = Size(390, 844);
  static const tablet = Size(768, 1024);
  static const desktop = Size(1440, 900);
}

extension DisplaySize on WidgetTester {
  /// Sets the test view to [size] logical pixels and resets it after the
  /// test.
  void setDisplaySize(Size size) {
    view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
  }
}
