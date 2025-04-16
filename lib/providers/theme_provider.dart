import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const THEME_KEY = 'theme_preference';
  bool _isDarkMode = false;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  ThemeProvider() {
    _loadFromPreferences();
  }

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  // Returns the appropriate theme data based on dark mode setting
  ThemeData get theme => _isDarkMode ? _darkTheme : _lightTheme;

  // Light theme
  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCardBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: ColorScheme.light().copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightCardBackground,
      onSurface: AppColors.lightTextPrimary,
      onBackground: AppColors.lightTextPrimary,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
      bodyMedium: TextStyle(color: AppColors.lightTextPrimary),
      bodySmall: TextStyle(color: AppColors.lightTextSecondary),
      titleLarge: TextStyle(color: AppColors.lightTextPrimary),
      titleMedium: TextStyle(color: AppColors.lightTextPrimary),
      titleSmall: TextStyle(color: AppColors.lightTextPrimary),
    ),
    useMaterial3: true,
  );

  // Dark theme
  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkCardBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: ColorScheme.dark().copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkCardBackground,
      onSurface: AppColors.darkTextPrimary,
      onBackground: AppColors.darkTextPrimary,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
      bodyMedium: TextStyle(color: AppColors.darkTextPrimary),
      bodySmall: TextStyle(color: AppColors.darkTextSecondary),
      titleLarge: TextStyle(color: AppColors.darkTextPrimary),
      titleMedium: TextStyle(color: AppColors.darkTextPrimary),
      titleSmall: TextStyle(color: AppColors.darkTextPrimary),
    ),
    useMaterial3: true,
  );

  // Toggle the theme
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToPreferences();
    notifyListeners();
  }

  // Set specific theme
  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    _saveToPreferences();
    notifyListeners();
  }

  // Load theme preference from SharedPreferences
  Future<void> _loadFromPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(THEME_KEY) ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  // Save theme preference to SharedPreferences
  Future<void> _saveToPreferences() async {
    await _prefs.setBool(THEME_KEY, _isDarkMode);
  }
}
