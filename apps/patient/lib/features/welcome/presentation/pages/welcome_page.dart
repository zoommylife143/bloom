import 'package:bloom_patient/app/view/widgets/bloom_wordmark.dart';
import 'package:bloom_patient/app/view/widgets/content_column.dart';
import 'package:bloom_patient/app/view/widgets/patient_button.dart';
import 'package:bloom_patient/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:bloom_patient/features/intake/presentation/bloc/intake_bloc.dart';
import 'package:bloom_patient/features/welcome/presentation/widgets/privacy_card.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// P01 Welcome + consent (Figma 6:2, loading 23:33). The patient ticks the
/// consent box, then Start creates the session; the router moves to P02 once
/// it exists.
class WelcomePage extends StatefulWidget {
  const new({super.key});

  /// Screen ID = Figma frame name = go_router route name.
  static const screenId = 'P01';

  /// Path inside the app. Public URL: `/intake/` (base href `/intake/`).
  static const path = '/';

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  var _consented = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mode = context.select<AuthCubit, RouteMode?>((c) => c.state.mode);
    final intake = context.watch<IntakeBloc>().state;
    final starting = intake is IntakeSending;
    final startFailure = switch (intake) {
      IntakeError(:final failure, :final conversation)
          when !conversation.hasSession =>
        failure,
      _ => null,
    };

    return Scaffold(
      body: SafeArea(
        child: ContentColumn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: BloomSpacing.lg,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: BloomSpacing.lg,
                    children: [
                      const BloomWordmark(),
                      BloomBanner.demo(message: l10n.patientDemoBanner),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.patientWelcomeTitle,
                          style: theme.textTheme.displaySmall,
                        ),
                      ),
                      Text(
                        l10n.patientWelcomeIntro,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: BloomColors.textSecondary,
                        ),
                      ),
                      PrivacyCard(mode: mode),
                      Text(
                        l10n.patientWelcomeSkipNote,
                        style: theme.textTheme.bodySmall,
                      ),
                      _ConsentCheck(
                        value: _consented,
                        enabled: !starting,
                        onChanged: (value) =>
                            setState(() => _consented = value),
                      ),
                      if (startFailure != null)
                        BloomBanner(
                          variant: BloomBannerVariant.critical,
                          message: startFailure is NetworkFailure
                              ? l10n.patientErrorNetwork
                              : l10n.patientErrorGeneric,
                        ),
                    ],
                  ),
                ),
              ),
              PatientButton(
                label: starting
                    ? l10n.patientWelcomeStarting
                    : l10n.patientWelcomeStart,
                expand: true,
                semanticHint: _consented ? null : l10n.patientWelcomeConsent,
                onPressed: _consented && !starting
                    ? () => context.read<IntakeBloc>().add(
                        startFailure == null
                            ? const IntakeStarted()
                            : const IntakeRetried(),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentCheck extends StatelessWidget {
  const new({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.patientWelcomeConsent;
    return MergeSemantics(
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(BloomRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: BloomSpacing.minTapTarget,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                onChanged: enabled ? (v) => onChanged(v ?? false) : null,
              ),
              const SizedBox(width: BloomSpacing.xs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: BloomSpacing.md),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
