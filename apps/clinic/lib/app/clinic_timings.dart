/// Polling intervals. Null disables polling (widget tests).
class ClinicTimings {
  const new({this.queuePoll, this.briefPoll});

  /// Live defaults: refresh the queue every 10 s, re-check a brief that is
  /// still generating every 3 s.
  static const live = ClinicTimings(
    queuePoll: Duration(seconds: 10),
    briefPoll: Duration(seconds: 3),
  );

  static const none = ClinicTimings();

  final Duration? queuePoll;
  final Duration? briefPoll;
}
