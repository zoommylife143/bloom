import 'dart:async';

import 'package:bloom_clinic/app/widgets/clinic_widgets.dart';
import 'package:bloom_clinic/app/widgets/status_tag.dart';
import 'package:bloom_clinic/features/brief/presentation/pages/brief_page.dart';
import 'package:bloom_clinic/features/demo/domain/negative_test.dart';
import 'package:bloom_clinic/features/demo/domain/scenarios.dart';
import 'package:bloom_clinic/features/demo/presentation/cubit/demo_cubit.dart';
import 'package:bloom_clinic/features/red_flag/presentation/pages/red_flag_page.dart';
import 'package:bloom_clinic/features/trust/presentation/widgets/trust_event_row.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// D05 Demo scenarios (Figma 7:428): run the ten synthetic scenarios
/// through the real graph and the private-mode negative test.
class DemoPage extends StatelessWidget {
  const new({super.key});

  /// Screen ID = Figma frame name = go_router route name.
  static const screenId = 'D05';

  /// Path inside the app. Public URL: `/doctor/demo`.
  static const path = '/demo';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => DemoCubit(
      context.read<SessionRepository>(),
      context.read<TrustRepository>(),
    ),
    child: const DemoView(),
  );
}

/// D05 copy for a failed negative test: the provider failed before it could
/// refuse, so it is not a pass.
String negativeProviderErrorText(BloomLocalizations l10n, int? httpStatus) =>
    httpStatus == null
    ? l10n.clinicNegativeProviderError
    : l10n.clinicNegativeProviderErrorHttp(httpStatus);

class DemoView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageBody(
      children: [
        PageHeader(
          title: l10n.clinicDemoTitle,
          subtitle: l10n.clinicDemoSubtitle,
        ),
        Wrap(
          spacing: BloomSpacing.lg,
          runSpacing: BloomSpacing.lg,
          children: [for (final s in demoScenarios) _ScenarioCard(scenario: s)],
        ),
        const _NegativeTestCard(),
      ],
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const new({required this.scenario});

  final DemoScenario scenario;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final run = context.select<DemoCubit, ScenarioRunState>(
      (c) => c.state.runOf(scenario.id),
    );
    final result = run.run;
    final failure = run.failure;

    return ClinicCard(
      width: 212,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(scenario.id, style: BloomTextStyles.title)),
              StatusTag(
                status: scenario.redFlag
                    ? ClinicStatus.redFlag
                    : ClinicStatus.ready,
              ),
            ],
          ),
          const SizedBox(height: BloomSpacing.sm),
          Text(scenario.summary, style: BloomTextStyles.bodySmall),
          const SizedBox(height: BloomSpacing.sm),
          Text(scenario.expected, style: BloomTextStyles.caption),
          const SizedBox(height: BloomSpacing.sm),
          BloomButton.secondary(
            label: result == null ? l10n.clinicRun : l10n.clinicRunAgain,
            semanticLabel: l10n.clinicRunScenario(scenario.id),
            isLoading: run.isRunning,
            onPressed: () => context.read<DemoCubit>().runScenario(scenario.id),
          ),
          if (run.isRunning) ...[
            const SizedBox(height: BloomSpacing.sm),
            const _RunningNote(),
          ],
          if (result != null) ...[
            const SizedBox(height: BloomSpacing.sm),
            _RunResult(run: result),
          ],
          if (failure != null) ...[
            const SizedBox(height: BloomSpacing.sm),
            Semantics(
              liveRegion: true,
              child: Text(
                isRunTimeout(failure)
                    ? l10n.clinicScenarioTimeout
                    : failureMessage(l10n, failure),
                style: BloomTextStyles.caption.copyWith(
                  color: BloomColors.statusCritical,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Running" with elapsed seconds, so a long run visibly progresses.
class _RunningNote extends StatefulWidget {
  const new();

  @override
  State<_RunningNote> createState() => _RunningNoteState();
}

class _RunningNoteState extends State<_RunningNote> {
  late final Timer _ticker;
  var _seconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _seconds++),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    // Announce once; the seconds counter would be noisy for screen readers.
    label: context.l10n.clinicScenarioRunningLong,
    excludeSemantics: true,
    child: Text(
      context.l10n.clinicScenarioRunningElapsed(_seconds),
      style: BloomTextStyles.caption,
    ),
  );
}

class _RunResult extends StatelessWidget {
  const new({required this.run});

  final ScenarioRun run;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final urgent = run.status == SessionStatus.urgent;
    final hasBrief = run.briefId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            urgent
                ? l10n.clinicScenarioDoneUrgent(run.turnsRun)
                : hasBrief
                ? l10n.clinicScenarioDoneReady(run.turnsRun)
                : l10n.clinicScenarioDoneOther(run.turnsRun),
            style: BloomTextStyles.caption.copyWith(
              color: urgent
                  ? BloomColors.statusCritical
                  : BloomColors.statusVerified,
            ),
          ),
        ),
        if (urgent)
          BloomButton.text(
            label: l10n.clinicViewSummary,
            onPressed: () => context.goNamed(
              RedFlagPage.screenId,
              pathParameters: {'id': run.sessionId},
            ),
          )
        else if (hasBrief)
          BloomButton.text(
            label: l10n.clinicOpenBrief,
            onPressed: () => context.goNamed(
              BriefPage.screenId,
              pathParameters: {'id': run.sessionId},
            ),
          ),
      ],
    );
  }
}

class _NegativeTestCard extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = BloomTokens.of(context);
    final state = context.watch<DemoCubit>().state;
    final result = state.negativeResult;
    final failure = state.negativeFailure;

    final button = BloomButton(
      label: l10n.clinicRunNegativeTest,
      isLoading: state.negativeRunning,
      onPressed: context.read<DemoCubit>().runNegativeTest,
    );

    final Widget? outcome = switch (result) {
      null => null,
      final e => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClinicBanner(
            type: ClinicBannerType.urgent,
            text: switch (negativeTestVerdictOf(e)) {
              NegativeTestVerdict.refused => l10n.clinicRefusedMessage,
              NegativeTestVerdict.providerError => negativeProviderErrorText(
                l10n,
                httpStatusOf(e),
              ),
              NegativeTestVerdict.served => l10n.clinicNegativeServed,
              NegativeTestVerdict.unexpected => l10n.clinicNegativeUnexpected,
            },
          ),
          const SizedBox(height: BloomSpacing.md),
          TrustEventRow(event: e),
        ],
      ),
    };

    return ClinicCard(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: tokens.critical,
              ),
              const SizedBox(width: BloomSpacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.clinicNegativeTitle,
                    style: BloomTextStyles.title,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BloomSpacing.md),
          Text(
            l10n.clinicNegativeBody,
            style: BloomTextStyles.bodySmall.copyWith(
              color: BloomColors.textSecondary,
            ),
          ),
          const SizedBox(height: BloomSpacing.md),
          Wrap(
            spacing: BloomSpacing.lg,
            runSpacing: BloomSpacing.md,
            children: [
              button,
              if (state.negativeRunning)
                Padding(
                  padding: const EdgeInsets.only(top: BloomSpacing.md),
                  child: Text(
                    l10n.clinicNegativeRunning,
                    style: BloomTextStyles.caption,
                  ),
                ),
              if (outcome != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: outcome,
                ),
              if (failure != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ClinicBanner(
                    type: ClinicBannerType.urgent,
                    text: failureMessage(l10n, failure),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
