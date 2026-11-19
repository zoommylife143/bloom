import 'package:bloom_patient/app/view/widgets/bloom_wordmark.dart';
import 'package:bloom_patient/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:bloom_patient/features/auth/presentation/widgets/role_tile.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// A01 Sign in (Figma 26:3, phone 26:74). Demo role entry: "Continue as
/// patient" calls `POST /api/login {role: patient}`; "Continue as clinician"
/// opens the clinic app. No access code (brief 06: no codes or phone states).
class SignInPage extends StatelessWidget {
  const new({this.openClinic, super.key});

  /// Screen ID = Figma frame name = go_router route name.
  static const screenId = 'A01';

  /// Path inside the app. Public URL: `/intake/sign-in` (base href
  /// `/intake/`).
  static const path = '/sign-in';

  /// The clinic app, served next to this one by nginx (deploy/nginx.conf).
  static final Uri clinicUrl = Uri.base.resolve('/doctor/');

  /// Overrides opening the clinic app (tests).
  final VoidCallback? openClinic;

  /// Card chrome is dropped below this width (Figma phone frame 26:74).
  static const double _cardBreakpoint = 480 + 2 * BloomSpacing.xl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final asCard = constraints.maxWidth >= _cardBreakpoint;
            final content = BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final signingIn = state.status == AuthStatus.signingIn;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  spacing: BloomSpacing.lg,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: BloomWordmark(),
                    ),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.patientSignInTitle,
                        style: theme.textTheme.displaySmall,
                      ),
                    ),
                    BloomBanner.demo(message: l10n.patientDemoBanner),
                    if (state.expired)
                      BloomBanner(message: l10n.patientSignInExpired),
                    if (state.failure case final failure?)
                      BloomBanner(
                        variant: BloomBannerVariant.critical,
                        message: failure is NetworkFailure
                            ? l10n.patientErrorNetwork
                            : l10n.patientErrorGeneric,
                      ),
                    RoleTile(
                      icon: Icons.person_outline,
                      title: l10n.patientSignInAsPatient,
                      subtitle: signingIn
                          ? l10n.patientSignInSigningIn
                          : l10n.patientSignInAsPatientDetail,
                      busy: signingIn,
                      onTap: signingIn
                          ? null
                          : () => context.read<AuthCubit>().signIn(),
                    ),
                    RoleTile(
                      // TODO(figma): stethoscope in Figma (26:28); no
                      // Material equivalent, closest substitute.
                      icon: Icons.medical_services_outlined,
                      title: l10n.patientSignInAsClinician,
                      subtitle: l10n.patientSignInAsClinicianDetail,
                      onTap: openClinic ?? _openClinic,
                    ),
                    Text(
                      l10n.patientSignInFootnote,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                );
              },
            );

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(BloomSpacing.xl),
                child: asCard
                    ? Container(
                        width: 480,
                        padding: const EdgeInsets.all(BloomSpacing.xxl),
                        decoration: BoxDecoration(
                          color: BloomColors.bgSurface,
                          border: Border.all(color: BloomColors.borderDefault),
                          borderRadius: BorderRadius.circular(BloomRadius.lg),
                        ),
                        child: content,
                      )
                    : content,
              ),
            );
          },
        ),
      ),
    );
  }

  static void _openClinic() =>
      launchUrl(clinicUrl, webOnlyWindowName: '_self').ignore();
}
