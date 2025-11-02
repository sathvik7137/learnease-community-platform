import 'package:flutter/material.dart';
import '../data/course_content.dart';
import '../models/course.dart';
import '../models/user_content.dart';
import '../services/local_storage.dart';
import '../services/community_integration_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../widgets/theme_toggle_button.dart';
import 'quiz_screen.dart';
import 'fill_blanks_screen.dart';
import 'community_contributions_screen.dart';
import 'sign_in_screen.dart';

class QuizTestScreen extends StatefulWidget {
  const QuizTestScreen({super.key});

  @override
  State<QuizTestScreen> createState() => _QuizTestScreenState();
}

class _QuizTestScreenState extends State<QuizTestScreen> {
  Map<String, int> quizScores = {};
  Map<String, int?> fillBlankScores = {};
  bool isLoading = true;
  Map<CourseCategory, Map<ContentType, int>> communityStats = {};
  final AuthService _authService = AuthService();

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

  // Check if user is logged in
  Future<bool> _isUserLoggedIn() async {
    final token = await _authService.getToken();
    return token != null && token.isNotEmpty;
  }

  // Handle quiz navigation with authentication check
  Future<void> _handleQuizPress(Topic topic) async {
    final isLoggedIn = await _isUserLoggedIn();
    
    if (!isLoggedIn) {
      _showLoginPromptDialog('quiz');
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(topic: topic),
        ),
      );
      _loadProgress();
    }
  }

  // Handle mock test navigation with authentication check
  Future<void> _handleMockTestPress(Course course) async {
    final isLoggedIn = await _isUserLoggedIn();
    
    if (!isLoggedIn) {
      _showLoginPromptDialog('mock test');
    } else {
      // Create a mock test with questions from all topics
      final allQuestions = <Question>[];
      for (final topic in course.topics) {
        allQuestions.addAll(topic.quizQuestions);
      }
      
      // Limit to 15 questions and shuffle them
      allQuestions.shuffle();
      final mockTestQuestions = allQuestions.take(15).toList();
      
      if (mockTestQuestions.isNotEmpty) {
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
      }
    }
  }

  // Handle fill blanks navigation with authentication check
  Future<void> _handleFillBlanksPress(Course course) async {
    final isLoggedIn = await _isUserLoggedIn();
    
    if (!isLoggedIn) {
      _showLoginPromptDialog('fill-in-the-blanks exercises');
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FillBlanksScreen(course: course),
        ),
      );
      _loadProgress();
    }
  }

  // Show dialog prompting user to login
  void _showLoginPromptDialog(String activityType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.blue, size: 28),
              SizedBox(width: 8),
              Text('Login Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please login to access $activityType and track your progress.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Save your scores', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Track your progress', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Unlock achievements', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignInScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Sign In'),
            ),
          ],
        );
      },
    );
  }

  bool _isQuizCompleted(String topicId) {
    return (quizScores[topicId] ?? 0) > 0;
  }

  bool _isFillBlankCompleted(String topicTitle) {
    return (fillBlankScores[topicTitle] ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz & Tests'),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          actions: const [
            ThemeToggleButton(
              size: 24,
              padding: EdgeInsets.only(right: 16),
            ),
          ],
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
                  _buildQuizzesTab(context),
                  _buildMockTestsTab(context),
                  _buildFillBlanksTab(context),
                ],
              ),
      ),
    );
  }

  Widget _buildQuizzesTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

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
          _buildCommunityBanner(ContentType.quiz, context),
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
                          color: isCompleted ? Colors.green : (isDark ? Colors.grey[700] : Colors.grey[300]),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.grey[700],
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
                          color: isCompleted ? Colors.green[700] : (isDark ? Colors.white : Colors.black87),
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
                      onTap: () => _handleQuizPress(topic),
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

  Widget _buildCommunityBanner(ContentType type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

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
      color: colors.primary.withOpacity(0.1),
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
            border: Border.all(color: colors.primary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.people, color: colors.primary, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌐 Community $typeLabel Available!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCount community-contributed $typeLabel (Java: $javaCount, DBMS: $dbmsCount)',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: colors.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockTestsTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

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
                    onTap: () => _handleMockTestPress(course),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFillBlanksTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

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
          _buildCommunityBanner(ContentType.fillBlank, context),
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
                        color: completedCount > 0 ? Colors.green.withOpacity(0.1) : (isDark ? Colors.grey[800] : Colors.grey[100]),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: completedCount > 0 ? Colors.green : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: completedCount > 0
                            ? Icon(Icons.check_circle, color: Colors.green, size: 30)
                            : Icon(Icons.edit_note, color: isDark ? Colors.grey[600] : Colors.grey[400], size: 30),
                      ),
                    ),
                    title: Text(
                      course.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: completedCount > 0 ? Colors.green[700] : (isDark ? Colors.white : Colors.black87),
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
                    onTap: () => _handleFillBlanksPress(course),
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
