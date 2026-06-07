import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/user_profile.dart';

class SettingsService {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _settingsFile async {
    final path = await _localPath;
    return File('$path/app_settings.json');
  }

  /// Loads all settings as a Map
  static Future<Map<String, dynamic>> _loadSettings() async {
    try {
      final file = await _settingsFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        return json.decode(content) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  /// Saves settings map
  static Future<void> _saveSettings(Map<String, dynamic> settings) async {
    try {
      final file = await _settingsFile;
      await file.writeAsString(json.encode(settings));
    } catch (_) {}
  }

  /// Load theme mode (defaults to dark, i.e. true)
  static Future<bool> loadDarkMode() async {
    final settings = await _loadSettings();
    // Default to true if not set
    return settings['darkMode'] ?? true;
  }

  /// Save theme mode
  static Future<void> saveDarkMode(bool isDark) async {
    final settings = await _loadSettings();
    settings['darkMode'] = isDark;
    await _saveSettings(settings);
  }

  /// Load biometric lock enablement (defaults to false)
  static Future<bool> loadBiometricEnabled() async {
    final settings = await _loadSettings();
    return settings['biometricEnabled'] ?? false;
  }

  /// Save biometric lock enablement
  static Future<void> saveBiometricEnabled(bool enabled) async {
    final settings = await _loadSettings();
    settings['biometricEnabled'] = enabled;
    await _saveSettings(settings);
  }

  /// Load user session profile
  static Future<UserProfile?> loadUserSession() async {
    final settings = await _loadSettings();
    final sessionMap = settings['userSession'];
    if (sessionMap != null) {
      try {
        return UserProfile.fromMap(Map<String, dynamic>.from(sessionMap));
      } catch (_) {}
    }
    return null;
  }

  /// Save user session profile
  static Future<void> saveUserSession(UserProfile? profile) async {
    final settings = await _loadSettings();
    if (profile == null) {
      settings.remove('userSession');
    } else {
      settings['userSession'] = profile.toMap();
    }
    await _saveSettings(settings);
  }

  /// Load backup encryption key
  static Future<String?> loadBackupKey() async {
    final settings = await _loadSettings();
    return settings['backupKey'] as String?;
  }

  /// Save backup encryption key
  static Future<void> saveBackupKey(String key) async {
    final settings = await _loadSettings();
    settings['backupKey'] = key;
    await _saveSettings(settings);
  }

  /// Load Gemini API key
  static Future<String?> loadGeminiApiKey() async {
    final settings = await _loadSettings();
    return settings['geminiApiKey'] as String?;
  }

  /// Save Gemini API key
  static Future<void> saveGeminiApiKey(String? key) async {
    final settings = await _loadSettings();
    if (key == null || key.isEmpty) {
      settings.remove('geminiApiKey');
    } else {
      settings['geminiApiKey'] = key;
    }
    await _saveSettings(settings);
  }
}
