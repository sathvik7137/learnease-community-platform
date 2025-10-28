import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  // Load theme preference from storage
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
  
  // Toggle theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
  
  // Light theme
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: Color(0xFF5C6BC0),
        secondary: Color(0xFF7E57C2),
    surface: Colors.white,
    // previously used background; use surface for compatibility
    // keep a light background via scaffoldBackgroundColor instead
        error: Colors.red.shade400,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF5C6BC0),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF5C6BC0),
      ),
    );
  }
  
  // Dark theme
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF7986CB),
        secondary: Color(0xFF9575CD),
  surface: Color(0xFF1E1E2E),
  // replaced background with surface usage (deprecated)
        error: Colors.red.shade300,
      ),
      scaffoldBackgroundColor: Color(0xFF121218),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF1E1E2E),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        color: Color(0xFF1E1E2E),
  shadowColor: Colors.black.withAlpha((0.5 * 255).round()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF7986CB),
      ),
      textTheme: TextTheme(
  bodyLarge: TextStyle(color: Colors.white.withAlpha((0.9 * 255).round())),
  bodyMedium: TextStyle(color: Colors.white.withAlpha((0.87 * 255).round())),
  bodySmall: TextStyle(color: Colors.white.withAlpha((0.7 * 255).round())),
  titleLarge: TextStyle(color: Colors.white),
  titleMedium: TextStyle(color: Colors.white.withAlpha((0.95 * 255).round())),
  titleSmall: TextStyle(color: Colors.white.withAlpha((0.9 * 255).round())),
      ),
    );
  }
  
  // Get current theme
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;
}
