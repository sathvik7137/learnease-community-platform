enum ContentType {
  topic,
  quiz,
  fillBlank,
  codeExample,
}

enum CourseCategory {
  java,
  dbms,
}

class UserContent {
  final String id;
  final String authorName;
  final ContentType type;
  final CourseCategory category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> content; // Flexible content structure
  
  UserContent({
    required this.id,
    required this.authorName,
    required this.type,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.content,
  });
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'content': content,
    };
  }
  
  // Create from JSON
  factory UserContent.fromJson(Map<String, dynamic> json) {
    return UserContent(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      type: ContentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      category: CourseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == (json['category'] ?? 'java'),
        orElse: () => CourseCategory.java,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      content: Map<String, dynamic>.from(json['content'] as Map),
    );
  }
  
  // Copy with method for updates
  UserContent copyWith({
    String? authorName,
    Map<String, dynamic>? content,
    CourseCategory? category,
  }) {
    return UserContent(
      id: id,
      authorName: authorName ?? this.authorName,
      type: type,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      content: content ?? this.content,
    );
  }
}

// Template/Example formats for different content types
class ContentTemplates {
  static const String topicTemplate = '''{
  "title": "Your Topic Title",
  "explanation": "Detailed explanation in markdown format.\\n\\n## Subheading\\nMore content here.",
  "codeSnippet": "// Your code example\\npublic class Example {\\n  public static void main(String[] args) {\\n    System.out.println(\\"Hello\\");\\n  }\\n}",
  "revisionPoints": [
    "Key point 1",
    "Key point 2",
    "Key point 3"
  ]
}''';

  static const String quizTemplate = '''{
  "topicTitle": "Related Topic Name",
  "questions": [
    {
      "question": "What is the output of this code?",
      "options": [
        "Option A",
        "Option B",
        "Option C",
        "Option D"
      ],
      "correctIndex": 0
    }
  ]
}''';

  static const String fillBlankTemplate = '''{
  "topicTitle": "Related Topic Name",
  "questions": [
    {
      "statement": "Java is a _____ programming language.",
      "answer": "object-oriented",
      "hint": "Related to OOP"
    }
  ]
}''';

  static const String codeExampleTemplate = '''{
  "title": "Example Title",
  "description": "What this example demonstrates",
  "code": "// Your code here\\npublic class Example {\\n  // implementation\\n}",
  "language": "java"
}''';
  
  static String getTemplate(ContentType type) {
    switch (type) {
      case ContentType.topic:
        return topicTemplate;
      case ContentType.quiz:
        return quizTemplate;
      case ContentType.fillBlank:
        return fillBlankTemplate;
      case ContentType.codeExample:
        return codeExampleTemplate;
    }
  }
}
