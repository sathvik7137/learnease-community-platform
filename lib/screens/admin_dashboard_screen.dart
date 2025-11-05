import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'admin_moderation_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_contributions_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  String? _adminEmail;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _totalUsers = 0;
  int _totalContributions = 0;
  int _pendingContributions = 0;
  int _approvedContributions = 0;
  
  late AnimationController _fadeInController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    print('[AdminDashboard] ✅ initState called');
    
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeInController, curve: Curves.easeInOut),
    );
    
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      final token = await AuthService().getToken();
      final email = await AuthService().getUserEmail();
      
      setState(() => _adminEmail = email);

      // If token exists, try to fetch real stats
      if (token != null) {
        try {
          final response = await http.get(
            Uri.parse('http://localhost:8080/api/admin/stats'),
            headers: {'Authorization': 'Bearer $token'},
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            setState(() {
              _totalUsers = data['totalUsers'] ?? 0;
              _totalContributions = data['totalContributions'] ?? 0;
              _pendingContributions = data['pendingContributions'] ?? 0;
              _approvedContributions = data['approvedContributions'] ?? 0;
              _isLoading = false;
            });
            
            _fadeInController.forward();
            return; // Success - exit early
          }
        } catch (apiError) {
          print('[AdminDashboard] ⚠️ API call with token failed: $apiError');
        }
      }

      // Fallback: Load stats from public stats endpoint (without auth)
      try {
        print('[AdminDashboard] 📊 Loading stats from public endpoint');
        final response = await http.get(
          Uri.parse('http://localhost:8080/api/stats/public'),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          setState(() {
            _totalUsers = data['totalUsers'] ?? 0;
            _totalContributions = data['totalContributions'] ?? 0;
            _pendingContributions = data['pendingContributions'] ?? 0;
            _approvedContributions = data['approvedContributions'] ?? 0;
            _isLoading = false;
          });
          
          print('[AdminDashboard] ✅ Stats loaded successfully: Users=$_totalUsers, Contributions=$_totalContributions, Pending=$_pendingContributions, Approved=$_approvedContributions');
          _fadeInController.forward();
        } else {
          // Show dashboard with zero stats
          setState(() {
            _totalUsers = 0;
            _totalContributions = 0;
            _pendingContributions = 0;
            _approvedContributions = 0;
            _isLoading = false;
          });
          _fadeInController.forward();
        }
      } catch (e) {
        print('[AdminDashboard] ⚠️ Public stats API failed: $e');
        // Show dashboard with zero stats
        setState(() {
          _totalUsers = 0;
          _totalContributions = 0;
          _pendingContributions = 0;
          _approvedContributions = 0;
          _isLoading = false;
        });
        _fadeInController.forward();
      }
    } catch (e) {
      // Critical error - show error state
      print('[AdminDashboard] ❌ Critical error: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                isDark ? Colors.blueAccent : Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading Dashboard...',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage ?? 'An unknown error occurred',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadAdminInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.blueAccent : Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildQuickStatsHeader(),
            const SizedBox(height: 12),
            _buildQuickStatsGrid(),
            const SizedBox(height: 32),
            _buildFeaturesHeader(),
            const SizedBox(height: 16),
            _buildFeaturesSection(),
            const SizedBox(height: 32),
            _buildSystemInfo(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.blueAccent.withOpacity(0.2), Colors.purpleAccent.withOpacity(0.1)]
              : [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? Colors.blueAccent.withOpacity(0.3) : Colors.purple.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _adminEmail ?? 'Admin',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      'Quick Stats',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = [
      {
        'label': 'Total Users',
        'value': _totalUsers,
        'icon': Icons.people_outline,
        'color': Colors.blue,
      },
      {
        'label': 'Contributions',
        'value': _totalContributions,
        'icon': Icons.assessment_outlined,
        'color': Colors.green,
      },
      {
        'label': 'Pending',
        'value': _pendingContributions,
        'icon': Icons.pending_actions_outlined,
        'color': Colors.orange,
      },
      {
        'label': 'Approved',
        'value': _approvedContributions,
        'icon': Icons.check_circle_outline,
        'color': Colors.teal,
      },
    ];

    return Column(
      children: stats.map((stat) {
        final color = stat['color'] as Color;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: stat['value'] as int),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutQuad,
                      builder: (context, animatedValue, child) {
                        return Text(
                          animatedValue.toString(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color.withOpacity(0.1),
                ),
                child: Text(
                  '+${stat['value']}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeaturesHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      'Admin Features',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'title': 'Contributions\nManagement',
        'icon': Icons.content_paste_rounded,
        'color': Colors.blue,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminContributionsScreen())),
      },
      {
        'title': 'Content\nModeration',
        'icon': Icons.fact_check_rounded,
        'color': Colors.purple,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminModerationScreen())),
      },
      {
        'title': 'User\nManagement',
        'icon': Icons.supervised_user_circle_rounded,
        'color': Colors.indigo,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserManagementScreen())),
      },
      {
        'title': 'Platform\nAnalytics',
        'icon': Icons.analytics_rounded,
        'color': Colors.cyan,
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Analytics coming soon...'), backgroundColor: Colors.blue.shade600),
        ),
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: features.asMap().entries.map((entry) {
          final idx = entry.key;
          final feature = entry.value;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return GestureDetector(
            onTap: feature['onTap'] as VoidCallback,
            child: Container(
              width: 100,
              height: 120,
              margin: EdgeInsets.only(right: idx < features.length - 1 ? 10 : 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: (feature['color'] as Color).withOpacity(0.1),
                border: Border.all(
                  color: (feature['color'] as Color).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    color: feature['color'] as Color,
                    size: 32,
                  ),
                  Text(
                    feature['title'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, MaterialColor color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: color.withOpacity(0.15),
                  ),
                  child: Icon(icon, color: color.shade600, size: 20),
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
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Expanded(
          child: _buildSystemInfoItem(
            icon: Icons.email_outlined,
            label: 'Email',
            value: (_adminEmail == null || _adminEmail!.isEmpty) ? 'Loading...' : _adminEmail!,
            color: Colors.blue,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSystemInfoItem(
            icon: Icons.shield_outlined,
            label: 'Role',
            value: 'Administrator',
            color: Colors.green,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSystemInfoItem(
            icon: Icons.check_circle_outline,
            label: 'Status',
            value: 'Active',
            color: Colors.teal,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoItemOld(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: isDark ? Colors.grey[300] : Colors.grey[700],
        fontFamily: 'monospace',
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await AuthService().clearTokens();
      // Navigate back to splash/login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}
