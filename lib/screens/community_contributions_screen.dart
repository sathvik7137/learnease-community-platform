import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/user_content.dart';
import '../services/user_content_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../widgets/theme_toggle_button.dart';
import 'add_content_screen.dart';
import 'my_contributions_screen.dart';
import 'sign_in_screen.dart';
import 'dart:async';

class CommunityContributionsScreen extends StatefulWidget {
  const CommunityContributionsScreen({super.key});

  @override
  State<CommunityContributionsScreen> createState() => _CommunityContributionsScreenState();
}

class _CommunityContributionsScreenState extends State<CommunityContributionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<UserContent> _contributions = [];
  ContentType? _filterType;
  StreamSubscription<List<UserContent>>? _realtimeSubscription;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_loadContributions);
    _loadContributions();
    
    // Start real-time updates
    UserContentService.startRealtimeUpdates();
    
    // Listen to real-time updates
    _realtimeSubscription = UserContentService.contributionsStream.listen((allContributions) {
      if (mounted) {
        _updateContributionsFromStream(allContributions);
      }
    });
  }
  
  void _updateContributionsFromStream(List<UserContent> allContributions) {
    final category = _tabController.index == 0 ? CourseCategory.java : CourseCategory.dbms;
    final filtered = allContributions.where((c) {
      final matchCategory = c.category == category;
      final matchType = _filterType == null || c.type == _filterType;
      return matchCategory && matchType;
    }).toList();
    
    if (mounted) {
      setState(() {
        _contributions = filtered;
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _realtimeSubscription?.cancel();
    UserContentService.stopRealtimeUpdates();
    super.dispose();
  }

  Future<void> _loadContributions() async {
    setState(() => _isLoading = true);
    final category = _tabController.index == 0 ? CourseCategory.java : CourseCategory.dbms;
    final contributions = await UserContentService.getContributions(category: category, type: _filterType);
    setState(() {
      _contributions = contributions;
      _isLoading = false;
    });
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
        _loadContributions();
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
              Icon(Icons.lock_outline, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Login Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please login to contribute content to the community.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Share your knowledge', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Help others learn', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
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
                backgroundColor: Colors.green,
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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF5C6BC0),
                const Color(0xFF7E57C2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5C6BC0).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: FutureBuilder<String?>(
              future: UserContentService.getUsername(),
              builder: (context, snapshot) {
                final username = snapshot.data;
                final categoryName = _tabController.index == 0 ? 'Java' : 'DBMS';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Community Contributions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      categoryName,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    if (username != null)
                      Text(
                        'Logged in as: $username',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                          color: Colors.white60,
                        ),
                      ),
                  ],
                );
              },
            ),
            actions: [
              // Theme toggle
              const ThemeToggleButton(
                size: 24,
                padding: EdgeInsets.only(right: 8),
              ),
              // Add Content Button - prominently displayed in app bar
              ElevatedButton.icon(
                onPressed: _handleAddContentPress,
                icon: const Icon(Icons.add),
                label: const Text('Add Content'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 4,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'My Contributions',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyContributionsScreen(),
                    ),
                  );
                  _loadContributions();
                },
              ),
              PopupMenuButton<ContentType?>(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter by type',
                onSelected: (type) {
                  setState(() {
                    _filterType = type;
                  });
                  _loadContributions();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: null, child: Text('All Types')),
                  ...ContentType.values.map((type) => PopupMenuItem(
                    value: type,
                    child: Text(_getTypeLabel(type)),
                  )),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.code), text: 'Java'),
                  Tab(icon: Icon(Icons.storage), text: 'DBMS'),
                ],
                indicatorColor: Colors.white,
                labelColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contributions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadContributions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _contributions.length,
                    itemBuilder: (context, index) {
                      final content = _contributions[index];
                      return FutureBuilder<Map<String, String?>>(
                        future: _getCurrentUserInfo(),
                        builder: (context, snapshot) {
                          final userInfo = snapshot.data ?? {'username': null, 'email': null};
                          return _buildContentCard(content, userInfo['username'], userInfo['email']);
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    final categoryName = _tabController.index == 0 ? 'Java' : 'DBMS';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              _filterType == null
                  ? 'No $categoryName Contributions Yet'
                  : 'No $categoryName ${_getTypeLabel(_filterType!)} Contributions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to add $categoryName content!',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleAddContentPress,
              icon: Icon(Icons.add),
              label: Text('Add Content'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get current user's info (username and email)
  Future<Map<String, String?>> _getCurrentUserInfo() async {
    final username = await UserContentService.getUsername();
    final email = await _authService.getUserEmail();
    return {'username': username, 'email': email};
  }

  Widget _buildContentCard(UserContent content, String? currentUsername, String? currentEmail) {
    final title = _getContentTitle(content);
    final subtitle = _getContentSubtitle(content);
    
    // Check ownership by comparing username OR email prefix (from old registration)
    final isOwner = currentUsername != null && 
                    (currentUsername.trim().toLowerCase() == content.authorName.trim().toLowerCase() ||
                     currentEmail != null && currentEmail.split('@')[0].toLowerCase() == content.authorName.trim().toLowerCase());
    
    // Debug: print ownership check
    print('Current user: "$currentUsername" (email: "$currentEmail"), Content author: "${content.authorName}", Is owner: $isOwner');
    
    return Card(
      margin: EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _viewContent(content),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getTypeIcon(content.type),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    itemBuilder: (context) {
                      final items = <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 20),
                              SizedBox(width: 8),
                              Text('View'),
                            ],
                          ),
                        ),
                      ];
                      if (isOwner) {
                        items.addAll([
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ]);
                      }
                      return items;
                    },
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
              SizedBox(height: 12),
              Row(
                children: [
                  // Category badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: content.category == CourseCategory.java ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: content.category == CourseCategory.java ? Colors.blue : Colors.green),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(content.category == CourseCategory.java ? Icons.code : Icons.storage, size: 14, color: content.category == CourseCategory.java ? Colors.blue : Colors.green),
                        SizedBox(width: 4),
                        Text(content.category == CourseCategory.java ? 'Java' : 'DBMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: content.category == CourseCategory.java ? Colors.blue : Colors.green)),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.person, size: 16, color: Colors.blue),
                  SizedBox(width: 4),
                  Text('By ${content.authorName}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blue)),
                  SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16),
                  SizedBox(width: 4),
                  Text(_formatDate(content.createdAt), style: TextStyle(fontSize: 12)),
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
        return Icon(Icons.article, color: Colors.blue);
      case ContentType.quiz:
        return Icon(Icons.quiz, color: Colors.green);
      case ContentType.fillBlank:
        return Icon(Icons.edit_note, color: Colors.orange);
      case ContentType.codeExample:
        return Icon(Icons.code, color: Colors.purple);
    }
  }

  String _getTypeLabel(ContentType type) {
    switch (type) {
      case ContentType.topic:
        return 'Topic';
      case ContentType.quiz:
        return 'Quiz';
      case ContentType.fillBlank:
        return 'Fill Blank';
      case ContentType.codeExample:
        return 'Code Example';
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

  void _viewContent(UserContent content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(content: content),
      ),
    );
  }

  Future<void> _editContent(UserContent content) async {
    // Navigate to AddContentScreen in edit mode
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddContentScreen(existingContent: content),
      ),
    );
    
    // Refresh the list if the user successfully edited
    if (result == true) {
      _loadContributions();
    }
  }

  Future<void> _deleteContent(UserContent content) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text('Are you sure you want to delete "${_getContentTitle(content)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete the content
    final success = await UserContentService.deleteContribution(content.id);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content deleted successfully')),
        );
        _loadContributions();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete content'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Detail screen to view content
