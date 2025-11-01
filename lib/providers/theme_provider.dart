import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey) ?? 'light';
      _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }
  
  Future<void> toggleTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      await prefs.setString(_themeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling theme: $e');
    }
  }
  
  Future<void> setTheme(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _themeMode = mode;
      await prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme: $e');
    }
  }
}
