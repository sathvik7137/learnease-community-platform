import 'package:flutter/material.dart';
import '../data/course_content.dart';
import '../models/course.dart';
import '../models/user_content.dart';
import '../services/local_storage.dart';
import '../services/community_integration_service.dart';
import 'quiz_screen.dart';
import 'fill_blanks_screen.dart';
import 'community_contributions_screen.dart';

class QuizTestScreen extends StatefulWidget {
  @override
  State<QuizTestScreen> createState() => _QuizTestScreenState();
}

class _QuizTestScreenState extends State<QuizTestScreen> {
  Map<String, int> quizScores = {};
  Map<String, int?> fillBlankScores = {};
  bool isLoading = true;
  Map<CourseCategory, Map<ContentType, int>> communityStats = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => isLoading = true);

    // Load quiz scores for all topics
    for (final course in courses) {
      for (final topic in course.topics) {
        final score = await LocalStorageService.getTopicProgress(topic.id);
        quizScores[topic.id] = score;

        // Load fill-blank scores
        final fillScore = await LocalStorageService.getExerciseScore(topic.title, 'fill-blanks');
        fillBlankScores[topic.title] = fillScore;
      }
    }

    // Load community stats
    communityStats[CourseCategory.java] = 
        await CommunityIntegrationService.getCommunityStats(CourseCategory.java);
    communityStats[CourseCategory.dbms] = 
        await CommunityIntegrationService.getCommunityStats(CourseCategory.dbms);

    setState(() => isLoading = false);
  }

  bool _isQuizCompleted(String topicId) {
    return (quizScores[topicId] ?? 0) > 0;
  }

  bool _isFillBlankCompleted(String topicTitle) {
    return (fillBlankScores[topicTitle] ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz & Tests'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Quizzes'),
              Tab(text: 'Mock Tests'),
              Tab(text: 'Fill Blanks'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildQuizzesTab(),
                  _buildMockTestsTab(),
                  _buildFillBlanksTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildQuizzesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a quiz to test your knowledge',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Community quizzes banner
          _buildCommunityBanner(ContentType.quiz),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, courseIndex) {
                final course = courses[courseIndex];
                return ExpansionTile(
                  title: Text(course.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: course.topics.asMap().entries.map((entry) {
                    final index = entry.key;
                    final topic = entry.value;
                    final isCompleted = _isQuizCompleted(topic.id);
                    final score = quizScores[topic.id] ?? 0;

                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                      title: Text(
                        topic.title.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                        style: TextStyle(
                          fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                          color: isCompleted ? Colors.green[700] : Colors.black87,
                        ),
                      ),
                      subtitle: isCompleted
                          ? Text(
                              'Completed • Score: $score%',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 12,
                              ),
                            )
                          : null,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizScreen(topic: topic),
                          ),
                        );
                        // Reload progress when returning
                        _loadProgress();
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityBanner(ContentType type) {
    final javaCount = communityStats[CourseCategory.java]?[type] ?? 0;
    final dbmsCount = communityStats[CourseCategory.dbms]?[type] ?? 0;
    final totalCount = javaCount + dbmsCount;

    if (totalCount == 0) {
      return const SizedBox.shrink();
    }

    String typeLabel;
    switch (type) {
      case ContentType.quiz:
        typeLabel = 'Quizzes';
        break;
      case ContentType.fillBlank:
        typeLabel = 'Fill-in-the-Blanks';
        break;
      default:
        typeLabel = 'Items';
    }

    return Material(
      color: Colors.blue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CommunityContributionsScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.people, color: Colors.blue, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌐 Community $typeLabel Available!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCount community-contributed $typeLabel (Java: $javaCount, DBMS: $dbmsCount)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockTestsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Take a mock test to assess your overall knowledge',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text(course.name),
                    subtitle: const Text('15-20 questions from all topics'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Create a mock test with questions from all topics
                      final allQuestions = <Question>[];
                      for (final topic in course.topics) {
                        allQuestions.addAll(topic.quizQuestions);
                      }
                      
                      // Limit to 15 questions and shuffle them
                      allQuestions.shuffle();
                      final mockTestQuestions = allQuestions.take(15).toList();
                      
                      // Create a temporary topic to hold the mock test questions
                      final mockTestTopic = Topic(
                        id: 'mock_test_${course.id}',
                        title: '${course.name} Mock Test',
                        explanation: '',
                        codeSnippet: '',
                        revisionPoints: [],
                        quizQuestions: mockTestQuestions,
                      );
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizScreen(
                            topic: mockTestTopic,
                            isMockTest: true,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFillBlanksTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Practice fill in the blanks exercises',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Community fill blanks banner
          _buildCommunityBanner(ContentType.fillBlank),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, courseIndex) {
                final course = courses[courseIndex];
                
                // Calculate completion for this course
                int completedCount = 0;
                int totalCount = course.topics.length;
                
                for (final topic in course.topics) {
                  if (_isFillBlankCompleted(topic.title)) {
                    completedCount++;
                  }
                }
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: completedCount > 0 ? Colors.green.withOpacity(0.1) : Colors.grey[100],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: completedCount > 0 ? Colors.green : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: completedCount > 0
                            ? Icon(Icons.check_circle, color: Colors.green, size: 30)
                            : Icon(Icons.edit_note, color: Colors.grey[400], size: 30),
                      ),
                    ),
                    title: Text(
                      course.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: completedCount > 0 ? Colors.green[700] : Colors.black87,
                      ),
                    ),
                    subtitle: completedCount > 0
                        ? Text(
                            '$completedCount/$totalCount topics completed',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : const Text('Fill in the blanks exercises'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FillBlanksScreen(course: course),
                        ),
                      );
                      // Reload progress when returning
                      _loadProgress();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