class ContentDetailScreen extends StatelessWidget {
  final UserContent content;

  const ContentDetailScreen({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author and date info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'By ${content.authorName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Added on ${_formatDate(content.createdAt)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    _getTypeChip(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Content based on type
            _buildContentView(),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (content.type) {
      case ContentType.topic:
        return content.content['title'] as String? ?? 'Topic';
      case ContentType.quiz:
        return content.content['topicTitle'] as String? ?? 'Quiz';
      case ContentType.fillBlank:
        return content.content['topicTitle'] as String? ?? 'Fill Blanks';
      case ContentType.codeExample:
        return content.content['title'] as String? ?? 'Code Example';
    }
  }

  Widget _getTypeChip() {
    final typeLabels = {
      ContentType.topic: '📚 Topic',
      ContentType.quiz: '❓ Quiz',
      ContentType.fillBlank: '✍️ Fill Blank',
      ContentType.codeExample: '💻 Code',
    };
    
    return Chip(
      label: Text(
        typeLabels[content.type] ?? '',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildContentView() {
    switch (content.type) {
      case ContentType.topic:
        return _buildTopicView();
      case ContentType.quiz:
        return _buildQuizView();
      case ContentType.fillBlank:
        return _buildFillBlankView();
      case ContentType.codeExample:
        return _buildCodeExampleView();
    }
  }

  Widget _buildTopicView() {
    final explanation = content.content['explanation'] as String? ?? '';
    final codeSnippet = content.content['codeSnippet'] as String? ?? '';
    final revisionPoints = content.content['revisionPoints'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (explanation.isNotEmpty) ...[
          const Text(
            'Explanation:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MarkdownBody(data: explanation),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        if (codeSnippet.isNotEmpty) ...[
          const Text(
            'Code Example:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  codeSnippet,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        if (revisionPoints.isNotEmpty) ...[
          const Text(
            'Key Points:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: revisionPoints.map((point) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(child: Text(point.toString())),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuizView() {
    final questions = content.content['questions'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiz Questions (${questions.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value as Map<String, dynamic>;
          final options = question['options'] as List? ?? [];
          final correctIndex = question['correctIndex'] as int? ?? 0;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${index + 1}: ${question['question']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...options.asMap().entries.map((optEntry) {
                    final optIndex = optEntry.key;
                    final isCorrect = optIndex == correctIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.circle_outlined,
                            size: 20,
                            color: isCorrect ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              optEntry.value.toString(),
                              style: TextStyle(
                                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                color: isCorrect ? Colors.green : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFillBlankView() {
    final questions = content.content['questions'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fill in the Blanks (${questions.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value as Map<String, dynamic>;
          final statement = question['statement'] as String? ?? '';
          final answer = question['answer'] as String? ?? '';
          final hint = question['hint'] as String?;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${index + 1}: $statement',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Answer: $answer',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Hint: $hint',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCodeExampleView() {
    final description = content.content['description'] as String? ?? '';
    final code = content.content['code'] as String? ?? '';
    final language = content.content['language'] as String? ?? 'code';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description.isNotEmpty) ...[
          const Text(
            'Description:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(description),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        Row(
          children: [
            const Text(
              'Code:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(language.toUpperCase()),
              backgroundColor: Colors.purple.withOpacity(0.2),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
