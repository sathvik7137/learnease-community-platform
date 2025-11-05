import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class UserData {
  final String id;
  final String email;
  final String username;
  final String createdAt;
  final int contributionCount;

  UserData({
    required this.id,
    required this.email,
    required this.username,
    required this.createdAt,
    required this.contributionCount,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String? ?? 'N/A',
      createdAt: json['createdAt'] as String? ?? '',
      contributionCount: json['contributionCount'] as int? ?? 0,
    );
  }
}

class AdminUserManagementScreen extends StatefulWidget {
  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  List<UserData> _users = [];
  List<UserData> _filteredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  static const String _serverUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService().getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$_serverUrl/api/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        final users =
            data.map((u) => UserData.fromJson(u as Map<String, dynamic>)).toList();

        setState(() {
          _users = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load users';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users
            .where((user) =>
                user.email.toLowerCase().contains(query.toLowerCase()) ||
                user.username.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _viewUserDetails(UserData user) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$_serverUrl/api/admin/users/${user.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _showUserDetailsDialog(data);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user details: $e')),
      );
    }
  }

  void _showUserDetailsDialog(Map<String, dynamic> userDetails) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email:', userDetails['email'] as String),
              _buildDetailRow('Username:', userDetails['username'] as String),
              _buildDetailRow(
                'Member Since:',
                _formatDate(userDetails['createdAt'] as String),
              ),
              _buildDetailRow(
                'Contributions:',
                (userDetails['contributionCount'] as int).toString(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(userDetails['id'] as String);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete User'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('$_serverUrl/api/admin/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
        await _loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete user')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDeleteConfirmation(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text(
          'Are you sure you want to delete this user? '
          'This will also delete all their contributions. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(userId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: 'Search by email or username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filterUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // User count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Total Users: ${_filteredUsers.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadUsers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUsers,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue[700],
                                      child: Text(
                                        user.email[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(user.email),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Username: ${user.username}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          'Contributions: ${user.contributionCount}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.arrow_forward_ios),
                                      onPressed: () =>
                                          _viewUserDetails(user),
                                    ),
                                    onTap: () => _viewUserDetails(user),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
