part of 'brief_bloc.dart';

sealed class BriefEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// First load or retry (shows the loading state).
final class BriefRequested extends BriefEvent {
  const new();
}

/// Quiet re-check while the brief is generating.
final class BriefPolled extends BriefEvent {
  const new();
}

final class BriefEditStarted extends BriefEvent {
  const new();
}

final class BriefEditCancelled extends BriefEvent {
  const new();
}

/// Confirm (`approve`), Edit (`edit` with [edited]) or Reject (`reject`).
final class BriefDecisionSubmitted extends BriefEvent {
  const new(this.decision, {required this.reviewer, this.edited});

  final BriefDecision decision;
  final String reviewer;

  /// The full edited brief; required for [BriefDecision.edit].
  final Brief? edited;

  @override
  List<Object?> get props => [decision, reviewer, edited];
}
