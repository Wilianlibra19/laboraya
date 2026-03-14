import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeBoxName = 'theme';
  static const String _themeModeKey = 'themeMode';
  
  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      Box box;
      if (Hive.isBoxOpen(_themeBoxName)) {
        box = Hive.box(_themeBoxName);
      } else {
        box = await Hive.openBox(_themeBoxName);
      }
      
      final savedTheme = box.get(_themeModeKey, defaultValue: 'light');
      _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
      _themeMode = ThemeMode.light;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    try {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      
      Box box;
      if (Hive.isBoxOpen(_themeBoxName)) {
        box = Hive.box(_themeBoxName);
      } else {
        box = await Hive.openBox(_themeBoxName);
      }
      
      await box.put(_themeModeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _themeMode = mode;
      
      Box box;
      if (Hive.isBoxOpen(_themeBoxName)) {
        box = Hive.box(_themeBoxName);
      } else {
        box = await Hive.openBox(_themeBoxName);
      }
      
      await box.put(_themeModeKey, mode == ThemeMode.dark ? 'dark' : 'light');
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme: $e');
    }
  }
}
