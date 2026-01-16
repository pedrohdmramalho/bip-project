import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeManager extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeModeManager() {
    _loadThemeMode();
  }
  
  ThemeMode get themeMode => _themeMode;
  
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey) ?? 'system';
      
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString().split('.').last == themeName,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading theme mode: $e');
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _themeMode = mode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.toString().split('.').last);
      notifyListeners();
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }
  
  String getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System';
    }
  }
}
