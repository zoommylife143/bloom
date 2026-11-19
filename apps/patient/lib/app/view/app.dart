import 'package:bloom_patient/app/router/app_router.dart';
import 'package:bloom_patient/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:bloom_patient/features/intake/presentation/bloc/intake_bloc.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Root of the patient app: provides the repositories, the app-wide
/// [AuthCubit] and [IntakeBloc] (the intake outlives single pages: P01
/// starts it, P02 runs it, P03 reads its urgent message) and the router.
/// Widgets never call HTTP.
class App extends StatefulWidget {
  const new({
    required this.repositories,
    this.initialLocation,
    this.authCubit,
    this.intakeBloc,
    super.key,
  });

  final BloomRepositories repositories;
  final String? initialLocation;

  /// Overrides for tests; created from [repositories] when null.
  final AuthCubit? authCubit;
  final IntakeBloc? intakeBloc;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthCubit _auth =
      widget.authCubit ?? AuthCubit(sessions: widget.repositories.session);
  late final IntakeBloc _intake =
      widget.intakeBloc ?? IntakeBloc(repository: widget.repositories.intake);
  late final PatientRouteGuard _guard = PatientRouteGuard(
    auth: _auth,
    intake: _intake,
  );
  late final GoRouter _router = createAppRouter(
    guard: _guard,
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    _guard.dispose();
    if (widget.authCubit == null) _auth.close().ignore();
    if (widget.intakeBloc == null) _intake.close().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repos = widget.repositories;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IntakeRepository>.value(value: repos.intake),
        RepositoryProvider<SessionRepository>.value(value: repos.session),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _auth),
          BlocProvider.value(value: _intake),
        ],
        child: BlocListener<IntakeBloc, IntakeState>(
          // The server rejected the demo token: back to A01, forget the
          // session.
          listenWhen: (_, state) =>
              state is IntakeError &&
              state.failure is ServerFailure &&
              (state.failure as ServerFailure).statusCode == 401,
          listener: (context, state) {
            _intake.add(const IntakeReset());
            _auth.expire();
          },
          child: MaterialApp.router(
            onGenerateTitle: (context) => context.l10n.patientAppTitle,
            theme: BloomTheme.patient(),
            localizationsDelegates: BloomLocalizations.localizationsDelegates,
            supportedLocales: BloomLocalizations.supportedLocales,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
  }
}
