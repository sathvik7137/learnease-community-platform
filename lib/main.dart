import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/quiz_test_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/community_contributions_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'services/sound_service.dart';
import 'providers/theme_provider.dart';
import 'utils/app_theme.dart';
import 'widgets/theme_toggle_button.dart';
import 'services/auth_service.dart';
import 'models/user.dart';

Future<void> main() async {
  // Load environment variables (AI_API_BASE, AI_API_KEY) if present
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // On web, .env may not be present in assets — log and continue so UI can run.
    // AI functionality will be disabled until env is provided.
    debugPrint('Could not load .env: $e');
  }
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const LearnEaseApp(),
    ),
  );
}

class LearnEaseApp extends StatelessWidget {
  const LearnEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'LearnEase: Java & DBMS Tutorials',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          routes: {
            '/chat': (ctx) => const ChatScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  static final GlobalKey<_MainNavigationState> globalKey = GlobalKey<_MainNavigationState>();

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _isInitialized = false;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    CoursesScreen(),
    const CommunityContributionsScreen(),
    QuizTestScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start with checking admin status with delay
    _checkAdminStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('[MainNav] App resumed, checking admin status');
      _checkAdminStatus();
    }
  }

  @override
  void didUpdateWidget(MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('[MainNav] Widget updated, checking admin status');
    // After widget update, schedule a check for next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _forceCheckAdminStatus();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    try {
      // Force a fresh check - wait longer for JWT token to be properly saved to storage
      // This is critical because SharedPreferences might take time to write to disk
      print('[MainNav] ⏳ Checking admin status with 1000ms delay...');
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final role = await AuthService().getUserRole();
      print('[MainNav] Current role: $role');
      
      final isAdmin = role == UserRole.admin;
      print('[MainNav] Is admin: $isAdmin, Previous: $_isAdmin');
      
      if ((_isAdmin != isAdmin || !_isInitialized) && mounted) {
        print('[MainNav] ✅ Admin status changed! Setting _isAdmin = $isAdmin');
        setState(() {
          _isAdmin = isAdmin;
          _isInitialized = true;
          
          // If newly admin, navigate to dashboard
          if (isAdmin) {
            _selectedIndex = 4;
            print('[MainNav] 🎯 Navigated to admin dashboard (index=4)');
          }
        });
      } else if (_isInitialized && mounted) {
        // Already initialized, just ensure state is updated
        print('[MainNav] Already initialized');
        setState(() {
          // Trigger rebuild to refresh UI
        });
      }
    } catch (e) {
      print('[MainNav] ❌ Error checking admin status: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _forceCheckAdminStatus() async {
    print('[MainNav] 🔥 FORCE CHECK - Admin status immediately');
    try {
      // Brief delay to ensure persistence
      await Future.delayed(const Duration(milliseconds: 200));
      
      final role = await AuthService().getUserRole();
      final token = await AuthService().getToken();
      print('[MainNav] Force check - Current role: $role, HasToken: ${token != null}');
      
      final isAdmin = role == UserRole.admin;
      print('[MainNav] Force check - Is admin: $isAdmin, Previous: $_isAdmin');
      
      if (mounted) {
        // Update state with new values
        setState(() {
          _isAdmin = isAdmin;
          _isInitialized = true;
          
          if (isAdmin) {
            _selectedIndex = 4;
            print('[MainNav] 🚀 Force check - Navigated to admin dashboard (index=4)');
          } else {
            _selectedIndex = 0;
            print('[MainNav] Force check - Not admin, navigated to home (index=0)');
          }
        });
        
        // Force another rebuild to ensure UI updates
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            // Trigger rebuild
          });
          print('[MainNav] ✅ Force check complete and rebuilt');
        }
      }
    } catch (e) {
      print('[MainNav] Force check error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  /// Public method to force immediate admin check - called from ProfileScreen after admin login
  void forceCheckAdminStatusImmediate() {
    print('[MainNav] 🔴 PUBLIC FORCE CHECK called from ProfileScreen - executing immediately');
    _forceCheckAdminStatus();
  }

  void _onItemTapped(int index) {
    // Play sound and haptic feedback
    SoundService.selectionHaptic();
    SoundService.playTapSound();
    
    // If clicking on profile and user is admin, ensure we show admin dashboard
    if (index == 4) {
      _checkAdminStatus();
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.secondary],
                    ),
                  ),
                  child: const Icon(Icons.school, size: 16, color: Colors.white),
                );
              },
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LearnEase',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                if (_isAdmin)
                  Row(
                    children: [
                      Text(
                        'Admin Mode',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[700],
                        ),
                      ),
                      Text(
                        ' [Index: $_selectedIndex, Init: $_isInitialized]',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        actions: [
          ThemeToggleButton(size: 26, padding: EdgeInsets.only(right: 16)),
        ],
      ),
      body: Builder(
        builder: (context) {
          print('[MainNav] 🔨 Rendering body - _isInitialized=$_isInitialized, _isAdmin=$_isAdmin, _selectedIndex=$_selectedIndex');
          
          if (!_isInitialized) {
            print('[MainNav] ⏳ Not initialized yet, waiting...');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing...', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }
          
          // Show AdminDashboardScreen if admin and on profile tab (index 4)
          if (_isAdmin && _selectedIndex == 4) {
            print('[MainNav] 📊 Showing AdminDashboardScreen');
            try {
              return AdminDashboardScreen();
            } catch (e) {
              print('[MainNav] ❌ Error showing AdminDashboardScreen: $e');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error loading admin dashboard: $e'),
                  ],
                ),
              );
            }
          } else if (_isAdmin && _selectedIndex != 4) {
            // If admin but on a different tab, show that screen
            print('[MainNav] 📱 Admin on different tab - Showing screen[$_selectedIndex]');
            return _screens[_selectedIndex];
          } else {
            // Not admin, show regular screens
            print('[MainNav] 📱 Showing screen[$_selectedIndex]');
            // Safety check: if selectedIndex is out of bounds, show home
            if (_selectedIndex >= 0 && _selectedIndex < _screens.length) {
              return _screens[_selectedIndex];
            } else {
              print('[MainNav] ⚠️ Index out of bounds, showing home screen');
              return _screens[0]; // Home screen
            }
          }
        },
      ),
      extendBody: false,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(isDark ? 0.2 : 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.03),
                        ]
                      : [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                    _buildNavItem(1, Icons.menu_book_outlined, Icons.menu_book_rounded, 'Courses'),
                    _buildNavItem(2, Icons.people_outline, Icons.people_rounded, 'Community'),
                    _buildNavItem(3, Icons.quiz_outlined, Icons.quiz_rounded, 'Quiz'),
                    _buildNavItem(4, Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, _isAdmin ? 'Admin' : 'Profile'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 90.0, right: 20.0),
        child: FloatingActionButton.small(
          onPressed: () {
            Navigator.of(context).pushNamed('/chat');
          },
          foregroundColor: Colors.white,
          tooltip: 'Chat & Community',
          child: const Icon(Icons.chat_bubble_outline),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    colors.primary.withOpacity(0.2),
                    colors.secondary.withOpacity(0.2),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected 
                    ? colors.primary
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected 
                    ? colors.primary
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
// ...existing code...
