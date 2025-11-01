import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Helper to add Noto Sans as fallback for comprehensive Unicode support
TextStyle _addNotoSansFallback(TextStyle style) {
  return style.copyWith(
    fontFamilyFallback: const ['NotoSans', 'Roboto'],
  );
}

class AppTheme {
  // Primary Colors
  static const Color primaryColorLight = Color(0xFF5C6BC0);
  static const Color primaryColorDark = Color(0xFF7E57C2);
  static const Color accentColor = Color(0xFF3F51B5);
  static const Color secondaryAccent = Color(0xFF7E57C2);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF1A237E);
  static const Color lightSubtleText = Color(0xFF90A4AE);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1A1F2E);
  static const Color darkText = Color(0xFFE8EAED);
  static const Color darkSubtleText = Color(0xFF90A4AE);

  // Success, Warning, Error colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color infoColor = Color(0xFF2196F3);

  /// Light Theme - Optimized for performance
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColorLight,
      secondary: secondaryAccent,
      tertiary: Color(0xFF26A69A),
      surface: lightSurface,
      error: errorColor,
      outline: Color(0xFFBDBDBD),
    ),
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: primaryColorLight,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
      centerTitle: false,
      scrolledUnderElevation: 0, // Smooth app bar transitions
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: lightText,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: lightText,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: lightText,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: lightText,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: lightText,
        height: 1.3,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: lightText,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: lightText,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: lightText,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: lightText,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: lightText,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: lightSubtleText,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 2, // Reduced from 4 for better performance
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      clipBehavior: Clip.antiAlias, // Better clipping performance
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColorLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: primaryColorLight.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        animationDuration: const Duration(milliseconds: 150), // Faster button animations
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColorLight,
        side: const BorderSide(color: primaryColorLight, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        animationDuration: const Duration(milliseconds: 150),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColorLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColorLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: lightText,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: lightSubtleText,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColorLight,
      foregroundColor: Colors.white,
      elevation: 8,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColorLight.withOpacity(0.1),
      selectedColor: primaryColorLight,
      disabledColor: Colors.grey.shade300,
      labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      brightness: Brightness.light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 16,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColorLight,
      circularTrackColor: Color(0xFFE0E0E0),
    ),
  );

  /// Dark Theme - Optimized for performance
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColorDark,
      secondary: secondaryAccent,
      tertiary: Color(0xFF26A69A),
      surface: darkSurface,
      error: errorColor,
      outline: Color(0xFF424242),
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: darkSurface,
      foregroundColor: darkText,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: darkText,
        letterSpacing: 0.5,
      ),
      centerTitle: false,
      scrolledUnderElevation: 0, // Smooth app bar transitions
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkText,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: darkText,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: darkText,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: darkText,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkText,
        height: 1.3,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: darkText,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: darkText,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: darkText,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: darkText,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkText,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: darkSubtleText,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 2, // Reduced from 4 for better performance
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      clipBehavior: Clip.antiAlias, // Better clipping performance
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColorDark,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: primaryColorDark.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        animationDuration: const Duration(milliseconds: 150), // Faster button animations
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryAccent,
        side: const BorderSide(color: secondaryAccent, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        animationDuration: const Duration(milliseconds: 150),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryAccent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A3142),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF424242), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A4557), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: secondaryAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: darkText,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkSubtleText,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColorDark,
      foregroundColor: Colors.white,
      elevation: 8,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColorDark.withOpacity(0.2),
      selectedColor: primaryColorDark,
      disabledColor: Colors.grey.shade700,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: darkText,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      brightness: Brightness.dark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3A4557),
      thickness: 1,
      space: 16,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColorDark,
      circularTrackColor: Color(0xFF3A4557),
    ),
  );

  /// Helper method to get a gradient based on theme
  static LinearGradient getThemeGradient(BuildContext context, {bool reverse = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark
        ? [primaryColorDark, accentColor]
        : [primaryColorLight, secondaryAccent];
    return LinearGradient(
      colors: reverse ? colors.reversed.toList() : colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Helper method to get text color based on theme
  static Color getTextColor(BuildContext context, {bool subtle = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (subtle) {
      return isDark ? darkSubtleText : lightSubtleText;
    }
    return isDark ? darkText : lightText;
  }

  /// Helper method to get background color based on theme
  static Color getBackgroundColor(BuildContext context, {bool subtle = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (subtle) {
      return isDark
          ? const Color(0xFF2A3142)
          : const Color(0xFFE8EAED);
    }
    return isDark ? darkBackground : lightBackground;
  }

  /// Helper method to get surface color based on theme
  static Color getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkSurface : lightSurface;
  }
}
