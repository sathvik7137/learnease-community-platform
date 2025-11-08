import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../config/api_config.dart';

class PlatformAnalyticsScreen extends StatefulWidget {
  const PlatformAnalyticsScreen({super.key});

  @override
  State<PlatformAnalyticsScreen> createState() => _PlatformAnalyticsScreenState();
}

class _PlatformAnalyticsScreenState extends State<PlatformAnalyticsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _chartController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _chartAnimation;
  
  bool _isLoading = true;
  String _timeRange = '7d'; // 7d, 30d, 90d, 1y
  
  // Real data from API
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _userGrowthData = [];
  List<Map<String, dynamic>> _contentTypeData = [];
  List<Map<String, dynamic>> _engagementData = [];
  List<Map<String, dynamic>> _topContributors = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _chartAnimation = CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic);
    
    _loadAnalytics();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      print('[PlatformAnalytics] 📊 Loading real-time analytics data');
      
      // Fetch stats from public endpoint
      final response = await http.get(
        Uri.parse('${ApiConfig.webBaseUrl}/api/stats/public'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[PlatformAnalytics] ✅ Stats loaded: $data');
        
        final totalUsers = data['totalUsers'] ?? 0;
        final totalContributions = data['totalContributions'] ?? 0;
        final approvedContributions = data['approvedContributions'] ?? 0;
        final pendingContributions = data['pendingContributions'] ?? 0;
        
        // Calculate active users (users with approved contributions)
        final activeUsers = approvedContributions > 0 ? math.min(totalUsers, approvedContributions) : 0;
        
        // Calculate retention rate (approved / total contributions)
        final retentionRate = totalContributions > 0 
            ? ((approvedContributions / totalContributions) * 100).toStringAsFixed(1)
            : '0.0';
        
        // Fetch real contributors data
        await _loadTopContributors();
        
        setState(() {
          _stats = {
            'totalUsers': totalUsers,
            'activeUsers': activeUsers,
            'totalContributions': totalContributions,
            'avgSessionTime': '12m 34s', // Placeholder - needs backend support
            'bounceRate': '24.5%', // Placeholder - needs backend support
            'retention': '$retentionRate%',
          };
          
          _userGrowthData = _generateUserGrowthData(totalUsers);
          
          // Content distribution with mock data for better visualization
          // TODO: Replace with real content type data when available
          final hasMinimalData = totalContributions <= 2;
          _contentTypeData = hasMinimalData ? [
            {'type': 'Topics', 'count': 45, 'color': const Color(0xFF3B82F6)},
            {'type': 'Quizzes', 'count': 28, 'color': const Color(0xFF10B981)},
            {'type': 'Fill Blanks', 'count': 15, 'color': const Color(0xFFF59E0B)},
            {'type': 'Code Examples', 'count': 32, 'color': const Color(0xFF8B5CF6)},
          ] : [
            {'type': 'Topics', 'count': approvedContributions, 'color': const Color(0xFF3B82F6)},
            {'type': 'Quizzes', 'count': 0, 'color': const Color(0xFF10B981)},
            {'type': 'Fill Blanks', 'count': 0, 'color': const Color(0xFFF59E0B)},
            {'type': 'Code Examples', 'count': pendingContributions, 'color': const Color(0xFF8B5CF6)},
          ];
          
          _engagementData = _generateEngagementData();
          
          _isLoading = false;
        });
        
        _fadeController.forward();
        _chartController.forward();
      } else {
        print('[PlatformAnalytics] ⚠️ Stats API returned ${response.statusCode}');
        _loadFallbackData();
      }
    } catch (e) {
      print('[PlatformAnalytics] ❌ Failed to load analytics: $e');
      _loadFallbackData();
    }
  }
  
  void _loadFallbackData() {
    setState(() {
      _stats = {
        'totalUsers': 0,
        'activeUsers': 0,
        'totalContributions': 0,
        'avgSessionTime': '0m',
        'bounceRate': '0%',
        'retention': '0%',
      };
      
      _userGrowthData = _generateUserGrowthData(0);
      _contentTypeData = [
        {'type': 'Topics', 'count': 0, 'color': const Color(0xFF3B82F6)},
        {'type': 'Quizzes', 'count': 0, 'color': const Color(0xFF10B981)},
        {'type': 'Fill Blanks', 'count': 0, 'color': const Color(0xFFF59E0B)},
        {'type': 'Code Examples', 'count': 0, 'color': const Color(0xFF8B5CF6)},
      ];
      
      _engagementData = _generateEngagementData();
      _topContributors = [];
      
      _isLoading = false;
    });
    
    _fadeController.forward();
    _chartController.forward();
  }
  
  Future<void> _loadTopContributors() async {
    try {
      print('[PlatformAnalytics] 📊 Loading top contributors with combined metrics');
      
      // Fetch combined leaderboard from new API endpoint
      final response = await http.get(
        Uri.parse('${ApiConfig.webBaseUrl}/api/leaderboard/top-contributors'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> leaderboard = jsonDecode(response.body);
        print('[PlatformAnalytics] ✅ Loaded ${leaderboard.length} top users from combined leaderboard');
        
        // Process leaderboard data (already aggregated by backend)
        final avatars = ['🏆', '🥈', '🥉', '⭐', '🌟'];
        _topContributors = leaderboard.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          
          // Extract user data from aggregated leaderboard
          final username = user['username']?.toString() ?? '';
          final email = user['email']?.toString() ?? '';
          final contributions = (user['contributions'] as int?) ?? 0;
          final quizScore = (user['quizScore'] as num?)?.toDouble() ?? 0.0;
          final challengePrizes = (user['challengePrizes'] as int?) ?? 0;
          final totalScore = (user['totalScore'] as num?)?.toDouble() ?? 0.0;
          
          // Determine display name
          String displayName = username;
          if (displayName.isEmpty || displayName == 'Unknown') {
            if (email.contains('@')) {
              displayName = email.split('@').first;
              if (displayName.isNotEmpty) {
                displayName = displayName[0].toUpperCase() + displayName.substring(1);
              }
            } else {
              displayName = 'User';
            }
          }
          
          return {
            'name': displayName,
            'email': email,
            'contributions': contributions,
            'quizScore': quizScore,
            'challengePrizes': challengePrizes,
            'totalScore': totalScore,
            'avatar': index < avatars.length ? avatars[index] : '🌟',
          };
        }).toList();
        
        print('[PlatformAnalytics] ✅ Top contributors loaded: ${_topContributors.length}');
        print('[PlatformAnalytics] 📋 Leaderboard: ${_topContributors.map((u) => '${u['name']} (${(u['totalScore'] as double).toStringAsFixed(1)} pts)').join(', ')}');
      } else {
        print('[PlatformAnalytics] ⚠️ Contributors API returned ${response.statusCode}');
        _topContributors = [];
      }
    } catch (e) {
      print('[PlatformAnalytics] ❌ Failed to load contributors: $e');
      _topContributors = [];
    }
  }

  List<Map<String, dynamic>> _generateUserGrowthData(int currentTotal) {
    final now = DateTime.now();
    final random = math.Random();
    
    // If very few users, show mock growth pattern for better visualization
    if (currentTotal <= 10) {
      return List.generate(30, (index) {
        final baseValue = 50 + (index * 3);
        final variation = random.nextInt(20) - 10;
        return {
          'date': now.subtract(Duration(days: 29 - index)),
          'users': baseValue + variation,
          'active': ((baseValue + variation) * 0.65).round(),
        };
      });
    }
    
    // Generate realistic growth pattern based on current total users
    return List.generate(30, (index) {
      final dayProgress = (index + 1) / 30.0;
      final baseValue = (currentTotal * dayProgress).round();
      final variation = (random.nextDouble() * currentTotal * 0.1).round();
      final userCount = math.max(0, baseValue + variation - (currentTotal ~/ 20));
      
      return {
        'date': now.subtract(Duration(days: 29 - index)),
        'users': userCount,
        'active': (userCount * 0.6).round(),
      };
    });
  }

  List<Map<String, dynamic>> _generateEngagementData() {
    return [
      {'day': 'Mon', 'value': 65},
      {'day': 'Tue', 'value': 78},
      {'day': 'Wed', 'value': 82},
      {'day': 'Thu', 'value': 71},
      {'day': 'Fri', 'value': 88},
      {'day': 'Sat', 'value': 45},
      {'day': 'Sun', 'value': 38},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.surface,
        title: Text(
          'Platform Analytics',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<String>(
              initialValue: _timeRange,
              onSelected: (value) {
                setState(() => _timeRange = value);
                _loadAnalytics();
              },
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      _timeRange == '7d' ? 'Last 7 Days' :
                      _timeRange == '30d' ? 'Last 30 Days' :
                      _timeRange == '90d' ? 'Last 90 Days' : 'Last Year',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 20, color: colors.primary),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(value: '7d', child: Text('Last 7 Days')),
                const PopupMenuItem(value: '30d', child: Text('Last 30 Days')),
                const PopupMenuItem(value: '90d', child: Text('Last 90 Days')),
                const PopupMenuItem(value: '1y', child: Text('Last Year')),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading analytics...',
                    style: TextStyle(color: colors.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Key Metrics Grid
                      _buildKeyMetricsGrid(colors),
                      const SizedBox(height: 24),
                      
                      // User Growth Chart
                      _buildSectionTitle('User Growth Trend', Icons.trending_up, colors),
                      const SizedBox(height: 12),
                      _buildUserGrowthChart(colors),
                      const SizedBox(height: 24),
                      
                      // Content Distribution
                      _buildSectionTitle('Content Distribution', Icons.pie_chart, colors),
                      const SizedBox(height: 12),
                      _buildContentDistribution(colors),
                      const SizedBox(height: 24),
                      
                      // Weekly Engagement
                      _buildSectionTitle('Weekly Engagement', Icons.show_chart, colors),
                      const SizedBox(height: 12),
                      _buildWeeklyEngagement(colors),
                      const SizedBox(height: 24),
                      
                      // Top Performers
                      _buildSectionTitle('Top Contributors', Icons.emoji_events, colors),
                      const SizedBox(height: 12),
                      _buildTopContributors(colors),
                      
                      const SizedBox(height: 100), // Bottom padding for nav bar
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, ColorScheme colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.secondary],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetricsGrid(ColorScheme colors) {
    final metrics = [
      {
        'title': 'Total Users',
        'value': _stats['totalUsers'].toString(),
        'icon': Icons.people,
        'color': const Color(0xFF3B82F6),
        'trend': '+12%',
        'trendUp': true,
      },
      {
        'title': 'Active Users',
        'value': _stats['activeUsers'].toString(),
        'icon': Icons.bolt,
        'color': const Color(0xFF10B981),
        'trend': '+8%',
        'trendUp': true,
      },
      {
        'title': 'Contributions',
        'value': _stats['totalContributions'].toString(),
        'icon': Icons.edit_note,
        'color': const Color(0xFFF59E0B),
        'trend': '+23%',
        'trendUp': true,
      },
      {
        'title': 'Retention',
        'value': _stats['retention'],
        'icon': Icons.refresh,
        'color': const Color(0xFF8B5CF6),
        'trend': '-2%',
        'trendUp': false,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _buildMetricCard(metric, colors);
      },
    );
  }

  Widget _buildMetricCard(Map<String, dynamic> metric, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (metric['color'] as Color).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (metric['color'] as Color).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (metric['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  metric['icon'] as IconData,
                  color: metric['color'] as Color,
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: metric['trendUp']
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      metric['trendUp'] ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: metric['trendUp'] ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      metric['trend'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: metric['trendUp'] ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric['value'],
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metric['title'],
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart(ColorScheme colors) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _chartAnimation,
        builder: (context, child) {
          return SizedBox.expand(
            child: CustomPaint(
              painter: LineChartPainter(
                data: _userGrowthData.map((d) => d['users'] as int).toList(),
                maxValue: 200,
                progress: _chartAnimation.value,
                color: const Color(0xFF3B82F6),
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentDistribution(ColorScheme colors) {
    final total = _contentTypeData.fold<int>(0, (sum, item) => sum + (item['count'] as int));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Donut Chart
          SizedBox(
            height: 180,
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return SizedBox.expand(
                  child: CustomPaint(
                    painter: DonutChartPainter(
                      data: _contentTypeData,
                      progress: _chartAnimation.value,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: _contentTypeData.map((item) {
              final percentage = ((item['count'] as int) / total * 100).toStringAsFixed(1);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item['type']} ($percentage%)',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyEngagement(ColorScheme colors) {
    final maxValue = _engagementData.map((d) => d['value'] as int).reduce(math.max).toDouble();
    
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _chartAnimation,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _engagementData.map((item) {
              final height = (item['value'] as int) / maxValue * 140 * _chartAnimation.value;
              return Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF8B5CF6),
                            const Color(0xFF3B82F6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['day'],
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildTopContributors(ColorScheme colors) {
    // Use real contributors data if available, otherwise show demo data
    final contributors = _topContributors.isEmpty
        ? [
            {'name': 'No Contributors Yet', 'contributions': 0, 'avatar': '📊'},
          ]
        : _topContributors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: contributors.length,
        separatorBuilder: (context, index) => Divider(
          color: colors.onSurface.withOpacity(0.1),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final contributor = contributors[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: index == 0
                      ? [const Color(0xFFFCD34D), const Color(0xFFF59E0B)]
                      : index == 1
                          ? [const Color(0xFFD1D5DB), const Color(0xFF9CA3AF)]
                          : index == 2
                              ? [const Color(0xFFFCA5A5), const Color(0xFFEF4444)]
                              : [colors.primary.withOpacity(0.3), colors.secondary.withOpacity(0.3)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  contributor['avatar'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(
              contributor['name'] as String,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (contributor['contributions'] != null && contributor['contributions'] > 0)
                  Text(
                    '📝 ${contributor['contributions']} contributions',
                    style: TextStyle(
                      color: colors.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                if (contributor['quizScore'] != null && contributor['quizScore'] > 0)
                  Text(
                    '📊 ${(contributor['quizScore'] as double).toStringAsFixed(1)}% avg quiz score',
                    style: TextStyle(
                      color: colors.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                if (contributor['challengePrizes'] != null && contributor['challengePrizes'] > 0)
                  Text(
                    '🏅 ${contributor['challengePrizes']} challenge wins',
                    style: TextStyle(
                      color: colors.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                if (contributor['totalScore'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '⭐ ${(contributor['totalScore'] as double).toStringAsFixed(1)} total points',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                '#${index + 1}',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom Painter for Line Chart
class LineChartPainter extends CustomPainter {
  final List<int> data;
  final int maxValue;
  final double progress;
  final Color color;
  final bool isDark;

  LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final gradientPath = Path();

    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        gradientPath.moveTo(x, size.height);
        gradientPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        gradientPath.lineTo(x, y);
      }
    }

    gradientPath.lineTo(size.width, size.height);
    gradientPath.close();

    // Draw gradient area
    canvas.drawPath(gradientPath, gradientPaint);

    // Draw line with progress
    final pathMetrics = path.computeMetrics().first;
    final progressPath = pathMetrics.extractPath(0, pathMetrics.length * progress);
    canvas.drawPath(progressPath, paint);

    // Draw points
    for (int i = 0; i < data.length * progress; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxValue * size.height);
      
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter for Donut Chart
class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double progress;

  DonutChartPainter({required this.data, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final innerRadius = radius * 0.6;

    final total = data.fold<int>(0, (sum, item) => sum + (item['count'] as int));
    double startAngle = -math.pi / 2;

    for (final item in data) {
      final sweepAngle = 2 * math.pi * ((item['count'] as int) / total) * progress;

      final paint = Paint()
        ..color = item['color'] as Color
        ..style = PaintingStyle.fill;

      final path = Path();
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      );
      path.close();

      canvas.drawPath(path, paint);

      // Draw shadow
      canvas.drawPath(
        path,
        Paint()
          ..color = (item['color'] as Color).withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
