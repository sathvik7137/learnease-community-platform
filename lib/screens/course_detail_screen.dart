import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/local_storage.dart';
import 'topic_detail_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with TickerProviderStateMixin {
  Map<String, int> topicScores = {};
  bool isLoading = true;
  late AnimationController _animationController;
  final List<Animation<double>> _itemAnimations = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadProgress();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    setState(() => isLoading = true);
    
    // Load progress for all topics
    for (final topic in widget.course.topics) {
      final score = await LocalStorageService.getTopicProgress(topic.id);
      topicScores[topic.id] = score;
    }
    
    // Setup staggered animations for each card
    _itemAnimations.clear();
    for (int i = 0; i < widget.course.topics.length; i++) {
      final start = i * 0.1;
      final end = start + 0.4;
      _itemAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOut),
          ),
        ),
      );
    }
    
    setState(() => isLoading = false);
    _animationController.forward();
  }

  bool _isTopicCompleted(String topicId) {
    return (topicScores[topicId] ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context) {
    // Consistent theme colors
    const primaryColor = Color(0xFF5C6BC0); // LearnEase indigo
    const accentColor = Color(0xFF7E57C2); // Purple accent
    
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.5),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.course.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        // Subtle gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.indigo.shade50,
              Colors.blue.shade50.withOpacity(0.3),
              Colors.purple.shade50.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: widget.course.topics.length,
                itemBuilder: (context, index) {
                  final topic = widget.course.topics[index];
                  final isCompleted = _isTopicCompleted(topic.id);
                  final score = topicScores[topic.id] ?? 0;
                  
                  // Get animation for this item
                  final animation = index < _itemAnimations.length
                      ? _itemAnimations[index]
                      : AlwaysStoppedAnimation(1.0);

                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - animation.value)),
                        child: Opacity(
                          opacity: animation.value,
                          child: child,
                        ),
                      );
                    },
                    child: _buildModuleCard(
                      context,
                      topic,
                      index,
                      isCompleted,
                      score,
                      primaryColor,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    dynamic topic,
    int index,
    bool isCompleted,
    int score,
    Color primaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 6,
        shadowColor: primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TopicDetailScreen(topic: topic),
              ),
            );
            // Reload progress when returning from topic detail
            _loadProgress();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  isCompleted
                      ? Colors.green.shade50.withOpacity(0.5)
                      : Colors.indigo.shade50.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isCompleted
                    ? Colors.green.withOpacity(0.3)
                    : Colors.indigo.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Number/Check badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [primaryColor.withOpacity(0.8), const Color(0xFF7E57C2).withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isCompleted ? Colors.green : primaryColor).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check_circle, color: Colors.white, size: 28)
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Topic info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // Remove leading numbers like "1. ", "2. ", "23. " from title
                          topic.title.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isCompleted ? Colors.green.shade800 : const Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stars, size: 14, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Score: $score%',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            'Tap to start learning',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Arrow icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
