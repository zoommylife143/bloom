import 'package:core_domain/core_domain.dart';

/// Brief sections shown on D02, in Figma order.
enum BriefSection {
  subjective,
  objective,
  assessment,
  plan,
  flags,
  screenings,
  questions,
}

/// The lines of one section, as shown and as edited.
List<String> sectionLines(Brief brief, BriefSection section) =>
    switch (section) {
      BriefSection.subjective => _split(brief.subjective),
      BriefSection.objective => _split(brief.objective),
      BriefSection.assessment => _split(brief.assessmentConsiderations),
      BriefSection.plan => _split(brief.planConsiderations),
      BriefSection.flags => brief.flags,
      BriefSection.screenings => [
        for (final line in brief.screeningsPossiblyDue) line.text,
      ],
      BriefSection.questions => brief.suggestedQuestions,
    };

List<String> _split(String text) => [
  for (final line in text.split('\n'))
    if (line.trim().isNotEmpty) line.trim(),
];

/// How many lines of [section] the physician changed (added, removed or
/// reworded) compared with the AI draft. 0 when there is no original.
int changedLines(Brief? original, Brief shown, BriefSection section) {
  if (original == null) return 0;
  final a = sectionLines(original, section);
  final b = sectionLines(shown, section);
  var changed = 0;
  final n = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < n; i++) {
    final x = i < a.length ? a[i] : null;
    final y = i < b.length ? b[i] : null;
    if (x != y) changed++;
  }
  return changed;
}

/// Builds the edited brief from the edit form. Multi-line fields keep one
/// item per non-empty line; screening lines keep their citation when the
/// line at the same position still exists.
Brief buildEditedBrief({
  required Brief draft,
  required String subjective,
  required String objective,
  required String assessment,
  required String plan,
  required String flags,
  required String screenings,
  required String questions,
}) {
  final screeningTexts = _split(screenings);
  return draft.copyWith(
    subjective: subjective.trim(),
    objective: objective.trim(),
    assessmentConsiderations: assessment.trim(),
    planConsiderations: plan.trim(),
    flags: _split(flags),
    screeningsPossiblyDue: [
      for (final (i, text) in screeningTexts.indexed)
        ScreeningLine(
          text: text,
          sourceUrl: i < draft.screeningsPossiblyDue.length
              ? draft.screeningsPossiblyDue[i].sourceUrl
              : null,
        ),
    ],
    suggestedQuestions: _split(questions),
  );
}
