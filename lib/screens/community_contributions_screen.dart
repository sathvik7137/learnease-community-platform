import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../models/user_content.dart';
import '../services/user_content_service.dart';
import '../services/auth_service.dart';
import '../widgets/enhanced_ui_components.dart';
import '../providers/theme_provider.dart';
import 'add_content_screen.dart';
import 'sign_in_screen.dart';
import 'dart:async';
import 'dart:convert';

class CommunityContributionsScreen extends StatefulWidget {
  const CommunityContributionsScreen({super.key});

  @override
  State<CommunityContributionsScreen> createState() => _CommunityContributionsScreenState();
}

class _CommunityContributionsScreenState extends State<CommunityContributionsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _loadingAnimController;
  bool _isLoading = false;
  int _loadingSeconds = 0;
  Timer? _loadingTimer;
  List<UserContent> _contributions = [];
  Set<int> _selectedIndices = {}; // Track selected items for deletion
  bool _selectionMode = false; // Toggle selection mode on/off
  ContentType? _filterType;
  StreamSubscription<List<UserContent>>? _realtimeSubscription;
  final AuthService _authService = AuthService();
  String? _currentUsername;
  String? _currentEmail;
  
  // Caching mechanism with shorter validity for fresher data
  static final Map<String, List<UserContent>> _globalContributionCache = {};
  static final Map<String, DateTime> _globalLastFetchTime = {};
  static const Duration _cacheValidityDuration = Duration(seconds: 30); // Reduced from 10 minutes to 30 seconds
  
  // Track if we're currently fetching to prevent duplicate requests
  static final Map<String, bool> _isFetching = {};
  bool _hasMadeInitialFetch = false;
  
  // Throttle stream updates to prevent endless loops
  DateTime? _lastStreamUpdate;
  static const Duration _streamUpdateThrottle = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadingAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _tabController.addListener(_onTabChanged);
    
    // Always clear cache and fetch fresh data on init to show latest content
    _globalContributionCache.clear();
    _globalLastFetchTime.clear();
    _loadContributions();
    _loadCurrentUserInfo();
    
    // Start real-time updates
    UserContentService.startRealtimeUpdates();
    
    // Listen to real-time updates
    _realtimeSubscription = UserContentService.contributionsStream.listen((allContributions) {
      if (mounted) {
        _updateContributionsFromStream(allContributions);
      }
    });
  }
  
  void _onTabChanged() {
    // Only load if we don't have cached data or it's stale
    _loadContributions();
  }
  
  Future<void> _loadCurrentUserInfo() async {
    final username = await UserContentService.getUsername();
    final email = await _authService.getUserEmail();
    final token = await _authService.getToken();
    
    // Only consider user logged in if they have a valid token
    final isLoggedIn = token != null && token.isNotEmpty;
    
    setState(() {
      _currentUsername = isLoggedIn ? username : null;
      _currentEmail = isLoggedIn ? email : null;
    });
  }
  
  void _updateContributionsFromStream(List<UserContent> allContributions) {
    // Throttle stream updates to prevent endless rebuild loops
    final now = DateTime.now();
    if (_lastStreamUpdate != null && 
        now.difference(_lastStreamUpdate!) < _streamUpdateThrottle) {
      return;
    }
    _lastStreamUpdate = now;
    
    final category = _tabController.index == 0 ? CourseCategory.java : CourseCategory.dbms;
    final filtered = allContributions.where((c) {
      final matchCategory = c.category == category;
      final matchType = _filterType == null || c.type == _filterType;
      return matchCategory && matchType;
    }).toList();
    
    // Check if this is actually different from current contributions
    // to avoid unnecessary rebuilds
    if (_contributions.length == filtered.length &&
        _contributions.asMap().entries.every((entry) =>
            entry.value.id == filtered[entry.key].id)) {
      return;
    }
    
    // Update global cache with new data from stream
    final cacheKey = _getCacheKey(category);
    _globalContributionCache[cacheKey] = filtered;
    _globalLastFetchTime[cacheKey] = DateTime.now();
    
    if (mounted) {
      setState(() {
        _contributions = filtered;
        // Stop loading if we got contributions from stream
        if (_isLoading && filtered.isNotEmpty) {
          _isLoading = false;
          _loadingTimer?.cancel();
        }
      });
    }
  }
  
  String _getCacheKey(CourseCategory category) {
    return '${category.toString()}_${_filterType?.toString() ?? 'all'}';
  }
  
  // Public method to force refresh - clears cache and reloads
  Future<void> forceRefresh() async {
    // Clear all cache
    _globalContributionCache.clear();
    _globalLastFetchTime.clear();
    print('[Community] 🔄 Force refresh: Cache cleared');
    
    // Reload contributions
    await _loadContributions();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _realtimeSubscription?.cancel();
    UserContentService.stopRealtimeUpdates();
    _loadingAnimController.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadContributions() async {
    final category = _tabController.index == 0 ? CourseCategory.java : CourseCategory.dbms;
    final cacheKey = _getCacheKey(category);
    
    // Check if we're already fetching this category to prevent duplicates
    if (_isFetching[cacheKey] == true) {
      return;
    }
    
    // Check if we have cached data
    final cachedData = _globalContributionCache[cacheKey];
    final lastFetch = _globalLastFetchTime[cacheKey];
    final isCacheFresh = lastFetch != null && DateTime.now().difference(lastFetch) < _cacheValidityDuration;
    
    // If cache is fresh and we have data, use it immediately without loading indicator or fetching
    if (cachedData != null && isCacheFresh) {
      if (mounted) {
        setState(() {
          _contributions = cachedData;
          _isLoading = false;
          _hasMadeInitialFetch = true;
        });
      }
      return;
    }
    
    // If we have cached data but it's stale, show it while fetching in background
    if (cachedData != null && !isCacheFresh) {
      if (mounted) {
        setState(() {
          _contributions = cachedData;
          _isLoading = true;
          _loadingSeconds = 0;
          _hasMadeInitialFetch = true;
        });
      }
    } else {
      // No cached data, show loading
      if (mounted) {
        setState(() {
          _isLoading = true;
          _loadingSeconds = 0;
        });
      }
    }
    
    // Mark as fetching
    _isFetching[cacheKey] = true;
    
    // Start elapsed time counter (for accurate timing display)
    _loadingTimer?.cancel();
    int elapsedSeconds = 0;
    _loadingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      elapsedSeconds++;
      if (mounted) {
        setState(() => _loadingSeconds = (elapsedSeconds / 10).ceil());
      }
    });
    
    try {
      // Fetch fresh data - include both approved and pending (pending shows with special badge)
      final contributions = await UserContentService.getCommunityContributions(category: category, type: _filterType);
      
      // Stop timer immediately
      _loadingTimer?.cancel();
      
      // Update global cache and timestamp
      _globalContributionCache[cacheKey] = contributions;
      _globalLastFetchTime[cacheKey] = DateTime.now();
      
      // Update contributions and hide loading
      if (mounted) {
        setState(() {
          _contributions = contributions;
          _isLoading = false;
          _loadingSeconds = 0;
          _hasMadeInitialFetch = true;
        });
      }
    } catch (e) {
      // Stop timer on error
      _loadingTimer?.cancel();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingSeconds = 0;
        });
      }
      print('[Community] ❌ Error loading contributions for $cacheKey: $e');
    } finally {
      // Clear fetching flag
      _isFetching[cacheKey] = false;
    }
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
      final category = _tabController.index == 0 ? CourseCategory.java : CourseCategory.dbms;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AddContentScreen(initialCategory: category),
        ),
      );
      if (result == true) {
        _loadContributions();
      }
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      // Only select contributions that belong to the current user
      final ownedIndices = <int>[];
      for (int i = 0; i < _contributions.length; i++) {
        final content = _contributions[i];
        final currentUsernameNormalized = _currentUsername?.trim().toLowerCase() ?? '';
        final authorNameNormalized = content.authorName.trim().toLowerCase();
        if (currentUsernameNormalized.isNotEmpty && currentUsernameNormalized == authorNameNormalized) {
          ownedIndices.add(i);
        }
      }
      _selectedIndices = Set.from(ownedIndices);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndices.clear();
      _selectionMode = false;
    });
  }

  void _deleteSelected() {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items selected for deletion')),
      );
      return;
    }

    final selectedCount = _selectedIndices.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Items'),
        content: Text('Delete $selectedCount item(s)? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _performBulkDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkDelete() async {
    final selectedCount = _selectedIndices.length;
    final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    
    // Store item IDs before we modify the list
    final itemsToDelete = <String>[];
    for (final index in sortedIndices) {
      if (index < _contributions.length) {
        itemsToDelete.add(_contributions[index].id);
      }
    }
    
    int successCount = 0;
    int failureCount = 0;

    // Delete each item
    for (final itemId in itemsToDelete) {
      try {
        print('🗑️ Attempting to delete contribution: $itemId');
        final result = await UserContentService.deleteContribution(itemId);
        print('📊 Delete result for $itemId: $result');
        if (result) {
          successCount++;
        } else {
          failureCount++;
        }
      } catch (e) {
        print('❌ Error deleting item $itemId: $e');
        failureCount++;
      }
    }

    setState(() {
      _selectedIndices.clear();
      _selectionMode = false;
    });

    // Reload contributions from server to get updated list
    await _loadContributions();

    // Show feedback
    if (mounted) {
      if (successCount > 0 && failureCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Successfully deleted $successCount item(s)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (successCount > 0 && failureCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Deleted $successCount, failed to delete $failureCount'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Failed to delete items'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      initialIndex: _tabController.index,
      child: Scaffold(
        appBar: _selectionMode
            ? AppBar(
                title: Text('${_selectedIndices.length} selected'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                ),
                actions: [
                  if (_selectedIndices.length < _contributions.length)
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      onPressed: _selectAll,
                      tooltip: 'Select All',
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteSelected,
                    tooltip: 'Delete Selected',
                  ),
                ],
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: Container(
                  color: isDark ? const Color(0xFF121212) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Java Tab
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _tabController.animateTo(0);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _tabController.index == 0
                                            ? colors.primary
                                            : Colors.transparent,
                                        width: 3.0,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.code,
                                        size: 18,
                                        color: _tabController.index == 0
                                            ? colors.primary
                                            : colors.onSurface.withOpacity(0.5),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Java',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: _tabController.index == 0
                                              ? colors.primary
                                              : colors.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // DBMS Tab
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _tabController.animateTo(1);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _tabController.index == 1
                                            ? colors.primary
                                            : Colors.transparent,
                                        width: 3.0,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.storage,
                                        size: 18,
                                        color: _tabController.index == 1
                                            ? colors.primary
                                            : colors.onSurface.withOpacity(0.5),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'DBMS',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: _tabController.index == 1
                                              ? colors.primary
                                              : colors.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Add Content Button
                            IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: colors.primary,
                                size: 28,
                              ),
                              onPressed: _handleAddContentPress,
                              tooltip: 'Add Content',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF0F1419),
                      const Color(0xFF1A1E27),
                      const Color(0xFF121820),
                    ]
                  : [
                      const Color(0xFFF8FAFB),
                      const Color(0xFFF3F5F7),
                      const Color(0xFFEEF1F4),
                    ],
            ),
          ),
          child: _isLoading
              ? _buildLoadingState()
              : _contributions.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadContributions,
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          ..._buildApprovedSection(isDark),
                          ..._buildPendingSection(isDark),
                          ..._buildRejectedSection(isDark),
                        ],
                      ),
                    ),
        ),
        floatingActionButton: _selectionMode
            ? FloatingActionButton.extended(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete),
                label: Text('Delete (${_selectedIndices.length})'),
                backgroundColor: Colors.red,
              )
            : null,
      ),
    );
  }

  Widget _buildTimelineApprovalCard(bool isDark) {
    const primaryColor = Color(0xFF5C6BC0);
    const accentColor = Color(0xFF7E57C2);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, accentColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.timeline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Content Approval Journey',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your submission through the approval stages',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Timeline stages
          Row(
            children: [
              _buildTimelineStage('✅', 'Submit', 0),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withOpacity(0.25),
                          const Color(0xFF8B5CF6).withOpacity(0.25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
              _buildTimelineStage('⏳', 'Review', 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8B5CF6).withOpacity(0.25),
                          const Color(0xFF10B981).withOpacity(0.25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
              _buildTimelineStage('✔️', 'Approved', 2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.25),
                          const Color(0xFF10B981).withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
              _buildTimelineStage('📱', 'Live', 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStage(String emoji, String label, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.2),
                const Color(0xFF8B5CF6).withOpacity(0.15),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated rotating spinner
            RotationTransition(
              turns: _loadingAnimController,
              child: Icon(
                Icons.refresh,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Loading text
            const Text(
              'Fetching contributions...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            // Elapsed time counter
            Text(
              'Loading ${_loadingSeconds}s...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalInfoBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pending_actions,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⏳ Content Approval Process',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'New content requires admin review before appearing here',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '✅ Submit content → ⏳ Pending review → ✔️ Approved → 📱 Appears in community',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            SizedBox(height: 32),
            // Info box explaining the approval process
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2F3F)
                    : const Color(0xFFF0F2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF5C6BC0).withOpacity(isDark ? 0.3 : 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5C6BC0).withOpacity(isDark ? 0.1 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: const Color(0xFF5C6BC0),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'How Content Gets Approved',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildApprovalStep(1, 'Add Content', 'Submit your contribution', isDark),
                  const SizedBox(height: 8),
                  _buildApprovalStep(2, 'Admin Review', 'Content is reviewed by admins', isDark),
                  const SizedBox(height: 8),
                  _buildApprovalStep(3, 'Approved', 'Content appears in community', isDark),
                ],
              ),
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

  Widget _buildApprovalStep(int step, String title, String description, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF5C6BC0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFFB0B5C6)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildApprovedSection(bool isDark) {
    // Approved content visible to EVERYONE
    final approved = _contributions.where((c) => c.status == ContentStatus.approved).toList();
    if (approved.isEmpty) return [];
    
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withOpacity(0.15),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.verified_outlined,
                color: Color(0xFF10B981),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approved Content',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Curated learning resources',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white.withOpacity(0.55) : Colors.grey[700],
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                approved.length.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
    
    for (int i = 0; i < approved.length; i++) {
      widgets.add(_buildContentCard(approved[i], _currentUsername, _currentEmail, i, isDark));
    }
    
    return widgets;
  }

  List<Widget> _buildPendingSection(bool isDark) {
    // Pending content visible ONLY to the owner
    final currentUsernameNormalized = _currentUsername?.trim().toLowerCase() ?? '';
    final pending = _contributions.where((c) {
      // Only show pending if logged in AND is the owner
      final isOwner = _currentUsername != null && 
                      _currentUsername!.isNotEmpty && 
                      c.authorName.trim().toLowerCase() == currentUsernameNormalized;
      return c.status == ContentStatus.pending && isOwner;
    }).toList();
    
    if (pending.isEmpty) return [];
    
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.pending_outlined,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Pending Submissions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Awaiting admin review',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white.withOpacity(0.55) : Colors.grey[700],
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                pending.length.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFF59E0B).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withOpacity(0.2),
              ),
              child: const Icon(
                Icons.info_outlined,
                size: 14,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Only you can see these submissions. They\'re under admin review.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[700],
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
    
    for (int i = 0; i < pending.length; i++) {
      widgets.add(_buildContentCard(pending[i], _currentUsername, _currentEmail, i, isDark));
    }
    
    return widgets;
  }

  List<Widget> _buildRejectedSection(bool isDark) {
    // Rejected content visible ONLY to the owner
    final currentUsernameNormalized = _currentUsername?.trim().toLowerCase() ?? '';
    final rejected = _contributions.where((c) {
      // Only show if logged in AND is the owner
      final isOwner = _currentUsername != null && 
                      _currentUsername!.isNotEmpty && 
                      c.authorName.trim().toLowerCase() == currentUsernameNormalized;
      return c.status == ContentStatus.rejected && isOwner;
    }).toList();
    
    if (rejected.isEmpty) return [];
    
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withOpacity(0.15),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.close_outlined,
                color: Color(0xFFEF4444),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Rejected Submissions',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Review feedback and improve',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.55),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                rejected.length.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEF4444).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withOpacity(0.2),
              ),
              child: const Icon(
                Icons.info_outlined,
                size: 14,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Only you can see these submissions. Review feedback and resubmit with improvements.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
    
    for (int i = 0; i < rejected.length; i++) {
      widgets.add(_buildContentCard(rejected[i], _currentUsername, _currentEmail, i, isDark));
    }
    
    return widgets;
  }

  Widget _buildContentCard(UserContent content, String? currentUsername, String? currentEmail, int index, bool isDark) {
    final title = _getContentTitle(content);
    final subtitle = _getContentSubtitle(content);
    final isSelected = _selectedIndices.contains(index);
    
    // Check if user is actually logged in (must have both username AND email)
    final isLoggedIn = currentUsername != null && 
                       currentUsername.isNotEmpty && 
                       currentEmail != null && 
                       currentEmail.isNotEmpty;
    
    // Check ownership by comparing username (case-insensitive, strict match only)
    // Only allow ownership if user is logged in AND usernames match
    final currentUsernameNormalized = currentUsername?.trim().toLowerCase() ?? '';
    final authorNameNormalized = content.authorName.trim().toLowerCase();
    final isOwner = isLoggedIn && 
                    currentUsernameNormalized.isNotEmpty && 
                    currentUsernameNormalized == authorNameNormalized;
    
    // Determine glow color based on status
    Color glowColor = Colors.blueAccent;
    if (content.status == ContentStatus.approved) {
      glowColor = Colors.greenAccent;
    } else if (content.status == ContentStatus.pending) {
      glowColor = Colors.orangeAccent;
    } else if (content.status == ContentStatus.rejected) {
      glowColor = Colors.redAccent;
    }
    
    // Determine status color
    Color statusColor = const Color(0xFF3B82F6); // Blue for other
    if (content.status == ContentStatus.approved) {
      statusColor = const Color(0xFF10B981); // Green
    } else if (content.status == ContentStatus.pending) {
      statusColor = const Color(0xFFF59E0B); // Orange
    } else if (content.status == ContentStatus.rejected) {
      statusColor = const Color(0xFFEF4444); // Red
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border.all(
          color: statusColor.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectionMode
              ? (isOwner ? () => _toggleSelection(index) : null)
              : () => _viewContent(content),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_selectionMode && isOwner)
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          _toggleSelection(index);
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: _getTypeIconGradient(content.type),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white.withOpacity(0.55) : Colors.grey[700],
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_selectionMode)
                      PopupMenuButton<String>(
                        itemBuilder: (context) {
                          final items = <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'view',
                              child: Row(
                                children: [
                                  const Icon(Icons.visibility, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('View'),
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
                                    const Icon(Icons.edit, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, size: 20, color: Colors.red),
                                    const SizedBox(width: 8),
                                    const Text('Delete', style: TextStyle(color: Colors.red)),
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
                const SizedBox(height: 12),
                // Badges row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: content.category == CourseCategory.java
                            ? const Color(0xFF3B82F6).withOpacity(0.15)
                            : const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: content.category == CourseCategory.java
                              ? const Color(0xFF3B82F6).withOpacity(0.4)
                              : const Color(0xFF10B981).withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            content.category == CourseCategory.java ? Icons.code : Icons.storage,
                            size: 14,
                            color: content.category == CourseCategory.java
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            content.category == CourseCategory.java ? 'Java' : 'DBMS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: content.category == CourseCategory.java
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF10B981),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    _buildStatusBadge(content.status),
                  ],
                ),
                const SizedBox(height: 12),
                // Author and date row with subtle icons
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Icon(Icons.person, size: 12, color: isDark ? Colors.white : Colors.grey[700]),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'By ${content.authorEmail}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white.withOpacity(0.55) : Colors.grey[700],
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Icon(Icons.access_time, size: 12, color: isDark ? Colors.white : Colors.grey[700]),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(content.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white.withOpacity(0.55) : Colors.grey[700],
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Show rejection reason if content is rejected and has a reason
                if (content.status == ContentStatus.rejected && content.rejectionReason != null && content.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rejection Reason:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                content.rejectionReason!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.red.shade300 : Colors.red.shade900,
                                  letterSpacing: 0.2,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ContentStatus status) {
    if (status == ContentStatus.pending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFF59E0B).withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pending_outlined, size: 13, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            const Text(
              'Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF59E0B),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    } else if (status == ContentStatus.approved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_outlined, size: 13, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            const Text(
              'Approved',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFEF4444).withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close_outlined, size: 13, color: Color(0xFFEF4444)),
            const SizedBox(width: 4),
            const Text(
              'Rejected',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }
  }

  Icon _getTypeIconGradient(ContentType type) {
    switch (type) {
      case ContentType.topic:
        return const Icon(Icons.article, color: Colors.white);
      case ContentType.quiz:
        return const Icon(Icons.quiz, color: Colors.white);
      case ContentType.fillBlank:
        return const Icon(Icons.edit_note, color: Colors.white);
      case ContentType.codeExample:
        return const Icon(Icons.code, color: Colors.white);
    }
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
    // Robust extraction: handle Map, nested 'content', or stringified JSON
    dynamic raw = content.content;
    Map<String, dynamic>? map;

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) map = Map<String, dynamic>.from(decoded);
      } catch (_) {
        // not JSON
      }
    } else if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    }

    // If map itself contains a nested 'content' object, prefer that
    if (map != null && map['content'] is Map) {
      map = Map<String, dynamic>.from(map['content'] as Map);
    }

    // Try common keys depending on type
    switch (content.type) {
      case ContentType.topic:
        final result = (map != null && (map['title'] as String?)?.isNotEmpty == true)
            ? (map['title'] as String)
            : 'Untitled Topic';
        return result;
      case ContentType.quiz:
        final result = (map != null && (map['topicTitle'] as String?)?.isNotEmpty == true)
            ? (map['topicTitle'] as String)
            : 'Quiz';
        return result;
      case ContentType.fillBlank:
        final result = (map != null && (map['topicTitle'] as String?)?.isNotEmpty == true)
            ? (map['topicTitle'] as String)
            : 'Fill in the Blanks';
        return result;
      case ContentType.codeExample:
        final result = (map != null && (map['title'] as String?)?.isNotEmpty == true)
            ? (map['title'] as String)
            : 'Code Example';
        return result;
    }
  }

  String _getContentSubtitle(UserContent content) {
    // Robust extraction for subtitle metadata
    dynamic raw = content.content;
    Map<String, dynamic>? map;

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) map = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    } else if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    }

    if (map != null && map['content'] is Map) {
      map = Map<String, dynamic>.from(map['content'] as Map);
    }

    switch (content.type) {
      case ContentType.topic:
        // Use short excerpt of explanation if available
        final explanation = (map != null) ? (map['explanation'] as String? ?? '') : '';
        if (explanation.isNotEmpty) {
          final singleLine = explanation.replaceAll(RegExp(r"\s+"), ' ').trim();
          return singleLine.length > 80 ? '${singleLine.substring(0, 77)}...' : singleLine;
        }
        return 'Learning Topic';
      case ContentType.quiz:
      case ContentType.fillBlank:
        final questions = (map != null) ? (map['questions'] as List?) : null;
        return '${questions?.length ?? 0} questions';
      case ContentType.codeExample:
        return (map != null && (map['language'] as String?)?.isNotEmpty == true)
            ? (map['language'] as String)
            : 'Code';
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
    // Security check: Verify ownership before allowing edit
    final currentUsernameNormalized = _currentUsername?.trim().toLowerCase() ?? '';
    final authorNameNormalized = content.authorName.trim().toLowerCase();
    final isOwner = currentUsernameNormalized.isNotEmpty && 
                    currentUsernameNormalized == authorNameNormalized;
    
    if (!isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit your own contributions'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
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
    // Security check: Verify ownership before allowing delete
    final currentUsernameNormalized = _currentUsername?.trim().toLowerCase() ?? '';
    final authorNameNormalized = content.authorName.trim().toLowerCase();
    final isOwner = currentUsernameNormalized.isNotEmpty && 
                    currentUsernameNormalized == authorNameNormalized;
    
    if (!isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own contributions'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
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
        }).toList(),
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
