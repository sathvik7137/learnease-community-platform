import 'package:flutter/material.dart';
import '../models/user_content.dart';
import '../models/user.dart';
import '../services/user_content_service.dart';
import '../services/auth_service.dart';

class AdminModerationScreen extends StatefulWidget {
  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  List<UserContent> _pendingContributions = [];
  bool _isLoading = false;
  String? _errorMessage;
  UserRole? _userRole;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadPendingContributions();
  }

  Future<void> _checkAdminAccess() async {
    final isAdmin = await AuthService().isAdmin();
    final role = await AuthService().getUserRole();
    
    setState(() {
      _userRole = role;
    });

    if (!isAdmin) {
      // Redirect or show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have admin access')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadPendingContributions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pending = await UserContentService.getPendingContributions();
      setState(() {
        _pendingContributions = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load pending contributions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _approveContribution(String id) async {
    try {
      final success = await UserContentService.approveContribution(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contribution approved')),
        );
        await _loadPendingContributions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve contribution')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectContribution(String id) async {
    try {
      final success = await UserContentService.rejectContribution(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contribution rejected')),
        );
        await _loadPendingContributions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reject contribution')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showApprovalDialog(UserContent content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade100,
                      ),
                      child: Icon(
                        _getContentIcon(content.type),
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Review Contribution',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Decide to approve or reject',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Author & Meta Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Author',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  content.authorName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Type',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _getTypeLabel(content.type),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _getCategoryLabel(content.category),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            content.createdAt.toString().split('.')[0],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Content Display
                Text(
                  'Content',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Text(
                    content.content.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveContribution(content.id);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _rejectContribution(content.id);
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  String _getCategoryLabel(CourseCategory category) {
    switch (category) {
      case CourseCategory.java:
        return 'Java';
      case CourseCategory.dbms:
        return 'DBMS';
    }
  }

  String _truncateContent(String content) {
    if (content.length > 100) {
      return '${content.substring(0, 100)}...';
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Moderation'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPendingContributions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pendingContributions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 80,
                            color: Colors.green[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Pending Contributions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'All contributions have been moderated',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadPendingContributions,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPendingContributions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _pendingContributions.length,
                        itemBuilder: (context, index) {
                          final content = _pendingContributions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: ListTile(
                              leading: Icon(
                                _getContentIcon(content.type),
                                color: Colors.blue,
                              ),
                              title: Text(
                                content.authorName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Type: ${_getTypeLabel(content.type)}'),
                                  Text('Category: ${_getCategoryLabel(content.category)}'),
                                  Text(
                                    'Posted: ${content.createdAt.toString().split('.')[0]}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                              onTap: () => _showApprovalDialog(content),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPendingContributions,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  IconData _getContentIcon(ContentType type) {
    switch (type) {
      case ContentType.topic:
        return Icons.book;
      case ContentType.quiz:
        return Icons.quiz;
      case ContentType.fillBlank:
        return Icons.edit;
      case ContentType.codeExample:
        return Icons.code;
    }
  }
}
