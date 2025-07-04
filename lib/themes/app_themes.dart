import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  // Dark Mode Color Palette
  static const Color darkPrimary = Color(0xFF1E40AF); // Deep Blue
  static const Color darkSecondary = Color(0xFF059669); // Emerald Green
  static const Color darkTertiary = Color(0xFF7C3AED); // Purple accent
  static const Color darkBackground = Color(0xFF0F0F23); // Very dark blue
  static const Color darkSurface = Color(0xFF1A1A2E); // Dark blue-gray
  static const Color darkCard = Color(0xFF16213E); // Dark blue card
  static const Color darkText = Color(0xFFE8E8E8); // Light gray text
  static const Color darkTextSecondary = Color(0xFFB0B0B0); // Medium gray text
  static const Color darkAccent = Color(0xFF4F46E5); // Indigo accent
  static const Color darkSuccess = Color(0xFF10B981); // Green success
  static const Color darkWarning = Color(0xFFF59E0B); // Orange warning
  static const Color darkError = Color(0xFFEF4444); // Red error

  // Light Mode Color Palette
  static const Color lightPrimary = Color(0xFF1E40AF); // Deep Blue
  static const Color lightSecondary = Color(0xFF059669); // Emerald Green
  static const Color lightTertiary = Color(0xFF7C3AED); // Purple accent
  static const Color lightBackground = Color(0xFFF8FAFC); // Very light gray
  static const Color lightSurface = Color(0xFFFFFFFF); // White
  static const Color lightCard = Color(0xFFFFFFFF); // White card
  static const Color lightText = Color(0xFF1F2937); // Dark gray text
  static const Color lightTextSecondary = Color(0xFF6B7280); // Medium gray text
  static const Color lightAccent = Color(0xFF4F46E5); // Indigo accent
  static const Color lightSuccess = Color(0xFF10B981); // Green success
  static const Color lightWarning = Color(0xFFF59E0B); // Orange warning
  static const Color lightError = Color(0xFFEF4444); // Red error

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        tertiary: darkTertiary,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: darkText,
        error: darkError,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: darkText, displayColor: darkText),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: darkPrimary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkAccent,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimary,
        unselectedItemColor: darkTextSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.poppins(
          color: darkTextSecondary,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: GoogleFonts.poppins(color: darkText, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return darkPrimary;
          }
          return darkTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return darkPrimary.withValues(alpha: 0.3);
          }
          return darkTextSecondary.withValues(alpha: 0.3);
        }),
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        tertiary: lightTertiary,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: lightText,
        error: lightError,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().textTheme,
      ).apply(bodyColor: lightText, displayColor: lightText),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: lightPrimary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightPrimary,
        unselectedItemColor: lightTextSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightCard,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.poppins(
          color: lightTextSecondary,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightCard,
        contentTextStyle: GoogleFonts.poppins(color: lightText, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return lightPrimary;
          }
          return lightTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return lightPrimary.withValues(alpha: 0.3);
          }
          return lightTextSecondary.withValues(alpha: 0.3);
        }),
      ),
    );
  }
}

// Theme Provider
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme =>
      _isDarkMode ? AppThemes.darkTheme : AppThemes.lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _saveThemeMode();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
    _saveThemeMode();
  }

  void _saveThemeMode() {
    // In a real app, you would save to SharedPreferences or similar
    // For now, we'll just keep it in memory
  }

  void loadThemeMode() {
    // In a real app, you would load from SharedPreferences
    // For now, we'll default to system theme
    _isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    notifyListeners();
  }
}
