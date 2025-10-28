class Course {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<Topic> topics;

  Course({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.topics,
  });
}

class ConceptSection {
  final String heading;
  final String explanation;
  final String codeSnippet;

  ConceptSection({
    required this.heading,
    required this.explanation,
    required this.codeSnippet,
  });
}

class Topic {
  final String id;
  final String title;
  final String explanation;
  final String codeSnippet;
  final List<ConceptSection>? conceptSections;
  final List<String> revisionPoints;
  final List<Question> quizQuestions;

  Topic({
    required this.id,
    required this.title,
    required this.explanation,
    required this.codeSnippet,
    this.conceptSections,
    required this.revisionPoints,
    required this.quizQuestions,
  });
}

class Question {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? fillBlankAnswer;

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.fillBlankAnswer,
  });
}
