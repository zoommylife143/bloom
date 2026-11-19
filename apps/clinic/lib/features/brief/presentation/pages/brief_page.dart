import 'dart:async';

import 'package:bloom_clinic/app/clinic_timings.dart';
import 'package:bloom_clinic/app/formatting.dart';
import 'package:bloom_clinic/app/widgets/clinic_widgets.dart';
import 'package:bloom_clinic/app/widgets/status_tag.dart';
import 'package:bloom_clinic/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bloom_clinic/features/brief/presentation/bloc/brief_bloc.dart';
import 'package:bloom_clinic/features/brief/presentation/widgets/brief_edit_form.dart';
import 'package:bloom_clinic/features/brief/presentation/widgets/brief_sections.dart';
import 'package:bloom_clinic/features/trust/presentation/cubit/trust_cubit.dart';
import 'package:bloom_clinic/features/trust/presentation/widgets/trust_panel.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// D02 Physician brief (Figma 7:139) with the D03 Privacy & Trust panel as
/// its right column (below the brief on narrow screens).
class BriefPage extends StatelessWidget {
  const new({
    required this.id,
    this.summary,
    this.focusTrust = false,
    super.key,
  });

  /// Screen ID = Figma frame name = go_router route name.
  static const screenId = 'D02';

  /// D03 route name: D02 scrolled to the Privacy & Trust panel.
  static const trustScreenId = 'D03';

  /// Path inside the app. Public URL: `/doctor/brief/:id`.
  static const path = '/brief/:id';

  /// D03 sub-path: `/doctor/brief/:id/trust`.
  static const trustSubPath = 'trust';

  /// Session ID.
  final String id;

  /// Queue row, when opened from D01 (header label without a second call).
  final SessionSummary? summary;
  final bool focusTrust;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    key: ValueKey(id),
    providers: [
      BlocProvider(
        create: (context) => BriefBloc(
          briefRepository: context.read<BriefRepository>(),
          sessionRepository: context.read<SessionRepository>(),
          sessionId: id,
          summary: summary,
          pollInterval: context.read<ClinicTimings>().briefPoll,
        )..add(const BriefRequested()),
      ),
      BlocProvider(
        create: (context) {
          final cubit = TrustCubit(context.read<TrustRepository>(), id);
          unawaited(cubit.load());
          return cubit;
        },
      ),
    ],
    child: BriefScreen(focusTrust: focusTrust),
  );
}

class BriefScreen extends StatefulWidget {
  const new({this.focusTrust = false, super.key});

  final bool focusTrust;

  /// Two columns (brief + 424 px trust panel) from this content width.
  static const twoColumnWidth = 960.0;
  static const trustWidth = 424.0;

  @override
  State<BriefScreen> createState() => _BriefViewState();
}

class _BriefViewState extends State<BriefScreen> {
  final GlobalKey<State<StatefulWidget>> _trustKey = GlobalKey();
  var _focused = false;

  void _maybeFocusTrust(TrustState state) {
    if (!widget.focusTrust || _focused || state.status != TrustStatus.loaded) {
      return;
    }
    _focused = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _trustKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
        ).ignore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final brief = context.watch<BriefBloc>().state;
    final trust = context.watch<TrustCubit>().state;
    _maybeFocusTrust(trust);

    final panel = KeyedSubtree(
      key: _trustKey,
      child: TrustPanel(
        state: trust,
        approval: _approvalOf(brief),
        generating: brief.status == BriefStatus.generating,
        sampleQuery: brief.bundle?.evidence
            .map((e) => e.query)
            .where((q) => q.isNotEmpty)
            .firstOrNull,
      ),
    );

    return BlocListener<BriefBloc, BriefState>(
      // Reload D03 whenever the brief changes state (generated, decided).
      listenWhen: (a, b) =>
          a.status != b.status || a.bundle?.provenance != b.bundle?.provenance,
      listener: (context, _) => unawaited(context.read<TrustCubit>().load()),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth - 2 * BloomSpacing.xxl >=
              BriefScreen.twoColumnWidth;
          if (wide) {
            return PageBody(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _BriefColumn(state: brief)),
                    const SizedBox(width: BloomSpacing.xl),
                    SizedBox(width: BriefScreen.trustWidth, child: panel),
                  ],
                ),
              ],
            );
          }
          return PageBody(
            children: [
              _BriefColumn(state: brief),
              panel,
            ],
          );
        },
      ),
    );
  }
}

ClinicStatus _approvalOf(BriefState s) => switch (s.view) {
  BriefView.loading ||
  BriefView.generating ||
  BriefView.failure => ClinicStatus.inProgress,
  BriefView.draft || BriefView.noGuideline => ClinicStatus.draft,
  BriefView.approved || BriefView.edited => ClinicStatus.approved,
  BriefView.rejected => ClinicStatus.rejected,
};

class _BriefColumn extends StatelessWidget {
  const new({required this.state});

  final BriefState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<BriefBloc>();
    final bundle = state.bundle;
    final view = state.view;
    final prov = bundle?.provenance;
    final reviewer = prov?.reviewedBy ?? '';
    final reviewedAt = prov?.reviewedAt == null
        ? ''
        : formatClock(prov!.reviewedAt!);

    final title = l10n.clinicBriefTitle(
      patientLabel(l10n, state.session, bloc.sessionId),
    );
    final meta = switch (view) {
      BriefView.generating => l10n.clinicBriefMetaGenerating,
      _ when prov?.createdAt != null => l10n.clinicBriefMeta(
        formatClock(prov!.createdAt!),
      ),
      _ => l10n.clinicBriefMetaPlain,
    };

