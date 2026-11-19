import 'package:bloom_patient/features/intake/domain/question_hints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuestionHints', () {
    test('pregnancy question offers Yes / No / Not sure / Skip', () {
      final hints = QuestionHints.of(
        'Is there any chance you could be pregnant? You can skip this.',
      );
      expect(hints.quickReplies, ['Yes', 'No', 'Not sure', 'Skip']);
      expect(hints.isOptional, isTrue);
    });

    test('age group question offers the server age bands', () {
      final hints = QuestionHints.of(
        'Which age group are you in: 18-24, 25-29, 30-39, 40-49, 50-64, '
        'or 65 and over?',
      );
      expect(hints.quickReplies, contains('30-39'));
    });

    test('yes/no question offers Yes / No', () {
      expect(
        QuestionHints.of('Thanks. Do you take any medicines?').quickReplies,
        ['Yes', 'No'],
      );
    });

    test('opening greeting gets no chips and no optional marker', () {
      final hints = QuestionHints.of(
        "Hi, I'm Bloom. You can skip any question. "
        'What brings you in today?',
      );
      expect(hints.quickReplies, isEmpty);
      expect(hints.isOptional, isFalse);
    });

    test('open question and closing line get no chips', () {
      expect(
        QuestionHints.of('When did your last period start?').quickReplies,
        isEmpty,
      );
      expect(QuestionHints.of('Thank you. That is all.').quickReplies, isEmpty);
    });

    test('either/or questions get no yes/no chips', () {
      expect(
        QuestionHints.of('Is the pain sharp or dull?').quickReplies,
        isEmpty,
      );
    });
  });
}
