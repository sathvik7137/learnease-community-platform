import 'package:flutter/material.dart';
import '../data/course_content.dart';
import '../models/course.dart';
import '../services/local_storage.dart';
import '../utils/app_theme.dart';
import '../widgets/theme_toggle_button.dart';
import 'course_detail_screen.dart';
import 'sign_in_screen.dart';
import '../services/auth_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  // Map to store course progress
  final Map<String, double> courseProgress = {};
  bool isLoading = true;
  String searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadCourseProgress();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will ensure progress is refreshed when returning to this screen
    _loadCourseProgress();
  }
  
  Future<void> _loadCourseProgress() async {
    // Set loading state
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    
    // Get progress for each course
    for (final course in courses) {
      final List<String> topicIds = course.topics.map((topic) => topic.id).toList();
      final progress = await LocalStorageService.getCourseProgress(topicIds);
      courseProgress[course.id] = progress;
    }
    
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        // Gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    colors.surface,
                    colors.surface.withOpacity(0.8),
                  ]
                : [
                    colors.primary.withOpacity(0.05),
                    colors.secondary.withOpacity(0.05),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search courses...',
                      prefixIcon: Icon(Icons.search, color: colors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? colors.surface : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(color: colors.onSurface),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Courses list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadCourseProgress();
                      return;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100), // Space for floating nav
                      itemCount: _filteredCourses().length,
                      itemBuilder: (context, index) {
                        final course = _filteredCourses()[index];
                        return _buildCourseCard(course, context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  List<Course> _filteredCourses() {
    if (searchQuery.isEmpty) {
      return courses;
    }
    return courses.where((course) {
      return course.name.toLowerCase().contains(searchQuery) ||
          course.description.toLowerCase().contains(searchQuery);
    }).toList();
  }

  Widget _buildCourseCard(Course course, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ScaleOnTap(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDark
                  ? [colors.surface, colors.surface.withOpacity(0.8)]
                  : [Colors.white, colors.primary.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
              child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                final token = await AuthService().getToken();
                if (token == null) {
                  // Ask user to sign in first
                  final res = await Navigator.push<bool?>(
                    context,
                    MaterialPageRoute(builder: (context) => SignInScreen()),
                  );
                  // If user signed in (or returned true), proceed to course
                  final newToken = await AuthService().getToken();
                  if (newToken == null) return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseDetailScreen(course: course),
                  ),
                ).then((_) => _loadCourseProgress()); // Refresh on return
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // Course icon with gradient background
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.primary,
                            colors.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          course.icon,
                          style: const TextStyle(
                            fontSize: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            course.description,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // Progress bar with percentage
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.primary.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: isLoading ? 0.0 : courseProgress[course.id] ?? 0.0,
                                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        course.id == 'java' ? Colors.orange.shade600 : Colors.blue.shade600,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: course.id == 'java' 
                                      ? Colors.orange.shade50 
                                      : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: course.id == 'java' 
                                        ? Colors.orange.shade200 
                                        : Colors.blue.shade200,
                                  ),
                                ),
                                child: Text(
                                  isLoading
                                      ? '...'
                                      : '${((courseProgress[course.id] ?? 0.0) * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: course.id == 'java' 
                                        ? Colors.orange.shade900 
                                        : Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: colors.primary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Scale animation widget for tap feedback
class ScaleOnTap extends StatefulWidget {
  final Widget child;

  const ScaleOnTap({super.key, required this.child});

  @override
  _ScaleOnTapState createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
