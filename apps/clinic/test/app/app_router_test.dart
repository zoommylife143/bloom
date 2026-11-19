import 'package:bloom_clinic/app/router/app_router.dart';
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
import 'package:bloom_ui/bloom_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

String _location(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold).first);
  return GoRouter.of(context).state.matchedLocation;
}

// (route name = screen ID, path inside the app, path parameters, page type)
const _routes = <(String, String, Map<String, String>, Type)>[
  ('D01', '/', {}, QueuePage),
  ('D02', '/brief/s-123', {'id': 's-123'}, BriefPage),
  ('D03', '/brief/s-123/trust', {'id': 's-123'}, BriefPage),
  ('D04', '/audit', {}, AuditPage),
  ('D05', '/demo', {}, DemoPage),
  ('D06', '/flag/s-123', {'id': 's-123'}, RedFlagPage),
  ('S01', '/settings', {}, SettingsPage),
];

void main() {
  group('App', () {
    testWidgets('starts on D01 with the Bloom theme', (tester) async {
      await tester.pumpApp();
      expect(find.byType(QueuePage), findsOneWidget);
      final context = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(context).colorScheme.primary, BloomColors.actionPrimary);
    });

    testWidgets('dev gallery is routed at /dev/gallery', (tester) async {
      await tester.pumpApp(initialLocation: '/dev/gallery', settle: false);
      expect(find.byType(GalleryPage), findsOneWidget);
      expect(find.text('Component gallery'), findsOneWidget);
    });

    testWidgets('unknown paths show the not found page', (tester) async {
      await tester.pumpApp(initialLocation: '/no-such-screen');
      expect(find.byType(NotFoundPage), findsOneWidget);
      expect(find.text('Page not found'), findsOneWidget);
    });
  });

  group('routes', () {
    for (final (screenId, path, params, page) in _routes) {
      testWidgets('$screenId opens by path $path', (tester) async {
        await tester.pumpApp(initialLocation: path, settle: false);
        expect(find.byType(page), findsOneWidget);
        expect(_location(tester), path);
      });

      testWidgets('$screenId opens by route name', (tester) async {
        await tester.pumpApp(initialLocation: '/no-such-screen');
        final context = tester.element(find.byType(Scaffold).first);
        GoRouter.of(context).goNamed(screenId, pathParameters: params);
        // One frame for the router to parse the new location, then let the
        // page transition finish.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(page), findsOneWidget);
        expect(_location(tester), path);
      });
    }

    testWidgets('A01 opens by path /sign-in when signed out', (tester) async {
      await tester.pumpApp(initialLocation: '/sign-in', signedIn: false);
      expect(find.byType(SignInPage), findsOneWidget);
    });
  });

  group('sign-in redirect', () {
    testWidgets('signed out: / → A01', (tester) async {
      await tester.pumpApp(signedIn: false);
      expect(_location(tester), '/sign-in');
      expect(find.byType(SignInPage), findsOneWidget);
    });

    testWidgets('signed out: deep link keeps ?from=', (tester) async {
      await tester.pumpApp(initialLocation: '/audit', signedIn: false);
      expect(find.byType(SignInPage), findsOneWidget);
      final context = tester.element(find.byType(Scaffold).first);
      expect(GoRouter.of(context).state.uri.queryParameters['from'], '/audit');
    });

    testWidgets('signed in: /sign-in → D01', (tester) async {
      await tester.pumpApp(initialLocation: '/sign-in');
      expect(_location(tester), '/');
    });
  });

  group('authRedirect', () {
    const signedOut = AuthState();
    const signedIn = AuthState(status: AuthStatus.signedIn);

    test('signed out at A01 stays', () {
      expect(authRedirect(signedOut, Uri.parse('/sign-in')), isNull);
    });

    test('signed out at / goes to A01 without from', () {
      expect(authRedirect(signedOut, Uri.parse('/')), '/sign-in');
    });

    test('signed out elsewhere keeps from', () {
      expect(
        authRedirect(signedOut, Uri.parse('/brief/s-1')),
        '/sign-in?from=%2Fbrief%2Fs-1',
      );
    });

    test('signed in at A01 restores a relative from', () {
      expect(
        authRedirect(signedIn, Uri.parse('/sign-in?from=/audit')),
        '/audit',
      );
    });

    test('signed in at A01 ignores an absolute from', () {
      expect(
        authRedirect(signedIn, Uri.parse('/sign-in?from=https://example.com')),
        '/',
      );
    });

    test('signed in elsewhere is not redirected', () {
      expect(authRedirect(signedIn, Uri.parse('/demo')), isNull);
    });
  });
}
