import 'package:bloom_clinic/app/clinic_timings.dart';
import 'package:bloom_clinic/app/view/app.dart';
import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  /// Pumps the real app over synthetic in-memory repositories, signed in
  /// as the demo doctor with polling off. Pass `signedIn: false` to start
  /// at A01, and `settle: false` for pages with endless animations
  /// (spinners).
  Future<void> pumpApp({
    String? initialLocation,
    bool signedIn = true,
    bool settle = true,
    BloomRepositories? repositories,
  }) async {
    await pumpWidget(
      App(
        repositories: repositories ?? BloomRepositories.fake(),
        initialLocation: initialLocation,
        signedIn: signedIn,
        timings: ClinicTimings.none,
      ),
    );
    if (settle) {
      await pumpAndSettle();
    } else {
      await pump(const Duration(milliseconds: 500));
    }
  }
}
