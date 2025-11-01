import 'package:flutter/material.dart';
import '../models/fill_blank.dart';
import '../models/course.dart';
import '../data/fill_blanks_data.dart';
import '../data/course_content.dart';
import '../services/local_storage.dart';
import 'fill_blank_exercise_screen.dart';
import '../widgets/theme_toggle_widget.dart';

class FillBlanksScreen extends StatefulWidget {
  final Course course;
  
  const FillBlanksScreen({super.key, required this.course});
  
  @override
  _FillBlanksScreenState createState() => _FillBlanksScreenState();
}

class _FillBlanksScreenState extends State<FillBlanksScreen> {
  Map<String, int?> topicScores = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => isLoading = true);
    
    // Determine which topics to load
    List<Topic> courseTopics = [];
    if (widget.course.id == 'java') {
      courseTopics = javaTopics;
    } else if (widget.course.id == 'dbms') {
      courseTopics = dbmsTopics;
    }
    
    // Load fill-blank scores for all topics
    for (final topic in courseTopics) {
      final score = await LocalStorageService.getExerciseScore(topic.title, 'fill-blanks');
      topicScores[topic.title] = score;
    }
    
    setState(() => isLoading = false);
  }

  bool _isTopicCompleted(String topicTitle) {
    return (topicScores[topicTitle] ?? 0) > 0;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine which questions to show based on the course
    List<FillBlankQuestion> courseQuestions = [];
    List<Topic> courseTopics = [];
    
    if (widget.course.id == 'java') {
      courseQuestions = javaFillBlankQuestions;
      courseTopics = javaTopics;
    } else if (widget.course.id == 'dbms') {
      courseQuestions = dbmsFillBlankQuestions;
      courseTopics = dbmsTopics;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.course.name} - Fill in the Blanks'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: const [ThemeToggleWidget()],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildTopicsList(courseTopics, courseQuestions),
            ),
    );
  }

  Widget _buildTopicsList(List<Topic> topics, List<FillBlankQuestion> questions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        
        // Filter questions for this topic
        final topicQuestions = questions.where((q) => q.topicId == topic.id).toList();
        
        // Only show topics that have fill-in-the-blanks questions
        if (topicQuestions.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final isCompleted = _isTopicCompleted(topic.title);
        final score = topicScores[topic.title] ?? 0;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            title: Text(
              // Remove leading numbers like "1. ", "2. ", "23. " from title
              topic.title.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
              style: TextStyle(
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                color: isCompleted ? Colors.green[700] : Colors.black87,
              ),
            ),
            subtitle: isCompleted
                ? Text(
                    'Completed • Score: $score% • ${topicQuestions.length} questions',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                    ),
                  )
                : Text('${topicQuestions.length} fill-in-the-blank questions'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FillBlankExerciseScreen(
                    topicName: topic.title,
                    questions: topicQuestions,
                  ),
                ),
              );
              // Reload progress when returning from exercise
              _loadProgress();
            },
          ),
        );
      },
    );
  }
}
