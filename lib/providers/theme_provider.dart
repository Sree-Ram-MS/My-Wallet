import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true; // Default to dark mode

  bool get isDarkMode => _isDarkMode;

  /// Loads saved theme setting
  Future<void> initTheme() async {
    _isDarkMode = await SettingsService.loadDarkMode();
    notifyListeners();
  }

  /// Toggles theme and saves preference
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await SettingsService.saveDarkMode(_isDarkMode);
  }
}
