import 'dart:async';

import 'package:bloom_clinic/app/clinic_timings.dart';
import 'package:bloom_clinic/app/cubit/mode_cubit.dart';
import 'package:bloom_clinic/app/router/app_router.dart';
import 'package:bloom_clinic/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Root of the clinic app: provides the repositories (widgets never call
/// HTTP; blocs read repositories from context), the app-wide auth and mode
/// cubits, and the router.
class App extends StatefulWidget {
  const new({
    required this.repositories,
    this.initialLocation,
    this.signedIn = false,
    this.timings = ClinicTimings.live,
    super.key,
  });

  final BloomRepositories repositories;
  final String? initialLocation;

  /// Start signed in (tests). The real app starts at A01.
  final bool signedIn;
  final ClinicTimings timings;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthCubit _auth = AuthCubit(
    widget.repositories.session,
    signedIn: widget.signedIn,
  );
  late final ModeCubit _mode = ModeCubit(widget.repositories.session)..load();
  late final AuthRefresh _refresh = AuthRefresh(_auth);
  late final GoRouter _router = createAppRouter(
    auth: _auth,
    refresh: _refresh,
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    unawaited(_auth.close());
    unawaited(_mode.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repos = widget.repositories;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IntakeRepository>.value(value: repos.intake),
        RepositoryProvider<BriefRepository>.value(value: repos.brief),
        RepositoryProvider<TrustRepository>.value(value: repos.trust),
        RepositoryProvider<SessionRepository>.value(value: repos.session),
        RepositoryProvider<ClinicTimings>.value(value: widget.timings),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: _auth),
          BlocProvider<ModeCubit>.value(value: _mode),
        ],
        child: MaterialApp.router(
          onGenerateTitle: (context) => context.l10n.clinicAppTitle,
          theme: BloomTheme.clinic(),
          localizationsDelegates: BloomLocalizations.localizationsDelegates,
          supportedLocales: BloomLocalizations.supportedLocales,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
