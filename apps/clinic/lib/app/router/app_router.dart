import 'dart:async';

import 'package:bloom_clinic/app/view/clinic_shell.dart';
import 'package:bloom_clinic/app/view/not_found_page.dart';
import 'package:bloom_clinic/features/audit/presentation/pages/audit_page.dart';
import 'package:bloom_clinic/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bloom_clinic/features/auth/presentation/pages/sign_in_page.dart';
import 'package:bloom_clinic/features/brief/presentation/pages/brief_page.dart';
import 'package:bloom_clinic/features/demo/presentation/pages/demo_page.dart';
import 'package:bloom_clinic/features/dev_gallery/presentation/pages/gallery_page.dart';
import 'package:bloom_clinic/features/queue/presentation/pages/queue_page.dart';
import 'package:bloom_clinic/features/red_flag/presentation/pages/red_flag_page.dart';
import 'package:bloom_clinic/features/settings/presentation/pages/settings_page.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Re-runs the router redirect whenever the auth state changes.
class AuthRefresh extends ChangeNotifier {
  new(AuthCubit auth) {
    _sub = auth.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

/// Sign-in redirect: every screen except A01 needs the demo doctor token.
/// The requested location is kept in `?from=` and restored after sign-in.
String? authRedirect(AuthState auth, Uri uri) {
  final atSignIn = uri.path == SignInPage.path;
  if (!auth.isSignedIn) {
    if (atSignIn) return null;
    final from = uri.toString();
    return from == QueuePage.path
        ? SignInPage.path
        : Uri(
            path: SignInPage.path,
            queryParameters: {'from': from},
          ).toString();
  }
  if (atSignIn) {
    final from = uri.queryParameters['from'];
    return (from != null && from.startsWith('/')) ? from : QueuePage.path;
  }
  return null;
}

/// Routes for the clinic app. Route name = screen ID = Figma frame name
/// (docs/02-app-flow.md). Paths are relative to the base href
/// (`/doctor/`), so `/doctor/...` in the screen index maps to the path
/// after the prefix.
GoRouter createAppRouter({
  required AuthCubit auth,
  Listenable? refresh,
  String? initialLocation,
}) => GoRouter(
  initialLocation: initialLocation ?? QueuePage.path,
  refreshListenable: refresh,
  redirect: (context, state) => authRedirect(auth.state, state.uri),
  errorBuilder: (context, state) => const NotFoundPage(),
  routes: [
    GoRoute(
      name: SignInPage.screenId,
      path: SignInPage.path,
      builder: (context, state) => const SignInPage(),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          ClinicShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          name: QueuePage.screenId,
          path: QueuePage.path,
          builder: (context, state) => const QueuePage(),
        ),
        GoRoute(
          name: BriefPage.screenId,
          path: BriefPage.path,
          builder: (context, state) => BriefPage(
            id: state.pathParameters['id']!,
            summary: state.extra is SessionSummary
                ? state.extra! as SessionSummary
                : null,
          ),
          routes: [
            // D03 lives inside D02 (Figma draws it as D02's right column);
            // this route opens D02 scrolled to the panel.
            GoRoute(
              name: BriefPage.trustScreenId,
              path: BriefPage.trustSubPath,
              builder: (context, state) =>
                  BriefPage(id: state.pathParameters['id']!, focusTrust: true),
            ),
          ],
        ),
        GoRoute(
          name: AuditPage.screenId,
          path: AuditPage.path,
          builder: (context, state) => const AuditPage(),
        ),
        GoRoute(
          name: DemoPage.screenId,
          path: DemoPage.path,
          builder: (context, state) => const DemoPage(),
        ),
        GoRoute(
          name: RedFlagPage.screenId,
          path: RedFlagPage.path,
          builder: (context, state) => RedFlagPage(
            id: state.pathParameters['id']!,
            summary: state.extra is SessionSummary
                ? state.extra! as SessionSummary
                : null,
          ),
        ),
      ],
    ),
    GoRoute(
      name: SettingsPage.screenId,
      path: SettingsPage.path,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      name: GalleryPage.routeName,
      path: GalleryPage.path,
      builder: (context, state) => const GalleryPage(),
    ),
  ],
);
