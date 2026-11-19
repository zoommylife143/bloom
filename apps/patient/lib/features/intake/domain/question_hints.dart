/// Client-side hints for one Bloom question: tap-to-answer chips and the
/// "optional question" marker. The server sends free text only, so these are
/// read from the wording. They only shape the input; the server still decides
/// what to ask next and every red-flag rule runs on the server.
class QuestionHints {
  const new({this.quickReplies = const [], this.isOptional = false});

  /// Reads hints from Bloom's question. Only the last sentence that ends in
  /// "?" counts, so "Thanks. Do you ...?" works and the opening greeting
  /// ("You can skip any question. What brings you in today?") gets no chips.
  factory of(String question) {
    final isOptional = _optional.hasMatch(question);
    final asked = _lastQuestion(question);
    if (asked == null) return QuestionHints(isOptional: isOptional);

    final List<String> replies;
    if (_pregnant.hasMatch(asked)) {
      replies = _yesNoUnsure;
    } else if (_ageGroup.hasMatch(asked)) {
      replies = _ageBands;
    } else if (_yesNoStart.hasMatch(asked) && !asked.contains(' or ')) {
      replies = isOptional ? _yesNo : _yesNo.sublist(0, 2);
    } else {
      replies = const [];
    }
    return QuestionHints(quickReplies: replies, isOptional: isOptional);
  }

  /// Text sent when the patient taps "Skip". Matches the server prompt, which
  /// records a skip as "declined".
  static const skip = 'Skip';

  static const List<String> _yesNoUnsure = ['Yes', 'No', 'Not sure', skip];
  static const List<String> _yesNo = ['Yes', 'No', skip];
  static const _ageBands = [
    '18-24',
    '25-29',
    '30-39',
    '40-49',
    '50-64',
    '65 or over',
  ];

  static final _optional = RegExp(
    r'(you can|feel free to|it.s ok(ay)? to) skip (this|that|it)\b|\boptional\b',
    caseSensitive: false,
  );
  static final _pregnant = RegExp(r'\bpregnan', caseSensitive: false);
  static final _ageGroup = RegExp(
    r'\bage (group|range|band)\b|\bhow old\b',
    caseSensitive: false,
  );
  static final _yesNoStart = RegExp(
    r'^(do|does|did|are|is|have|has|were|was|could|can|any)\b',
    caseSensitive: false,
  );

  /// Chips to show under the question, if any.
  final List<String> quickReplies;

  /// Bloom said this question can be skipped.
  final bool isOptional;

  static String? _lastQuestion(String text) {
    final end = text.lastIndexOf('?');
    if (end < 0) return null;
    final before = text.substring(0, end);
    final start = before.lastIndexOf(RegExp('[.!?]'));
    return text.substring(start + 1, end + 1).trim();
  }
}
