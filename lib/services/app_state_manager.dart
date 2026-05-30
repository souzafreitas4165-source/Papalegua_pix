import 'package:flutter/material.dart';

class AppStateManager extends ChangeNotifier {
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isOnline = true;

  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isOnline => _isOnline;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setLocale(Locale? newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      notifyListeners();
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void toggleTheme() {
    setThemeMode(_themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  void setOnlineStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      notifyListeners();
    }
  }
}
