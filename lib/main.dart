import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
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
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables asynchronously without blocking startup
  dotenv.load(fileName: '.env').catchError((e) {
    debugPrint('Could not load .env: $e');
    return null;
  });
  
  // Start app immediately without waiting for .env
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
  
  // Method to get screen widget based on index
  // This ensures ProfileScreen is recreated each time it's displayed
  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return CoursesScreen();
      case 2:
        return const CommunityContributionsScreen();
      case 3:
        return QuizTestScreen();
      case 4:
        return ProfileScreen(key: ValueKey(DateTime.now().millisecondsSinceEpoch)); // Force rebuild with unique key
      default:
        return const HomeScreen();
    }
  }

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
    print('[MainNav] Widget updated, skipping admin status check to avoid loops');
    // Don't call _forceCheckAdminStatus() here - it causes infinite loops
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    try {
      print('[MainNav] ⏳ Checking admin status...');
      
      // First validate if token is actually valid (not expired)
      final isTokenValid = await AuthService().isTokenValid();
      print('[MainNav] Token valid: $isTokenValid');
      
      // If token is not valid, clear it and treat as non-admin
      if (!isTokenValid) {
        print('[MainNav] ⚠️ Token is invalid or expired, clearing cache and treating as non-admin');
        await AuthService().clearTokens();
        
        if (mounted && !_isInitialized) {
          setState(() {
            _isAdmin = false;
            _isInitialized = true;
            _selectedIndex = 0; // Go to home screen
          });
        }
        return;
      }
      
      // Token is valid, now check the role
      final role = await AuthService().getUserRole();
      print('[MainNav] Current role: $role');
      
      final isAdmin = role == UserRole.admin;
      print('[MainNav] Is admin: $isAdmin');
      
      if (mounted && !_isInitialized) {
        print('[MainNav] ✅ First time initialization with valid token');
        setState(() {
          _isAdmin = isAdmin;
          _isInitialized = true;
          
          // Navigate based on role
          if (isAdmin) {
            _selectedIndex = 4;
            print('[MainNav] 🎯 Admin user, navigated to dashboard (index=4)');
          } else {
            _selectedIndex = 0;
            print('[MainNav] 📱 Regular user, staying on home (index=0)');
          }
        });
      }
    } catch (e) {
      print('[MainNav] ❌ Error checking admin status: $e');
      if (mounted && !_isInitialized) {
        // On error, treat as not authenticated
        await AuthService().clearTokens();
        setState(() {
          _isInitialized = true;
          _isAdmin = false;
          _selectedIndex = 0;
        });
      }
    }
  }

  Future<void> _forceCheckAdminStatus() async {
    print('[MainNav] 🔥 FORCE CHECK - Admin status immediately');
    try {
      // Brief delay to ensure persistence
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Validate token first
      final isTokenValid = await AuthService().isTokenValid();
      print('[MainNav] Force check - Token valid: $isTokenValid');
      
      // If token is invalid, clear everything
      if (!isTokenValid) {
        print('[MainNav] Force check - ⚠️ Token invalid, clearing cache');
        await AuthService().clearTokens();
        
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _isInitialized = true;
            _selectedIndex = 0;
          });
        }
        return;
      }
      
      final roleString = await AuthService().getUserRole();
      print('[MainNav] Force check - Role: $roleString');
      
      final isAdmin = roleString == UserRole.admin;
      print('[MainNav] Force check - Is admin: $isAdmin');
      print('[MainNav] Force check - Current _isAdmin: $_isAdmin, isAdmin: $isAdmin, _isInitialized: $_isInitialized');
      
      // ALWAYS update state if role changed, regardless of initialization
      if (mounted) {
        if (_isAdmin != isAdmin) {
          print('[MainNav] 🔄 FORCE CHECK - Admin status CHANGED: $_isAdmin → $isAdmin');
          setState(() {
            _isAdmin = isAdmin;
            _isInitialized = true;
            
            if (_isAdmin) {
              _selectedIndex = 4;
              print('[MainNav] 🚀 Force check - Admin confirmed, setting index to 4 (dashboard)');
            } else {
              _selectedIndex = 0;
              print('[MainNav] Force check - Not admin, setting index to 0');
            }
          });
        } else {
          print('[MainNav] Force check - No change needed, already _isAdmin=$_isAdmin');
        }
      }
    } catch (e) {
      print('[MainNav] Force check error: $e');
      if (mounted && !_isInitialized) {
        await AuthService().clearTokens();
        setState(() {
          _isInitialized = true;
          _isAdmin = false;
          _selectedIndex = 0;
        });
      }
    }
  }

  /// Public method to force immediate admin check - called from ProfileScreen after admin login
  void forceCheckAdminStatusImmediate() {
    print('[MainNav] 🔴 PUBLIC FORCE CHECK called from ProfileScreen - executing immediately');
    _forceCheckAdminStatus();
  }

  /// Public method to switch tabs - called from ProfileScreen after admin login to force re-render
  void switchToTab(int index) {
    print('[MainNav] 🔄 PUBLIC METHOD: Switching to tab $index');
    _onItemTapped(index);
  }

  /// Force immediate admin dashboard render after successful admin login
  void forceAdminDashboardRender() async {
    print('[MainNav] ⚡ FORCE ADMIN DASHBOARD RENDER - Immediate update');
    
    try {
      // Get role immediately (already saved by admin login)
      final role = await AuthService().getUserRole();
      print('[MainNav] Force render - Role: $role');
      
      final isAdmin = role == UserRole.admin;
      print('[MainNav] Force render - isAdmin: $isAdmin');
      
      if (mounted && isAdmin) {
        print('[MainNav] 🚀 Setting _isAdmin=true and rebuilding NOW');
        setState(() {
          _isAdmin = true;
          _isInitialized = true;
          _selectedIndex = 4; // Ensure we're on profile tab
        });
        print('[MainNav] ✅ State updated, AdminDashboard should render now');
      }
    } catch (e) {
      print('[MainNav] ❌ Force render error: $e');
    }
  }

  /// Verify and update admin status when navigating to profile tab
  /// This ensures admin users see the dashboard instead of regular profile
  Future<void> _verifyAdminStatus() async {
    try {
      final token = await AuthService().getToken();
      final role = await AuthService().getUserRole();
      final email = await AuthService().getUserEmail();
      
      print('[MainNav] 🔍 Profile tab verification:');
      print('[MainNav]   Token exists: ${token != null && token.isNotEmpty}');
      print('[MainNav]   Email: $email');
      print('[MainNav]   Role: $role');
      print('[MainNav]   Current _isAdmin: $_isAdmin');
      
      final isAdmin = role == UserRole.admin;
      print('[MainNav]   Calculated isAdmin: $isAdmin');
      
      // Always update admin status when on profile tab to ensure correct view
      if (mounted) {
        if (_isAdmin != isAdmin) {
          print('[MainNav] 🔄 Admin status changed: $_isAdmin → $isAdmin');
        }
        setState(() {
          _isAdmin = isAdmin;
          _isInitialized = true;
        });
        print('[MainNav] ✅ Admin status updated to: $_isAdmin');
      }
    } catch (e) {
      print('[MainNav] ❌ Verify admin status error: $e');
    }
  }

  void _onItemTapped(int index) {
    // Play sound and haptic feedback
    SoundService.selectionHaptic();
    SoundService.playTapSound();
    
    setState(() {
      _selectedIndex = index;
    });
    
    // If clicking on profile (index 4), verify admin status and update if needed
    if (index == 4) {
      _verifyAdminStatus();
    }
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
            return _getScreen(_selectedIndex);
          } else {
            // Not admin, show regular screens
            print('[MainNav] 📱 Showing screen[$_selectedIndex]');
            // Safety check: if selectedIndex is out of bounds, show home
            if (_selectedIndex >= 0 && _selectedIndex < 5) {
              return _getScreen(_selectedIndex);
            } else {
              print('[MainNav] ⚠️ Index out of bounds, showing home screen');
              return _getScreen(0); // Home screen
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
