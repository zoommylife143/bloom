import 'dart:async';

import 'package:bloom_patient/app/view/not_found_page.dart';
import 'package:bloom_patient/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:bloom_patient/features/auth/presentation/pages/sign_in_page.dart';
import 'package:bloom_patient/features/done/presentation/pages/done_page.dart';
import 'package:bloom_patient/features/intake/presentation/bloc/intake_bloc.dart';
import 'package:bloom_patient/features/intake/presentation/pages/intake_chat_page.dart';
import 'package:bloom_patient/features/urgent/presentation/pages/urgent_page.dart';
import 'package:bloom_patient/features/welcome/presentation/pages/welcome_page.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Where the patient may be, from sign-in and intake state.
enum PatientPhase { signedOut, welcome, chatting, urgent, finished }

/// Reads the [PatientPhase] from the two blocs and notifies the router only
/// when it changes, so ordinary chat updates do not re-run redirects.
class PatientRouteGuard extends ChangeNotifier {
  new({required this._auth, required this._intake}) {
    _phase = _compute();
    _subscriptions = [
      _auth.stream.listen((_) => _update()),
      _intake.stream.listen((_) => _update()),
    ];
  }

  final AuthCubit _auth;
  final IntakeBloc _intake;
  late final List<StreamSubscription<Object?>> _subscriptions;
  late PatientPhase _phase;

  PatientPhase get phase => _phase;

  PatientPhase _compute() {
    if (!_auth.state.isSignedIn) return PatientPhase.signedOut;
    return switch (_intake.state) {
      IntakeUrgent() => PatientPhase.urgent,
      IntakeDone() || IntakeLocked() => PatientPhase.finished,
      final s when s.conversation.hasSession => PatientPhase.chatting,
      _ => PatientPhase.welcome,
    };
  }

  void _update() {
    final next = _compute();
    if (next == _phase) return;
    _phase = next;
    notifyListeners();
  }

  /// The path to send the patient to, or null to stay on [path].
  ///
  /// - Not signed in: A01.
  /// - No session: P01. In progress: P02.
  /// - Urgent: P03 (P04 after "I understand"); never back to the chat.
  /// - Finished or locked: P04.
  String? redirect(String path) {
    const known = {
      SignInPage.path,
      WelcomePage.path,
      IntakeChatPage.path,
      UrgentPage.path,
      DonePage.path,
    };
    if (!known.contains(path)) return null;
    final allowed = switch (_phase) {
      PatientPhase.signedOut => const [SignInPage.path],
      PatientPhase.welcome => const [WelcomePage.path],
      PatientPhase.chatting => const [IntakeChatPage.path],
      PatientPhase.urgent => const [UrgentPage.path, DonePage.path],
      PatientPhase.finished => const [DonePage.path],
    };
    return allowed.contains(path) ? null : allowed.first;
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel().ignore();
    }
    super.dispose();
  }
}

/// Routes for the patient app. Route name = screen ID = Figma frame name
/// (docs/02-app-flow.md). Paths are relative to the base href
/// (`/intake/`), so `/intake/...` in the screen index maps to the path
/// after the prefix.
GoRouter createAppRouter({
  required PatientRouteGuard guard,
  String? initialLocation,
}) => GoRouter(
  initialLocation: initialLocation ?? WelcomePage.path,
  refreshListenable: guard,
  redirect: (context, state) => guard.redirect(state.matchedLocation),
  errorBuilder: (context, state) => const NotFoundPage(),
  routes: [
    GoRoute(
      name: SignInPage.screenId,
      path: SignInPage.path,
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      name: WelcomePage.screenId,
      path: WelcomePage.path,
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      name: IntakeChatPage.screenId,
      path: IntakeChatPage.path,
      builder: (context, state) => const IntakeChatPage(),
    ),
    GoRoute(
      name: UrgentPage.screenId,
      path: UrgentPage.path,
      builder: (context, state) => const UrgentPage(),
    ),
    GoRoute(
      name: DonePage.screenId,
      path: DonePage.path,
      builder: (context, state) => const DonePage(),
    ),
  ],
);
