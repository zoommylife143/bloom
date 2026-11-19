import 'dart:async';

import 'package:bloom_clinic/app/formatting.dart';
import 'package:bloom_clinic/app/widgets/clinic_widgets.dart';
import 'package:bloom_clinic/features/audit/presentation/cubit/audit_cubit.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// D04 Audit log: who did what, when (metadata only, no clinical text).
/// Cut from Figma this week; a simple table over `GET /api/audit`.
class AuditPage extends StatelessWidget {
  const new({super.key});

  /// Screen ID = Figma frame name = go_router route name.
  static const screenId = 'D04';

  /// Path inside the app. Public URL: `/doctor/audit`.
  static const path = '/audit';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) {
      final cubit = AuditCubit(context.read<TrustRepository>());
      unawaited(cubit.load());
      return cubit;
    },
    child: const AuditView(),
  );
}

class AuditView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AuditCubit>();
    final state = context.watch<AuditCubit>().state;
    final time = DateFormat.MMMd().add_jms();
    final secondary = BloomTextStyles.bodySmall.copyWith(
      color: BloomColors.textSecondary,
    );

    Widget row(List<Widget> cells, {bool header = false, bool last = false}) =>
        Container(
          decoration: BoxDecoration(
            color: header ? BloomColors.bgSubtle : null,
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
          child: Row(
            children: [
              SizedBox(width: 200, child: cells[0]),
              const SizedBox(width: BloomSpacing.lg),
              SizedBox(width: 100, child: cells[1]),
              const SizedBox(width: BloomSpacing.lg),
              Expanded(child: cells[2]),
              const SizedBox(width: BloomSpacing.lg),
              SizedBox(width: 120, child: cells[3]),
            ],
          ),
        );
    Text h(String s) => Text(s.toUpperCase(), style: BloomTextStyles.overline);

    return PageBody(
      children: [
        PageHeader(
          title: l10n.clinicAuditTitle,
          subtitle: l10n.clinicAuditSubtitle,
          trailing: BloomButton.secondary(
            label: l10n.clinicRefresh,
            isLoading: state.status == AuditStatus.loading,
            onPressed: cubit.load,
          ),
        ),
        switch (state.status) {
          AuditStatus.failure => FailureView(
            failure: state.failure!,
            onRetry: cubit.load,
          ),
          _ => _ScrollableTable(
            child: ClinicCard(
              padding: EdgeInsets.zero,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  row(header: true, [
                    h(l10n.clinicAuditColTime),
                    h(l10n.clinicAuditColActor),
                    h(l10n.clinicAuditColAction),
                    h(l10n.clinicAuditColSession),
                  ]),
                  if (state.status == AuditStatus.loading)
                    for (var i = 0; i < 4; i++)
                      row([
                        const SkeletonBar(width: 140),
                        const SkeletonBar(width: 60),
                        const SkeletonBar(width: 200),
                        const SkeletonBar(width: 80),
                      ])
                  else if (state.rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(BloomSpacing.xl),
                      child: Center(
                        child: Text(l10n.clinicAuditEmpty, style: secondary),
                      ),
                    )
                  else
                    for (final (i, r) in state.rows.indexed)
                      row(last: i == state.rows.length - 1, [
                        Text(
                          r.createdAt == null
                              ? '—'
                              : time.format(r.createdAt!.toLocal()),
                          style: secondary,
                        ),
                        Text(r.actor ?? '—', style: BloomTextStyles.label),
                        Text(
                          r.action.replaceAll('_', ' '),
                          style: BloomTextStyles.bodySmall,
                        ),
                        Text(
                          r.sessionId == null ? '—' : shortId(r.sessionId!),
                          style: secondary,
                        ),
                      ]),
                ],
              ),
            ),
          ),
        },
      ],
    );
  }
}

/// Below [minWidth] the fixed columns no longer fit; scroll the table
/// horizontally instead of overflowing (phones).
class _ScrollableTable extends StatelessWidget {
  const new({required this.child});

  static const minWidth = 720.0;

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= minWidth) return child;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: minWidth, child: child),
      );
    },
  );
}
