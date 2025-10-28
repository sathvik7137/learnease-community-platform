import '../models/user_content.dart';
import '../models/fill_blank.dart';
import '../models/course.dart';
import 'user_content_service.dart';

/// Service to integrate community contributions with actual course content
class CommunityIntegrationService {
  /// Get community quizzes for a specific topic and convert them to Question format
  static Future<List<Question>> getCommunityQuizzesForTopic(
    String topicId,
    CourseCategory category,
  ) async {
    final contributions = await UserContentService.getContributionsByTypeAndCategory(
      ContentType.quiz,
      category,
    );

    final List<Question> questions = [];
    
    for (final contribution in contributions) {
      try {
        final content = contribution.content;
        final questionsData = content['questions'] as List?;
        
        if (questionsData != null) {
          for (final q in questionsData) {
            final questionMap = q as Map<String, dynamic>;
            questions.add(
              Question(
                question: questionMap['question'] as String,
                options: List<String>.from(questionMap['options'] as List),
                correctIndex: questionMap['correctIndex'] as int,
              ),
            );
          }
        }
      } catch (e) {
        print('Error converting community quiz: $e');
      }
    }
    
    return questions;
  }

  /// Get community fill-in-the-blanks for a specific topic
  static Future<List<FillBlankQuestion>> getCommunityFillBlanksForTopic(
    String topicId,
    CourseCategory category,
  ) async {
    final contributions = await UserContentService.getContributionsByTypeAndCategory(
      ContentType.fillBlank,
      category,
    );

    final List<FillBlankQuestion> questions = [];
    
    for (final contribution in contributions) {
      try {
        final content = contribution.content;
        final questionsData = content['questions'] as List?;
        
        if (questionsData != null) {
          for (final q in questionsData) {
            final questionMap = q as Map<String, dynamic>;
            questions.add(
              FillBlankQuestion(
                id: 'community_${contribution.id}_${questions.length}',
                statement: questionMap['statement'] as String,
                answer: questionMap['answer'] as String,
                topicId: topicId,
                hint: questionMap['hint'] as String? ?? '',
              ),
            );
          }
        }
      } catch (e) {
        print('Error converting community fill blank: $e');
      }
    }
    
    return questions;
  }

  /// Get all community quizzes for a course category (Java or DBMS)
  static Future<List<Question>> getAllCommunityQuizzesForCategory(
    CourseCategory category,
  ) async {
    return await getCommunityQuizzesForTopic('', category);
  }

  /// Get all community fill-in-the-blanks for a course category (Java or DBMS)
  static Future<List<FillBlankQuestion>> getAllCommunityFillBlanksForCategory(
    CourseCategory category,
  ) async {
    return await getCommunityFillBlanksForTopic('', category);
  }

  /// Get community topics as a list of Topic objects
  static Future<List<Topic>> getCommunityTopicsForCategory(
    CourseCategory category,
  ) async {
    final contributions = await UserContentService.getContributionsByTypeAndCategory(
      ContentType.topic,
      category,
    );

    final List<Topic> topics = [];
    
    for (final contribution in contributions) {
      try {
        final content = contribution.content;
        topics.add(
          Topic(
            id: 'community_${contribution.id}',
            title: '🌐 ${content['title'] as String}',
            explanation: content['explanation'] as String? ?? '',
            codeSnippet: content['codeSnippet'] as String? ?? '',
            revisionPoints: List<String>.from(content['revisionPoints'] as List? ?? []),
            quizQuestions: [], // Community topics don't have built-in questions
          ),
        );
      } catch (e) {
        print('Error converting community topic: $e');
      }
    }
    
    return topics;
  }

  /// Check if there are any community contributions for a category
  static Future<bool> hasCommunityContent(CourseCategory category) async {
    final contributions = await UserContentService.getContributionsByCategory(category);
    return contributions.isNotEmpty;
  }

  /// Get count of community contributions by type
  static Future<Map<ContentType, int>> getCommunityStats(CourseCategory category) async {
    final contributions = await UserContentService.getContributionsByCategory(category);
    
    final Map<ContentType, int> stats = {
      ContentType.topic: 0,
      ContentType.quiz: 0,
      ContentType.fillBlank: 0,
      ContentType.codeExample: 0,
    };
    
    for (final contribution in contributions) {
      stats[contribution.type] = (stats[contribution.type] ?? 0) + 1;
    }
    
    return stats;
  }
}
