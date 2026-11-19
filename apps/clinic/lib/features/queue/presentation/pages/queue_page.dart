import 'dart:async';

import 'package:bloom_clinic/app/clinic_timings.dart';
import 'package:bloom_clinic/app/formatting.dart';
import 'package:bloom_clinic/app/widgets/clinic_widgets.dart';
import 'package:bloom_clinic/app/widgets/status_tag.dart';
import 'package:bloom_clinic/features/brief/presentation/pages/brief_page.dart';
import 'package:bloom_clinic/features/queue/presentation/cubit/queue_cubit.dart';
import 'package:bloom_clinic/features/red_flag/presentation/pages/red_flag_page.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// D01 Patient queue (Figma 7:2): synthetic pre-visit intakes, red flags
/// first. Red-flag rows open D06; the others open D02.
class QueuePage extends StatelessWidget {
  const new({super.key});

  /// Screen ID = Figma frame name = go_router route name.
  static const screenId = 'D01';

  /// Path inside the app. Public URL: `/doctor/`.
  static const path = '/';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) {
      final cubit = QueueCubit(
        context.read<SessionRepository>(),
        pollInterval: context.read<ClinicTimings>().queuePoll,
      );
      unawaited(cubit.load());
      return cubit;
    },
    child: const QueueView(),
  );
}

class QueueView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<QueueCubit>().state;
    final cubit = context.read<QueueCubit>();

    return PageBody(
      children: [
        PageHeader(
          title: l10n.clinicQueueTitle,
          subtitle: l10n.clinicQueueSubtitle,
          trailing: BloomButton.secondary(
            label: l10n.clinicRefresh,
            isLoading: state.isRefreshing,
            onPressed: cubit.refresh,
          ),
        ),
        ClinicBanner(
          type: ClinicBannerType.demo,
          text: l10n.clinicDemoBanner,
          hug: true,
        ),
        if (state.status == QueueStatus.failure)
          FailureView(failure: state.failure!, onRetry: cubit.load)
        else
          _QueueTable(state: state),
      ],
    );
  }
}

const _colPatient = 200.0;
const _colStatus = 150.0;
const _colUpdated = 140.0;
const _colAction = 150.0;
const _minTableWidth = 820.0;

class _QueueTable extends StatelessWidget {
  const new({required this.state});

  final QueueState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Widget body;
    if (state.status == QueueStatus.loading) {
      body = Semantics(
        label: l10n.clinicLoading,
        child: Column(
          children: [for (var i = 0; i < 4; i++) const _SkeletonRow()],
        ),
      );
    } else if (state.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BloomSpacing.xl,
          vertical: 48,
        ),
        child: Center(
          child: Column(
            children: [
              Text(l10n.clinicQueueEmptyTitle, style: BloomTextStyles.title),
              const SizedBox(height: BloomSpacing.sm),
              Text(
                l10n.clinicQueueEmptyBody,
                textAlign: TextAlign.center,
                style: BloomTextStyles.bodySmall.copyWith(
                  color: BloomColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      body = Column(
        children: [
          for (final (i, s) in state.sessions.indexed)
            _QueueRow(session: s, last: i == state.sessions.length - 1),
        ],
      );
    }

    final table = ClinicCard(
      padding: EdgeInsets.zero,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [const _HeaderRow(), body],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _minTableWidth) return table;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: _minTableWidth, child: table),
        );
      },
    );
  }
}

class _Cells extends StatelessWidget {
  const new({
    required this.patient,
    required this.reason,
    required this.status,
    required this.updated,
    required this.action,
  });

  final Widget patient;
  final Widget reason;
  final Widget status;
  final Widget updated;
  final Widget action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: _colPatient, child: patient),
      const SizedBox(width: BloomSpacing.lg),
      Expanded(child: reason),
      const SizedBox(width: BloomSpacing.lg),
      SizedBox(
        width: _colStatus,
        child: Align(alignment: Alignment.centerLeft, child: status),
      ),
      const SizedBox(width: BloomSpacing.lg),
      SizedBox(width: _colUpdated, child: updated),
      const SizedBox(width: BloomSpacing.lg),
      SizedBox(
        width: _colAction,
        child: Align(alignment: Alignment.centerLeft, child: action),
      ),
    ],
  );
}

class _HeaderRow extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Text h(String s) => Text(s.toUpperCase(), style: BloomTextStyles.overline);
    return Container(
      decoration: const BoxDecoration(
        color: BloomColors.bgSubtle,
        border: Border(bottom: BorderSide(color: BloomColors.borderDefault)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: BloomSpacing.lg,
        vertical: BloomSpacing.md,
      ),
      child: Semantics(
        header: true,
        child: _Cells(
          patient: h(l10n.clinicColPatient),
          reason: h(l10n.clinicColReason),
          status: h(l10n.clinicColStatus),
          updated: h(l10n.clinicColUpdated),
          action: h(l10n.clinicColAction),
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const new({required this.session, required this.last});

  final SessionSummary session;
  final bool last;

  void _open(BuildContext context) {
    switch (queueActionFor(session)) {
      case QueueAction.viewSummary:
        context.goNamed(
          RedFlagPage.screenId,
          pathParameters: {'id': session.id},
          extra: session,
        );
      case QueueAction.openBrief:
        context.goNamed(
          BriefPage.screenId,
          pathParameters: {'id': session.id},
          extra: session,
        );
      case QueueAction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final secondary = BloomTextStyles.bodySmall.copyWith(
      color: BloomColors.textSecondary,
    );
    final action = queueActionFor(session);
    final edited = session.status == SessionStatus.edited;
    return InkWell(
      onTap: action == QueueAction.none ? null : () => _open(context),
      child: Container(
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: BloomColors.borderDefault),
                ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: BloomSpacing.lg,
          vertical: BloomSpacing.md,
        ),
        child: _Cells(
          patient: Text(
            patientLabel(l10n, session, session.id),
            style: BloomTextStyles.label,
          ),
          reason: Text(
            session.reasonForVisit ?? l10n.clinicReasonPending,
            style: secondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          status: Wrap(
            spacing: BloomSpacing.xs,
            runSpacing: BloomSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusTag(status: statusOfSession(session)),
              if (edited) Text(l10n.clinicEditedMarker, style: secondary),
            ],
          ),
          updated: Text(
            formatRelative(l10n, session.updatedAt ?? session.createdAt),
            style: secondary,
          ),
          action: switch (action) {
            QueueAction.viewSummary => BloomButton.text(
              label: l10n.clinicViewSummary,
              onPressed: () => _open(context),
            ),
            QueueAction.openBrief => BloomButton.text(
              label: l10n.clinicOpenBrief,
              onPressed: () => _open(context),
            ),
            QueueAction.none => Padding(
              padding: const EdgeInsets.symmetric(vertical: BloomSpacing.sm),
              child: Semantics(
                label: l10n.clinicNoActionYet,
                excludeSemantics: true,
                child: Text('—', style: secondary),
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(BloomSpacing.lg),
    child: _Cells(
      patient: SkeletonBar(width: 160),
      reason: SkeletonBar(width: double.infinity),
      status: SkeletonBar(width: 96, height: 20),
      updated: SkeletonBar(width: 90),
      action: SizedBox.shrink(),
    ),
  );
}
