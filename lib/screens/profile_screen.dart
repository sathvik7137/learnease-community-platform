import 'package:flutter/material.dart';
import '../data/course_content.dart';
import '../services/local_storage.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  // Progress tracking
  double javaProgress = 0.0;
  double dbmsProgress = 0.0;
  double quizCompletion = 0.0;
  
  // Stats tracking
  int topicsCompleted = 0;
  int quizzesTaken = 0;
  int averageScore = 0;
  int learningStreak = 0;
  
  // Animation controller for background
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Setup background animation
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_backgroundController);
    _backgroundController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    // Calculate Java progress
    final javaTopicIds = javaTopics.map((topic) => topic.id).toList();
    final javaProgressValue = await LocalStorageService.getCourseProgress(javaTopicIds);
    
    // Calculate DBMS progress
    final dbmsTopicIds = dbmsTopics.map((topic) => topic.id).toList();
    final dbmsProgressValue = await LocalStorageService.getCourseProgress(dbmsTopicIds);
    
    // Calculate quiz completion and performance
    int totalQuizzes = 0;
    int completedQuizzes = 0;
    int totalScore = 0;
    int completedTopics = 0;
    
    for (final course in courses) {
      for (final topic in course.topics) {
        totalQuizzes++;
        final score = await LocalStorageService.getTopicProgress(topic.id);
        if (score > 0) {
          completedQuizzes++;
          totalScore += score;
          completedTopics++;
        }
      }
    }
    
    // Calculate learning streak (simulated based on completed topics)
    int streak = (completedTopics / 3).floor();
    if (streak < 1 && completedTopics > 0) streak = 1;
    
    // Update state
    if (mounted) {
      setState(() {
        javaProgress = javaProgressValue;
        dbmsProgress = dbmsProgressValue;
        quizCompletion = totalQuizzes > 0 ? completedQuizzes / totalQuizzes : 0.0;
        quizzesTaken = completedQuizzes;
        averageScore = completedQuizzes > 0 ? (totalScore / completedQuizzes).round() : 0;
        topicsCompleted = completedTopics;
        learningStreak = streak;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.indigo.withOpacity(0.5),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Profile & Progress',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade50,
                  Colors.blue.shade50.withOpacity(0.3 + _backgroundAnimation.value * 0.3),
                  Colors.purple.shade50.withOpacity(0.3 + _backgroundAnimation.value * 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5 + _backgroundAnimation.value * 0.2, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildProgressSection(),
              const SizedBox(height: 24),
              _buildStatsSection(),
              SizedBox(height: 24),
              _buildSettingsSection(),
              SizedBox(height: 24),
              _buildRecentActivitySection(),
              SizedBox(height: 100), // Extra space for floating nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          // Profile picture with glowing border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  Color(0xFF5C6BC0),
                  Color(0xFF7E57C2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.all(5),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.indigo.shade100,
                child: Icon(Icons.person, size: 70, color: Colors.indigo),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Student',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          Text(
            'student@example.com',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          
          // Learning streak badge
          if (learningStreak > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '$learningStreak Day Streak!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(height: 12),
          
          // Total quiz score badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 18),
                SizedBox(width: 6),
                Text(
                  'Average Score: $averageScore%',
                  style: TextStyle(
                    color: Colors.indigo.shade900,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Card(
      elevation: 8,
      shadowColor: Colors.indigo.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.indigo.shade50.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              SizedBox(height: 20),
              _buildProgressItem('Java Programming', javaProgress, '${(javaProgress * 100).round()}%', Colors.orange),
              SizedBox(height: 16),
              _buildProgressItem('Database Management', dbmsProgress, '${(dbmsProgress * 100).round()}%', Colors.blue),
              SizedBox(height: 16),
              _buildProgressItem('Quizzes Completed', quizCompletion, '${(quizCompletion * 100).round()}%', Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem(String title, double progress, String percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Card(
      elevation: 8,
      shadowColor: Colors.purple.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.purple.shade50.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Stats',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(topicsCompleted.toString(), 'Topics Completed', Icons.topic, Colors.blue),
                  _buildStatItem(quizzesTaken.toString(), 'Quizzes Taken', Icons.quiz, Colors.purple),
                  _buildStatItem('$averageScore%', 'Avg. Score', Icons.stars, Colors.amber),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 8,
      shadowColor: Colors.amber.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.amber.shade50.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              SizedBox(height: 16),
              
              // Settings coming soon message
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.indigo),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'More settings coming soon!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return FutureBuilder(
      future: _getRecentActivities(),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        List<Map<String, dynamic>> activities = snapshot.data ?? [
          {'title': 'No recent activities', 'time': '', 'icon': Icons.info, 'color': Colors.grey},
        ];
        
        return Card(
          elevation: 8,
          shadowColor: Colors.blue.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  SizedBox(height: 16),
                  ...activities.asMap().entries.map((entry) {
                    final activity = entry.value;
                    return Column(
                      children: [
                        _buildActivityItem(
                          activity['title'], 
                          activity['time'], 
                          activity['icon'], 
                          activity['color']
                        ),
                        if (entry.key < activities.length - 1) 
                          Divider(color: Colors.grey.shade300),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Future<List<Map<String, dynamic>>> _getRecentActivities() async {
    List<Map<String, dynamic>> activities = [];
    
    // Get topic completion status for all topics
    for (final course in courses) {
      for (final topic in course.topics) {
        final score = await LocalStorageService.getTopicProgress(topic.id);
        if (score > 0) {
          activities.add({
            'title': 'Completed ${topic.title}',
            'time': _getRandomRecentTime(),
            'icon': Icons.check_circle,
            'color': Colors.green,
            'timestamp': DateTime.now().subtract(Duration(days: activities.length + 1)),
          });
        }
      }
    }
    
    // Get fill-in-the-blanks exercise completion
    for (final course in courses) {
      for (final topic in course.topics) {
        final score = await LocalStorageService.getExerciseScore(topic.title, 'fill-blanks');
        if (score != null) {
          activities.add({
            'title': 'Completed ${topic.title} Fill-in-the-Blanks',
            'time': _getRandomRecentTime(),
            'icon': Icons.edit,
            'color': Colors.purple,
            'timestamp': DateTime.now().subtract(Duration(days: activities.length)),
          });
        }
      }
    }
    
    // Sort activities by timestamp (most recent first)
    activities.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    
    // Take only the 5 most recent activities
    final recentActivities = activities.take(5).map((activity) {
      activity.remove('timestamp');  // Remove the timestamp field before returning
      return activity;
    }).toList();
    
    // If no activities yet, add a placeholder
    if (recentActivities.isEmpty) {
      recentActivities.add({
        'title': 'No recent activities',
        'time': '',
        'icon': Icons.info,
        'color': Colors.grey,
      });
    }
    
    return recentActivities;
  }
  
  String _getRandomRecentTime() {
    final options = [
      'Today',
      'Yesterday',
      '2 days ago',
      '3 days ago',
      'Last week',
    ];
    return options[DateTime.now().millisecondsSinceEpoch % options.length];
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
