import 'package:flutter/material.dart';
import '../data/course_content.dart';
import '../services/local_storage.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../providers/theme_provider.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'admin_login_screen.dart';
import '../widgets/theme_toggle_widget.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
  
  // Auth state
  bool _isLoggedIn = false;
  String _userEmail = 'student@example.com';
  String _username = 'Student';
  
  // Animation controller for background
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkAuthStatus();
    
    // Setup background animation
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_backgroundController);
    _backgroundController.repeat(reverse: true);
  }

  Future<void> _checkAuthStatus() async {
    final token = await AuthService().getToken();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
      });
      
      // If logged in, fetch user profile
      if (_isLoggedIn) {
        await _fetchUserProfile();
      }
    }
  }
  
  Future<void> _fetchUserProfile() async {
    try {
      final profile = await AuthService().getUserProfile();
      if (profile.containsKey('error')) {
        print('Error fetching profile: ${profile['error']}');
        return;
      }
      
      if (mounted) {
        setState(() {
          _userEmail = profile['email'] ?? 'student@example.com';
          _username = profile['username'] ?? 'Student';
          if (_username.isEmpty) {
            _username = 'Student';
          }
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(isDark),
              const SizedBox(height: 28),
              _buildProgressSection(isDark),
              const SizedBox(height: 28),
              _buildSettingsSection(isDark),
              const SizedBox(height: 100), // Extra space for floating nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    final cardColor = isDark ? Colors.grey.shade700 : Colors.white;
    final borderColor = isDark ? Colors.grey.shade500 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);
    final subtextColor = isDark ? Colors.grey.shade300 : const Color(0xFF546E7A);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
            blurRadius: isDark ? 28 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar with gradient border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF5C6BC0),
                    Color(0xFF7E57C2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: cardColor,
                child: CircleAvatar(
                  radius: 47,
                  backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                  child: Icon(
                    Icons.person,
                    size: 54,
                    color: const Color(0xFF5C6BC0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Username
            Text(
              _username,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            
            // Email
            Text(
              _userEmail,
              style: TextStyle(
                fontSize: 14,
                color: subtextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            
            // Stats Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(isDark, topicsCompleted.toString(), 'Topics'),
                  Container(
                    height: 40,
                    width: 1,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  ),
                  _buildStatColumn(isDark, quizzesTaken.toString(), 'Quizzes'),
                  Container(
                    height: 40,
                    width: 1,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  ),
                  _buildStatColumn(isDark, '$averageScore%', 'Score'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(bool isDark, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5C6BC0),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(bool isDark) {
    final cardColor = isDark ? Colors.grey.shade700 : Colors.white;
    final borderColor = isDark ? Colors.grey.shade500 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
            blurRadius: isDark ? 28 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6BC0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Learning Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Progress items
            _buildProgressRow('Java Programming', javaProgress, Colors.orange, isDark),
            const SizedBox(height: 20),
            _buildProgressRow('Database Management', dbmsProgress, Colors.blue, isDark),
            const SizedBox(height: 20),
            _buildProgressRow('Quizzes Completed', quizCompletion, Colors.green, isDark),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressRow(String title, double progress, Color color, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF424242);
    final bgColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    
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
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: bgColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(bool isDark) {
    final cardColor = isDark ? Colors.grey.shade700 : Colors.white;
    final borderColor = isDark ? Colors.grey.shade500 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
            blurRadius: isDark ? 28 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6BC0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
              
              // Sign in / Signup / Logout buttons
              if (!_isLoggedIn)
                Column(
                  children: [
                    Text(
                      'Not logged in yet?',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SignInScreen(),
                                ),
                              );
                            },
                            icon: Icon(Icons.login),
                            label: Text('Sign In'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF5C6BC0),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SignUpScreen(),
                                ),
                              );
                            },
                            icon: Icon(Icons.person_add),
                            label: Text('Sign Up'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7E57C2),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminLoginScreen(
                                onLoginSuccess: () async {
                                  print('[ProfileScreen] 🔓 Admin login successful!');
                                  // Only trigger admin check; do not pop any routes here.
                                  if (mounted) {
                                    final mainNavState = MainNavigation.globalKey.currentState;
                                    if (mainNavState != null) {
                                      mainNavState.forceCheckAdminStatusImmediate();
                                    } else {
                                      print('[ProfileScreen] ⚠️ MainNavigation state is null');
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.admin_panel_settings),
                        label: Text('Admin Login'),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.green.shade900 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.green.shade700 : Colors.green.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: isDark ? Colors.green.shade400 : Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You are logged in',
                              style: TextStyle(
                                color: isDark ? Colors.green.shade300 : Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Edit Profile button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5C6BC0),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(
                                currentUsername: _username,
                                email: _userEmail,
                              ),
                            ),
                          );
                          // If profile was updated, refresh it
                          if (result == true) {
                            await _fetchUserProfile();
                          }
                        },
                        icon: Icon(Icons.edit),
                        label: Text('Edit Profile'),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Settings button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5C6BC0),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                userEmail: _userEmail,
                                username: _username,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.settings),
                        label: Text('Settings'),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final res = await AuthService().revokeToken();
                          if (res.containsKey('success') && res['success'] == true) {
                            if (mounted) {
                              setState(() {
                                _isLoggedIn = false;
                                _userEmail = 'student@example.com';
                                _username = 'Student';
                              });
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logged out successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            final err = res['error'] ?? 'Logout failed';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.logout),
                        label: Text('Logout'),
                      ),
                    ),
                  ],
                ),

              SizedBox(height: 16),
            ],
          ),
        ),
      );
  }

  Widget _buildRecentActivitySection(bool isDark) {
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;
    final textColor = isDark ? Colors.white : Color(0xFF1A237E);
    final dividerColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final gradientColors = isDark 
      ? [Colors.grey.shade900, Colors.grey.shade800]
      : [Colors.white, Colors.blue.shade50.withOpacity(0.3)];
    
    return FutureBuilder(
      future: _getRecentActivities(),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        List<Map<String, dynamic>> activities = snapshot.data ?? [
          {'title': 'No recent activities', 'time': '', 'icon': Icons.info, 'color': Colors.grey},
        ];
        
        return Card(
          elevation: 8,
          shadowColor: isDark ? Colors.black.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: gradientColors,
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
                      color: textColor,
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
                          activity['color'],
                          isDark
                        ),
                        if (entry.key < activities.length - 1) 
                          Divider(color: dividerColor),
                      ],
                    );
                  }),
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

  Widget _buildActivityItem(String title, String time, IconData icon, Color color, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    
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
                    color: textColor,
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtextColor,
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
