import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../models/user_content.dart';

class AdminContributionsScreen extends StatefulWidget {
  const AdminContributionsScreen({super.key});

  @override
  State<AdminContributionsScreen> createState() => _AdminContributionsScreenState();
}

class _AdminContributionsScreenState extends State<AdminContributionsScreen> with TickerProviderStateMixin {
  static const String _serverUrl = 'http://localhost:8080';
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _contributions = [];
  String _filterStatus = 'all'; // all, pending, approved, rejected
  String _filterCategory = 'all'; // all, java, dbms
  String _filterType = 'all'; // all, topic, quiz, fillBlank, codeExample
  
  Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _loadContributions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadContributions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No token found');

      final uri = Uri.parse('$_serverUrl/api/admin/contributions').replace(queryParameters: {
        'status': _filterStatus,
        'category': _filterCategory,
        'type': _filterType,
      });

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _contributions = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
        _fadeController.forward(from: 0.0);
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _updateContributionStatus(String id, String status, {String? note}) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.patch(
        Uri.parse('$_serverUrl/api/admin/contributions/$id/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          if (note != null) 'adminNote': note,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Contribution ${status}!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
        _loadContributions();
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _deleteContribution(String id) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.delete(
        Uri.parse('$_serverUrl/api/admin/contributions/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contribution deleted!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
        _loadContributions();
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _bulkApprove() async {
    if (_selectedIds.isEmpty) return;

    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$_serverUrl/api/admin/contributions/bulk-approve'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ids': _selectedIds.toList()}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Approved ${data['approvedCount']} contributions!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
        setState(() {
          _selectedIds.clear();
          _isSelectionMode = false;
        });
        _loadContributions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedIds.isEmpty) return;

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDarkDialog(
        title: 'Bulk Delete',
        content: 'Are you sure you want to delete ${_selectedIds.length} contributions? This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: const Color(0xFFEF4444),
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$_serverUrl/api/admin/contributions/bulk-delete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ids': _selectedIds.toList()}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted ${data['deletedCount']} contributions!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
        setState(() {
          _selectedIds.clear();
          _isSelectionMode = false;
        });
        _loadContributions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilters(),
          if (_isSelectionMode) _buildBulkActions(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _contributions.isEmpty
                    ? _buildEmptyState()
                    : _buildContributionsList(),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _selectedIds.clear();
                  _isSelectionMode = false;
                });
              },
              backgroundColor: const Color(0xFF374151),
              child: const Icon(Icons.close, color: Colors.white),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF161B22),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.admin_panel_settings, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text(
            'Manage Contributions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        if (_isSelectionMode)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                '${_selectedIds.length} selected',
                style: const TextStyle(
                  color: Color(0xFF60A5FA),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        IconButton(
          onPressed: () {
            setState(() {
              _isSelectionMode = !_isSelectionMode;
              if (!_isSelectionMode) _selectedIds.clear();
            });
          },
          icon: Icon(
            _isSelectionMode ? Icons.check_box : Icons.check_box_outline_blank,
            color: _isSelectionMode ? const Color(0xFF60A5FA) : Colors.white,
          ),
          tooltip: 'Selection Mode',
        ),
        IconButton(
          onPressed: _loadContributions,
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B).withOpacity(0.6),
            const Color(0xFF0F172A).withOpacity(0.5),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF374151).withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Status', [
                  ('all', 'All'),
                  ('pending', 'Pending'),
                  ('approved', 'Approved'),
                  ('rejected', 'Rejected'),
                ], _filterStatus, (value) {
                  setState(() => _filterStatus = value);
                  _loadContributions();
                }),
                const SizedBox(width: 12),
                _buildFilterChip('Category', [
                  ('all', 'All'),
                  ('java', 'Java'),
                  ('dbms', 'DBMS'),
                ], _filterCategory, (value) {
                  setState(() => _filterCategory = value);
                  _loadContributions();
                }),
                const SizedBox(width: 12),
                _buildFilterChip('Type', [
                  ('all', 'All'),
                  ('topic', 'Topic'),
                  ('quiz', 'Quiz'),
                  ('fillBlank', 'Fill Blank'),
                  ('codeExample', 'Code'),
                ], _filterType, (value) {
                  setState(() => _filterType = value);
                  _loadContributions();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    List<(String, String)> options,
    String currentValue,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: options.map((option) {
            final isSelected = currentValue == option.$1;
            return GestureDetector(
              onTap: () => onChanged(option.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF60A5FA).withOpacity(0.5)
                        : const Color(0xFF4B5563),
                    width: 1,
                  ),
                ),
                child: Text(
                  option.$2,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBulkActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _selectedIds.isEmpty ? null : _bulkApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                disabledBackgroundColor: const Color(0xFF374151),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text(
                'Approve Selected',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _selectedIds.isEmpty ? null : _bulkDelete,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                disabledBackgroundColor: const Color(0xFF374151),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.delete_sweep, size: 18),
              label: const Text(
                'Delete Selected',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading contributions...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.2),
                  const Color(0xFF8B5CF6).withOpacity(0.2),
                ],
              ),
            ),
            child: const Icon(
              Icons.inbox,
              size: 64,
              color: Color(0xFF60A5FA),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Contributions Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contributions.length,
        itemBuilder: (context, index) {
          final contribution = _contributions[index];
          final id = contribution['_id']['\$oid'] as String;
          final isSelected = _selectedIds.contains(id);

          return _buildContributionCard(contribution, id, isSelected);
        },
      ),
    );
  }

  Widget _buildContributionCard(Map<String, dynamic> contribution, String id, bool isSelected) {
    final status = contribution['status'] as String? ?? 'pending';
    final category = contribution['category'] as String? ?? 'java';
    final type = contribution['type'] as String? ?? 'topic';
    final authorName = contribution['authorName'] as String? ?? 'Unknown';
    final createdAt = contribution['serverCreatedAt'] as String?;
    
    final content = contribution['content'] as Map<String, dynamic>?;
    final title = content?['title'] as String? ?? 
                  content?['question'] as String? ?? 
                  'Untitled';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pending;
    }

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(id);
            } else {
              _selectedIds.add(id);
            }
          });
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedIds.add(id);
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1E293B)).withOpacity(0.6),
              (isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF0F172A)).withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF60A5FA).withOpacity(0.5)
                : const Color(0xFF374151).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_isSelectionMode)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFF60A5FA) : Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFF60A5FA),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isSelected ? Icons.check : Icons.circle_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
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
                _buildBadge(category.toUpperCase(), category == 'java' ? const Color(0xFF3B82F6) : const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildBadge(_getTypeLabel(type), const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                Icon(Icons.person, size: 14, color: Colors.white.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                  authorName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Created: ${_formatDate(createdAt)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
            if (!_isSelectionMode) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (status == 'pending') ...[
                    Expanded(
                      child: _buildActionButton(
                        'Approve',
                        Icons.check_circle,
                        const Color(0xFF10B981),
                        () => _updateContributionStatus(id, 'approved'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        'Reject',
                        Icons.cancel,
                        const Color(0xFFEF4444),
                        () => _updateContributionStatus(id, 'rejected'),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: _buildActionButton(
                        'View Details',
                        Icons.visibility,
                        const Color(0xFF3B82F6),
                        () => _showContributionDetails(contribution),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  _buildIconButton(
                    Icons.delete,
                    const Color(0xFFEF4444),
                    () => _confirmDelete(id),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDarkDialog(
        title: 'Delete Contribution',
        content: 'Are you sure you want to delete this contribution? This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: const Color(0xFFEF4444),
      ),
    );

    if (confirmed == true) {
      _deleteContribution(id);
    }
  }

  void _showContributionDetails(Map<String, dynamic> contribution) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E293B).withOpacity(0.95),
                    const Color(0xFF0F172A).withOpacity(0.95),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF3B82F6).withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Contribution Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Author', contribution['authorName'] ?? 'Unknown'),
                          _buildDetailRow('Category', (contribution['category'] as String? ?? 'java').toUpperCase()),
                          _buildDetailRow('Type', _getTypeLabel(contribution['type'] as String? ?? 'topic')),
                          _buildDetailRow('Status', (contribution['status'] as String? ?? 'pending').toUpperCase()),
                          if (contribution['serverCreatedAt'] != null)
                            _buildDetailRow('Created', _formatDate(contribution['serverCreatedAt'] as String)),
                          const SizedBox(height: 16),
                          const Text(
                            'Content',
                            style: TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1117),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF374151),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              const JsonEncoder.withIndent('  ').convert(contribution['content']),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: confirmColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning, color: confirmColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'topic':
        return 'Topic';
      case 'quiz':
        return 'Quiz';
      case 'fillBlank':
        return 'Fill Blank';
      case 'codeExample':
        return 'Code Example';
      default:
        return type;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 30) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } else if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
