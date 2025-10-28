// Mock class for Quiz/Test screen
class MockTestQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  MockTestQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

// Mock class for Fill-in-Blanks
class FillBlankQuestion {
  final String sentence;
  final String answer;
  final String? hint;

  FillBlankQuestion({
    required this.sentence,
    required this.answer,
    this.hint,
  });
}
