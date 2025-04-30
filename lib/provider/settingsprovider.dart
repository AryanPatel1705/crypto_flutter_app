import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';

  String get selectedLanguage => _selectedLanguage;
  String get selectedTheme => _selectedTheme;

  void changeLanguage(String newLanguage) {
    _selectedLanguage = newLanguage;
    notifyListeners();
  }

  void changeTheme(String newTheme) {
    _selectedTheme = newTheme;
    notifyListeners();
  }

  ThemeData get themeData {
    switch (_selectedTheme) {
      case 'Dark':
        return ThemeData.dark();
      case 'System Default':
        return ThemeData.fallback();
      default:
        return ThemeData.light();
    }
  }

  get notificationsEnabled => null;

  void changeCurrency(String value) {}
}
