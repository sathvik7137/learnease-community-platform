import 'package:flutter/material.dart';
import '../models/user_content.dart';
import '../services/user_content_service.dart';
import '../services/auth_service.dart';
import 'add_content_screen.dart';
import 'community_contributions_screen.dart';
import 'sign_in_screen.dart';
import '../widgets/theme_toggle_widget.dart';

class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen> {
  List<UserContent> _myContributions = [];
  bool _isLoading = true;
  String? _username;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadMyContributions();
  }

  Future<void> _loadMyContributions() async {
    setState(() {
      _isLoading = true;
    });

    _username = await UserContentService.getUsername();
    
    if (_username != null) {
      final allContributions = await UserContentService.getAllContributions();
      final myContributions = allContributions
          .where((c) => c.authorName == _username)
          .toList();
      
      // Sort by newest first
      myContributions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _myContributions = myContributions;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteContent(UserContent content) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: const Text('Are you sure you want to delete this content?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await UserContentService.deleteContribution(content.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content deleted successfully')),
          );
          _loadMyContributions();
        }
      }
    }
  }

  Future<void> _editContent(UserContent content) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddContentScreen(existingContent: content),
      ),
    );

    if (result == true) {
      _loadMyContributions();
    }
  }

  void _viewContent(UserContent content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(content: content),
      ),
    );
  }

  // Check if user is logged in
  Future<bool> _isUserLoggedIn() async {
    final token = await _authService.getToken();
    return token != null && token.isNotEmpty;
  }

  // Handle Add Content with authentication check
  Future<void> _handleAddContentPress() async {
    final isLoggedIn = await _isUserLoggedIn();
    
    if (!isLoggedIn) {
      // Show login prompt dialog
      _showLoginPromptDialog();
    } else {
      // User is logged in, proceed to Add Content
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const AddContentScreen(),
        ),
      );
      if (result == true) {
        _loadMyContributions();
      }
    }
  }

  // Show dialog prompting user to login
  void _showLoginPromptDialog() {
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
                'Please login to contribute content and track your contributions.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Share your knowledge', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Track your contributions', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Build your reputation', style: TextStyle(fontSize: 14)),
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
                // Navigate to sign-in screen
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contributions'),
        actions: [
          if (_username != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _username!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          const ThemeToggleWidget(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _username == null
              ? _buildNoUsernameState()
              : _myContributions.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadMyContributions,
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          // Stats card
                          _buildStatsCard(),
                          const SizedBox(height: 16),
                          
                          // Contributions list
                          ..._myContributions.map((content) => _buildContentCard(content)),
                        ],
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddContentPress,
        icon: const Icon(Icons.add),
        label: const Text('Add Content'),
      ),
    );
  }

  Widget _buildNoUsernameState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Username Not Set',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please set up your username first',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Contributions Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your knowledge with the community!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleAddContentPress,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Content'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final topicCount = _myContributions.where((c) => c.type == ContentType.topic).length;
    final quizCount = _myContributions.where((c) => c.type == ContentType.quiz).length;
    final fillBlankCount = _myContributions.where((c) => c.type == ContentType.fillBlank).length;
    final codeCount = _myContributions.where((c) => c.type == ContentType.codeExample).length;
    
    final javaCount = _myContributions.where((c) => c.category == CourseCategory.java).length;
    final dbmsCount = _myContributions.where((c) => c.category == CourseCategory.dbms).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Your Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_myContributions.length}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text('Total'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$topicCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Topics', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$quizCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Quizzes', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$fillBlankCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Fill Blanks', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$codeCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Code', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    const Icon(Icons.code, color: Colors.blue, size: 20),
                    const SizedBox(width: 4),
                    Text('Java: $javaCount'),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.storage, color: Colors.green, size: 20),
                    const SizedBox(width: 4),
                    Text('DBMS: $dbmsCount'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(UserContent content) {
    final title = _getContentTitle(content);
    final subtitle = _getContentSubtitle(content);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _viewContent(content),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getTypeIcon(content.type),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 8),
                            Text('View'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _viewContent(content);
                          break;
                        case 'edit':
                          _editContent(content);
                          break;
                        case 'delete':
                          _deleteContent(content);
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: content.category == CourseCategory.java
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: content.category == CourseCategory.java
                            ? Colors.blue
                            : Colors.green,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          content.category == CourseCategory.java
                              ? Icons.code
                              : Icons.storage,
                          size: 14,
                          color: content.category == CourseCategory.java
                              ? Colors.blue
                              : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          content.category == CourseCategory.java ? 'Java' : 'DBMS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: content.category == CourseCategory.java
                                ? Colors.blue
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(content.createdAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Icon _getTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.topic:
        return const Icon(Icons.article, color: Colors.blue);
      case ContentType.quiz:
        return const Icon(Icons.quiz, color: Colors.green);
      case ContentType.fillBlank:
        return const Icon(Icons.edit_note, color: Colors.orange);
      case ContentType.codeExample:
        return const Icon(Icons.code, color: Colors.purple);
    }
  }

  String _getContentTitle(UserContent content) {
    switch (content.type) {
      case ContentType.topic:
        return content.content['title'] as String? ?? 'Untitled Topic';
      case ContentType.quiz:
        return content.content['topicTitle'] as String? ?? 'Quiz';
      case ContentType.fillBlank:
        return content.content['topicTitle'] as String? ?? 'Fill in the Blanks';
      case ContentType.codeExample:
        return content.content['title'] as String? ?? 'Code Example';
    }
  }

  String _getContentSubtitle(UserContent content) {
    switch (content.type) {
      case ContentType.topic:
        return 'Learning Topic';
      case ContentType.quiz:
        final questions = content.content['questions'] as List?;
        return '${questions?.length ?? 0} questions';
      case ContentType.fillBlank:
        final questions = content.content['questions'] as List?;
        return '${questions?.length ?? 0} questions';
      case ContentType.codeExample:
        return content.content['language'] as String? ?? 'Code';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
