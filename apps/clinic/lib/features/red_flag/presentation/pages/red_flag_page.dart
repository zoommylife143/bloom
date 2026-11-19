import 'dart:async';

import 'package:bloom_clinic/app/formatting.dart';
import 'package:bloom_clinic/app/widgets/clinic_widgets.dart';
import 'package:bloom_clinic/app/widgets/status_tag.dart';
import 'package:bloom_clinic/features/queue/presentation/pages/queue_page.dart';
import 'package:bloom_clinic/features/red_flag/presentation/cubit/red_flag_cubit.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// D06 Red-flag summary (Figma 25:722): which deterministic rule fired, on
/// which fields, what the patient was shown, and that no brief exists.
class RedFlagPage extends StatelessWidget {
  const new({required this.id, this.summary, super.key});

  /// Screen ID = Figma frame name = go_router route name.
  static const screenId = 'D06';

  /// Path inside the app. Public URL: `/doctor/flag/:id`.
  static const path = '/flag/:id';

  /// Session ID.
  final String id;
  final SessionSummary? summary;

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(id),
    create: (context) {
      final cubit = RedFlagCubit(
        context.read<SessionRepository>(),
        id,
        summary: summary,
      );
      unawaited(cubit.load());
      return cubit;
    },
    child: const RedFlagView(),
  );
}

class RedFlagView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<RedFlagCubit>();
    final state = context.watch<RedFlagCubit>().state;
    final flag = state.flag;
    final when = flag?.createdAt ?? state.session?.updatedAt;

    final header = Row(
      children: [
        Expanded(
          child: PageHeader(
            compact: true,
            title: l10n.clinicFlagTitle(
              patientLabel(l10n, state.session, cubit.sessionId),
            ),
            subtitle: when == null
                ? l10n.clinicFlagMetaPlain
                : l10n.clinicFlagMeta(formatClock(when)),
          ),
        ),
        const StatusTag(status: ClinicStatus.redFlag),
      ],
    );

    final back = BloomButton.secondary(
      label: l10n.clinicBackToQueue,
      onPressed: () => context.goNamed(QueuePage.screenId),
    );

    return PageBody(
      children: [
        header,
        ClinicBanner(
          type: ClinicBannerType.urgent,
          text: l10n.clinicFlagBanner,
        ),
        ...switch (state.status) {
          RedFlagStatus.loading => [
            Semantics(
              label: l10n.clinicLoading,
              child: SectionCard(
                title: l10n.clinicFlagRuleTitle,
                children: const [
                  SkeletonBar(width: 520),
                  SkeletonBar(width: 380),
                ],
              ),
            ),
          ],
          RedFlagStatus.failure => [
            FailureView(failure: state.failure!, onRetry: cubit.load),
          ],
          RedFlagStatus.loaded => [
            SectionCard(
              title: l10n.clinicFlagRuleTitle,
              children: [
                SectionLine(
                  l10n.clinicFlagRuleLine(
                    flag!.ruleId.id,
                    ruleName(l10n, flag.ruleId),
                  ),
                ),
                SectionLine(
                  flag.matched.isEmpty
                      ? l10n.clinicFlagMatchedNone
                      : l10n.clinicFlagMatched(flag.matched.join(' · ')),
                ),
                if (flag.source != null)
                  SectionLine(
                    flag.source == 'fields'
                        ? l10n.clinicFlagSourceFields
                        : l10n.clinicFlagSourceText,
                  ),
              ],
            ),
            SectionCard(
              title: l10n.clinicFlagShownTitle,
              children: [
                if (flag.title case final t?)
                  Text(t, style: BloomTextStyles.label),
                if (flag.body case final b?) SectionLine(b),
                if (flag.title == null && flag.body == null)
                  SectionLine(l10n.clinicFlagShownFallback),
              ],
            ),
            SectionCard(
              title: l10n.clinicFlagNextTitle,
              children: [
                SectionLine(l10n.clinicFlagNext1),
                SectionLine(l10n.clinicFlagNext2),
              ],
            ),
          ],
        },
        back,
      ],
    );
  }
}
