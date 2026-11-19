import 'package:bloom_clinic/app/widgets/clinic_widgets.dart';
import 'package:bloom_clinic/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// A01 Sign in (Figma 26:3): demo role entry. The clinician tile calls
/// `POST /api/login {role: doctor}`; the patient tile opens the patient app.
/// Demo login only, not production authentication.
class SignInPage extends StatelessWidget {
  const new({super.key});

  /// Screen ID = Figma frame name = go_router route name.
  static const screenId = 'A01';

  /// Path inside the app. Public URL: `/doctor/sign-in`.
  static const path = '/sign-in';

  /// Patient app (nginx serves it at `/intake/`).
  static final Uri patientAppUri = Uri.parse('/intake/');

  @override
  Widget build(BuildContext context) => const SignInView();
}

class SignInView extends StatefulWidget {
  const new({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _signIn() => context.read<AuthCubit>().signIn(reviewerName: _name.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AuthCubit>().state;
    final failure = state.failure;
    final busy = state.status == AuthStatus.signingIn;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final phone = constraints.maxWidth < 480 + 2 * BloomSpacing.xl;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    size: 24,
                    color: BloomColors.textBrand,
                  ),
                  const SizedBox(width: BloomSpacing.sm),
                  Text(
                    'Bloom',
                    style: BloomTextStyles.heading.copyWith(
                      color: BloomColors.textBrand,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BloomSpacing.lg),
              Semantics(
                header: true,
                child: Text(
                  l10n.clinicSignInTitle,
                  style: BloomTextStyles.display,
                ),
              ),
              const SizedBox(height: BloomSpacing.lg),
              ClinicBanner(
                type: ClinicBannerType.demo,
                text: l10n.clinicDemoBanner,
              ),
              const SizedBox(height: BloomSpacing.lg),
              Text(l10n.clinicReviewerLabel, style: BloomTextStyles.label),
              const SizedBox(height: BloomSpacing.lg),
              TextField(
                controller: _name,
                enabled: !busy,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _signIn(),
                style: BloomTextStyles.body,
                decoration: InputDecoration(
                  hintText: l10n.clinicReviewerHint,
                  hintStyle: BloomTextStyles.body.copyWith(
                    color: BloomColors.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: BloomSpacing.lg,
                    vertical: BloomSpacing.md,
                  ),
                  enabledBorder: failure == null
                      ? null
                      : OutlineInputBorder(
                          borderRadius: BorderRadius.circular(BloomRadius.md),
                          borderSide: const BorderSide(
                            color: BloomColors.statusCritical,
                          ),
                        ),
                ),
              ),
              if (failure != null) ...[
                const SizedBox(height: BloomSpacing.lg),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    failureMessage(l10n, failure),
                    style: BloomTextStyles.caption.copyWith(
                      color: BloomColors.statusCritical,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: BloomSpacing.lg),
              _RoleTile(
                icon: Icons.person_outline,
                title: l10n.clinicRolePatientTitle,
                subtitle: l10n.clinicRolePatientSubtitle,
                onTap: busy
                    ? null
                    : () => launchUrl(
                        SignInPage.patientAppUri,
                        webOnlyWindowName: '_self',
                      ),
              ),
              const SizedBox(height: BloomSpacing.md),
              _RoleTile(
                icon: Icons.medical_services_outlined,
                title: l10n.clinicRoleClinicianTitle,
                subtitle: busy
                    ? l10n.clinicSigningIn
                    : l10n.clinicRoleClinicianSubtitle,
                busy: busy,
                onTap: busy ? null : _signIn,
              ),
              const SizedBox(height: BloomSpacing.lg),
              Text(l10n.clinicSignInFooter, style: BloomTextStyles.caption),
            ],
          );

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(BloomSpacing.xl),
              child: phone
                  ? content
                  : Container(
                      width: 480,
                      padding: const EdgeInsets.all(BloomSpacing.xxl),
                      decoration: BoxDecoration(
                        color: BloomColors.bgSurface,
                        border: Border.all(color: BloomColors.borderDefault),
                        borderRadius: BorderRadius.circular(BloomRadius.lg),
                      ),
                      child: content,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: '$title. $subtitle',
    excludeSemantics: true,
    child: Material(
      color: BloomColors.bgBrandSubtle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BloomRadius.md),
        side: const BorderSide(color: BloomColors.borderBrand),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(BloomRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(BloomSpacing.lg),
          child: Row(
            children: [
              if (busy)
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, size: 24, color: BloomColors.textBrand),
              const SizedBox(width: BloomSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: BloomTextStyles.title),
                    const SizedBox(height: BloomSpacing.xs),
                    Text(
                      subtitle,
                      style: BloomTextStyles.bodySmall.copyWith(
                        color: BloomColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
