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

enum ContentStatus {
  pending,
  approved,
  rejected,
}

class UserContent {
  final String id;
  final String authorName;
  final String authorEmail;
  final ContentType type;
  final CourseCategory category;
  final ContentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> content; // Flexible content structure
  
  UserContent({
    required this.id,
    required this.authorName,
    required this.authorEmail,
    required this.type,
    required this.category,
    this.status = ContentStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    required this.content,
  });
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'content': content,
    };
  }
  
  // Create from JSON
  factory UserContent.fromJson(Map<String, dynamic> json) {
    // Handle both MongoDB's _id and client-side id
    final idValue = json['_id'] ?? json['id'];
    final idString = idValue is Map ? idValue['\$oid'] : idValue?.toString();
    
    return UserContent(
      id: idString ?? 'unknown',
      authorName: json['authorName'] as String? ?? json['authorUsername'] as String? ?? 'Unknown',
      authorEmail: json['authorEmail'] as String? ?? 'unknown@email.com',
      type: ContentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ContentType.topic,
      ),
      category: CourseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == (json['category'] ?? 'java'),
        orElse: () => CourseCategory.java,
      ),
      status: ContentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'pending'),
        orElse: () => ContentStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['serverCreatedAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['serverCreatedAt'] as String? ?? DateTime.now().toIso8601String()),
      content: Map<String, dynamic>.from(json['content'] as Map? ?? json),
    );
  }
  
  // Copy with method for updates
  UserContent copyWith({
    String? authorName,
    String? authorEmail,
    Map<String, dynamic>? content,
    CourseCategory? category,
    ContentStatus? status,
  }) {
    return UserContent(
      id: id,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      type: type,
      category: category ?? this.category,
      status: status ?? this.status,
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
