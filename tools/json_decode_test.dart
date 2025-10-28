import 'dart:convert';

void main() {
  final samples = {
    'trailing_commas': '{"question": "What is Java?",}',
    'uppercase_type': '{"Type": "Quiz", "question": "x"}',
    'missing_quotes': '{type: quiz, question: what}',
    'valid': '{"type": "quiz", "question": "ok"}'
  };

  samples.forEach((name, sample) {
    print('--- Sample: $name ---');
    try {
      final parsed = jsonDecode(sample);
      print('Parsed OK: ${parsed.runtimeType} -> $parsed');
    } catch (e) {
      print('Error: ${e.runtimeType} -> $e');
    }
  });
}
