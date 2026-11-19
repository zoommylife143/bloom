import 'package:bloom_patient/app/view/app.dart';
import 'package:core_data/core_data.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:material_ui/material_ui.dart';

/// Build with `flutter build web --base-href /intake/`. Optional defines:
/// `API_BASE_URL` (default `/api`), `BLOOM_FAKE_API=true` (synthetic
/// in-memory data, no server).
void main() {
  usePathUrlStrategy();
  runApp(App(repositories: BloomRepositories.fromEnvironment()));
}