    final tag = switch (view) {
      BriefView.loading || BriefView.failure => null,
      _ => StatusTag(status: _approvalOf(state)),
    };

    final banner = switch (view) {
      BriefView.loading || BriefView.failure => null,
      BriefView.generating => ClinicBanner(
        type: ClinicBannerType.draft,
        text: l10n.clinicGeneratingBanner,
      ),
      BriefView.draft || BriefView.noGuideline =>
        state.isEditing
            ? null
            : ClinicBanner(
                type: ClinicBannerType.draft,
                text: l10n.clinicDraftBanner,
              ),
      BriefView.approved => ClinicBanner(
        type: ClinicBannerType.verified,
        text: l10n.clinicApprovedBanner(reviewer, reviewedAt),
      ),
      BriefView.edited => ClinicBanner(
        type: ClinicBannerType.verified,
        text: l10n.clinicEditedBanner(reviewer, reviewedAt),
      ),
      BriefView.rejected => ClinicBanner(
        type: ClinicBannerType.urgent,
        text: l10n.clinicRejectedBanner(reviewer, reviewedAt),
      ),
    };

    // Server-built DRAFT with no AI (`provenance.source == fallback`): say so
    // in words, above everything else, in every state that shows the brief.
    final fallback = switch (view) {
      BriefView.loading || BriefView.generating || BriefView.failure => null,
      _ when prov?.isFallback ?? false => BloomBanner(
        key: const Key('brief-fallback-banner'),
        variant: BloomBannerVariant.warning,
        title: l10n.clinicFallbackDraftTitle,
        message: l10n.clinicFallbackDraftBody,
      ),
      _ => null,
    };

    final updates = bundle == null
        ? const <String>[]
        : bundle.guidelineUpdates.toSet().toList();
    final decisionFailure = state.decisionFailure;

    final children = <Widget>[
      Row(
        children: [
          Expanded(
            child: PageHeader(title: title, subtitle: meta, compact: true),
          ),
          ?tag,
        ],
      ),
      ?fallback,
      ?banner,
      for (final url in updates)
        BloomBanner(
          variant: BloomBannerVariant.warning,
          title: l10n.clinicGuidelineUpdatedTitle,
          message: l10n.clinicGuidelineUpdatedBody(hostOf(url)),
        ),
      if (decisionFailure != null)
        ClinicBanner(
          type: ClinicBannerType.urgent,
          text: decisionFailure is LockedFailure
              ? l10n.clinicAlreadyDecided
              : failureMessage(l10n, decisionFailure),
        ),
      ...switch (view) {
        BriefView.loading => [const BriefSkeleton()],
        BriefView.generating => [const BriefSkeleton()],
        BriefView.failure => [
          FailureView(
            failure: state.failure!,
            onRetry: () => bloc.add(const BriefRequested()),
          ),
        ],
        _ when state.isEditing => [
          BriefEditForm(
            draft: bundle!.brief,
            isSaving: state.submitting != null,
            onCancel: () => bloc.add(const BriefEditCancelled()),
            onSave: (edited) => bloc.add(
              BriefDecisionSubmitted(
                BriefDecision.edit,
                reviewer: context.read<AuthCubit>().state.reviewerName,
                edited: edited,
              ),
            ),
          ),
        ],
        _ => [
          BriefSections(bundle: bundle!),
          if (!state.isDecided) _Decision(state: state),
          _Provenance(bundle: bundle),
        ],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: BloomSpacing.lg),
          children[i],
        ],
      ],
    );
  }
}

class _Decision extends StatelessWidget {
  const new({required this.state});

  final BriefState state;

  Future<void> _reject(BuildContext context) async {
    final l10n = context.l10n;
    final bloc = context.read<BriefBloc>();
    final reviewer = context.read<AuthCubit>().state.reviewerName;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clinicRejectTitle),
        content: Text(l10n.clinicRejectBody),
        actions: [
          BloomButton.text(
            label: l10n.clinicCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          BloomButton(
            label: l10n.clinicRejectConfirm,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      bloc.add(
        BriefDecisionSubmitted(BriefDecision.reject, reviewer: reviewer),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BriefBloc>();
    return Align(
      alignment: Alignment.centerLeft,
      child: ClinicCard(
        padding: const EdgeInsets.symmetric(
          horizontal: BloomSpacing.lg,
          vertical: BloomSpacing.md,
        ),
        child: DecisionBar(
          draftLabel: context.l10n.clinicDecisionDraftLabel,
          isBusy: state.submitting != null,
          onConfirm: () => bloc.add(
            BriefDecisionSubmitted(
              BriefDecision.approve,
              reviewer: context.read<AuthCubit>().state.reviewerName,
            ),
          ),
          onEdit: () => bloc.add(const BriefEditStarted()),
          onReject: () => _reject(context),
        ),
      ),
    );
  }
}

/// Stored provenance: which model drafted it, when, on how many guideline
/// sources, and who reviewed it.
class _Provenance extends StatelessWidget {
  const new({required this.bundle});

  final BriefBundle bundle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = bundle.provenance;
    final parts = [
      l10n.clinicProvenanceGenerated(p.generatedBy),
      if (p.createdAt != null) formatClock(p.createdAt!),
      l10n.clinicProvenanceSources(p.evidenceUrls.length),
      if (p.reviewedBy != null)
        l10n.clinicProvenanceReviewed(
          p.reviewedBy!,
          p.reviewedAt == null ? '' : formatClock(p.reviewedAt!),
        ),
    ];
    return Semantics(
      label: l10n.clinicProvenanceLabel,
      child: Text(parts.join(' · '), style: BloomTextStyles.caption),
    );
  }
}
