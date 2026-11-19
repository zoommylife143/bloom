import 'package:bloom_clinic/app/view/screen_placeholder.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// S01: placeholder until the screen is built.
class SettingsPage extends StatelessWidget {
  const new({super.key});

  /// Screen ID = Figma frame name = go_router route name.
  static const screenId = 'S01';

  /// Path inside the app. Public URL: `/doctor/settings` (base href
  /// `/doctor/`).
  static const path = '/settings';

  @override
  Widget build(BuildContext context) =>
      ScreenPlaceholder(screenId: screenId, title: context.l10n.screenSettings);
}
