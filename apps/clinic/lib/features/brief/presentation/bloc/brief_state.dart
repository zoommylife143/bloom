part of 'brief_bloc.dart';

enum BriefStatus { loading, generating, ready, failure }

/// What D02 shows (Figma states).
enum BriefView {
  loading,
  generating,
  draft,
  noGuideline,
  approved,
  edited,
  rejected,
  failure,
}

const _unset = Object();

class BriefState extends Equatable {
  const new({
    this.status = BriefStatus.loading,
    this.bundle,
    this.session,
    this.failure,
    this.isEditing = false,
    this.submitting,
    this.decisionFailure,
  });

  final BriefStatus status;
  final BriefBundle? bundle;

  /// Queue row for the header (scenario, age band). Optional.
  final SessionSummary? session;

  /// Load failure (status == failure).
  final AppFailure? failure;
  final bool isEditing;

  /// Decision in flight.
  final BriefDecision? submitting;

  /// Last decision failure, e.g. 409 already decided.
  final AppFailure? decisionFailure;

  ReviewStatus? get review => bundle?.provenance.reviewStatus;

  /// True once a physician decision is stored.
  bool get isDecided => review != null && review != ReviewStatus.draft;

  /// No screening line cites a guideline.
  bool get hasNoGuideline =>
      bundle != null &&
      bundle!.brief.screeningsPossiblyDue.every((l) => l.sourceUrl == null);

  BriefView get view => switch (status) {
    BriefStatus.loading => BriefView.loading,
    BriefStatus.generating => BriefView.generating,
    BriefStatus.failure => BriefView.failure,
    BriefStatus.ready => switch (review!) {
      ReviewStatus.approved => BriefView.approved,
      ReviewStatus.edited => BriefView.edited,
      ReviewStatus.rejected => BriefView.rejected,
      ReviewStatus.draft =>
        hasNoGuideline ? BriefView.noGuideline : BriefView.draft,
    },
  };

  BriefState copyWith({
    BriefStatus? status,
    Object? bundle = _unset,
    Object? session = _unset,
    Object? failure = _unset,
    bool? isEditing,
    Object? submitting = _unset,
    Object? decisionFailure = _unset,
  }) => BriefState(
    status: status ?? this.status,
    bundle: bundle == _unset ? this.bundle : bundle as BriefBundle?,
    session: session == _unset ? this.session : session as SessionSummary?,
    failure: failure == _unset ? this.failure : failure as AppFailure?,
    isEditing: isEditing ?? this.isEditing,
    submitting: submitting == _unset
        ? this.submitting
        : submitting as BriefDecision?,
    decisionFailure: decisionFailure == _unset
        ? this.decisionFailure
        : decisionFailure as AppFailure?,
  );

  @override
  List<Object?> get props => [
    status,
    bundle,
    session,
    failure,
    isEditing,
    submitting,
    decisionFailure,
  ];
}
