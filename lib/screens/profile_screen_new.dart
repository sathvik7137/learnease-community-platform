import 'package:flutter/material.dart';
import '../data/course_content.dart';
import '../services/local_storage.dart';
import '../services/user_content_service.dart';
import '../services/auth_service.dart';
import '../widgets/theme_toggle_widget.dart';
import 'admin_login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Progress tracking
  double javaProgress = 0.0;
  double dbmsProgress = 0.0;
  double quizCompletion = 0.0;
  
  // Stats tracking
  int topicsCompleted = 0;
  int quizzesTaken = 0;
  int averageScore = 0;
  
  // User info
  String username = 'Student';
  String email = 'student@example.com';
  bool isLoading = true;
  
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });
    
    // Load username from UserContentService
    final loadedUsername = await UserContentService.getUsername();
    if (loadedUsername != null && loadedUsername.isNotEmpty) {
      username = loadedUsername;
    }
    
    // Try to get email from auth service (this might not be available depending on your auth implementation)
    // For now, we'll use a default or you can extend this based on your auth system
    
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
    
    for (final course in courses) {
      for (final topic in course.topics) {
        totalQuizzes++;
        final score = await LocalStorageService.getTopicProgress(topic.id);
        if (score > 0) {
          completedQuizzes++;
          totalScore += score;
          topicsCompleted++;
        }
      }
    }
    
    // Update state
    if (mounted) {
      setState(() {
        javaProgress = javaProgressValue;
        dbmsProgress = dbmsProgressValue;
        quizCompletion = totalQuizzes > 0 ? completedQuizzes / totalQuizzes : 0.0;
        quizzesTaken = completedQuizzes;
        averageScore = completedQuizzes > 0 ? (totalScore / completedQuizzes).round() : 0;
        isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Progress'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: const [ThemeToggleWidget()],
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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
            _buildRecentActivitySection(),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.indigo.shade100,
            child: Icon(Icons.person, size: 70, color: Colors.indigo),
          ),
          SizedBox(height: 16),
          Text(
            username,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            email,
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: Icon(Icons.edit),
                label: Text('Edit Profile'),
                onPressed: () {},
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                icon: Icon(Icons.admin_panel_settings),
                label: Text('Admin Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminLoginScreen(
                        onLoginSuccess: _handleAdminLoginSuccess,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAdminLoginSuccess() {
  // No-op here; MainNavigation listens for role change.
  }

  Widget _buildProgressSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildProgressItem('Java Programming', javaProgress, '${(javaProgress * 100).round()}%', Colors.orange),
            SizedBox(height: 12),
            _buildProgressItem('Database Management', dbmsProgress, '${(dbmsProgress * 100).round()}%', Colors.blue),
            SizedBox(height: 12),
            _buildProgressItem('Quizzes Completed', quizCompletion, '${(quizCompletion * 100).round()}%', Colors.green),
          ],
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
            Text(title),
            Text(percentage, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(topicsCompleted.toString(), 'Topics Completed'),
                _buildStatItem(quizzesTaken.toString(), 'Quizzes Taken'),
                _buildStatItem('$averageScore%', 'Avg. Score'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
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
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      if (entry.key < activities.length - 1) Divider(),
                    ],
                  );
                }),
              ],
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (time.isNotEmpty)
                  Text(time, style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
