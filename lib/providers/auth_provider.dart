import 'dart:math';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/drive_service.dart';
import '../services/encryption_service.dart';
import '../services/settings_service.dart';

class AuthProvider extends ChangeNotifier {
  UserProfile? _user;
  bool _isLoading = false;
  bool _isSimulate = true; // Enabled by default to simplify testing
  String _defaultCurrency = 'INR';
  bool _isBiometricEnabled = false;
  String? _backupKey;
  String? _geminiApiKey;

  UserProfile? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSimulate => _isSimulate;
  String get defaultCurrency => _defaultCurrency;
  bool get isBiometricEnabled => _isBiometricEnabled;
  String? get backupKey => _backupKey;
  String? get geminiApiKey => _geminiApiKey;

  bool get isAuthenticated => _user != null;

  AuthProvider() {
    initSession();
  }

  /// Ensures that a backup key exists. If not, generates it.
  Future<void> _ensureBackupKey() async {
    _backupKey = await SettingsService.loadBackupKey();
    if ((_backupKey == null || _backupKey!.isEmpty) && _user != null) {
      _backupKey = _generateRandomBackupKey();
      await SettingsService.saveBackupKey(_backupKey!);
    }
    notifyListeners();
  }

  String _generateRandomBackupKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write('-');
      }
      buffer.write(chars[random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  /// Load session and biometric settings from storage
  Future<void> initSession() async {
    _isBiometricEnabled = await SettingsService.loadBiometricEnabled();
    _user = await SettingsService.loadUserSession();
    _geminiApiKey = await SettingsService.loadGeminiApiKey();
    if (_user != null) {
      _defaultCurrency = _user!.defaultCurrency;
      await _ensureBackupKey();
    }
    notifyListeners();
  }

  /// Update Gemini API key
  Future<void> setGeminiApiKey(String? key) async {
    _geminiApiKey = key;
    notifyListeners();
    await SettingsService.saveGeminiApiKey(key);
  }

  void toggleSimulation(bool value) {
    _isSimulate = value;
    notifyListeners();
  }

  void setDefaultCurrency(String currency) {
    _defaultCurrency = currency;
    notifyListeners();
  }

  /// Toggle biometric lock and save choice
  Future<void> setBiometricEnabled(bool enabled) async {
    _isBiometricEnabled = enabled;
    notifyListeners();
    await SettingsService.saveBiometricEnabled(enabled);
  }

  /// Guest Login
  Future<void> loginAsGuest() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await AuthService.instance.signInAsGuest();
      _defaultCurrency = _user?.defaultCurrency ?? 'INR';
      await SettingsService.saveUserSession(_user);
      await _ensureBackupKey();
    } catch (e) {
      debugPrint("Guest login failed: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Google Login
  /// Returns null on success, or an error message on failure.
  Future<String?> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loggedInUser = await AuthService.instance.signInWithGoogle(simulate: _isSimulate);
      if (loggedInUser != null) {
        _user = loggedInUser;
        _defaultCurrency = _user?.defaultCurrency ?? 'INR';
        await SettingsService.saveUserSession(_user);
        await _ensureBackupKey();
        _isLoading = false;
        notifyListeners();
        return null;
      }
      _isLoading = false;
      notifyListeners();
      return "Google sign in canceled by user";
    } catch (e) {
      debugPrint("Google login failed: $e");
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  /// Connects the current guest session with a Google account
  /// Returns null on success, or an error message on failure.
  Future<String?> linkWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loggedInUser = await AuthService.instance.signInWithGoogle(simulate: _isSimulate);
      if (loggedInUser != null) {
        // Link guest to Google: update user profile details while preserving currency settings
        _user = UserProfile(
          id: loggedInUser.id,
          name: loggedInUser.name,
          email: loggedInUser.email,
          profilePicUrl: loggedInUser.profilePicUrl,
          defaultCurrency: _defaultCurrency,
          authType: 'google',
        );
        await SettingsService.saveUserSession(_user);
        await _ensureBackupKey();
        _isLoading = false;
        notifyListeners();
        return null;
      }
      _isLoading = false;
      notifyListeners();
      return "Google sign in canceled by user";
    } catch (e) {
      debugPrint("Linking Google failed: $e");
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  /// Update Profile Info
  void updateProfile(String newName, String newCurrency, {String? newProfilePicUrl}) {
    if (_user != null) {
      _user = UserProfile(
        id: _user!.id,
        name: newName,
        email: _user!.email,
        profilePicUrl: newProfilePicUrl ?? _user!.profilePicUrl,
        defaultCurrency: newCurrency,
        authType: _user!.authType,
      );
      _defaultCurrency = newCurrency;
      SettingsService.saveUserSession(_user);
      notifyListeners();
    }
  }

  /// Cloud Backup Flow: exports, encrypts, and uploads
  Future<String?> syncToCloud(Map<String, dynamic> databasePayload) async {
    if (_user == null) return "User not authenticated";
    if (_backupKey == null) {
      await _ensureBackupKey();
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final authHeaders = _isSimulate ? null : await AuthService.instance.getAuthHeaders();
      final encryptedData = EncryptionService.encrypt(databasePayload, _backupKey!);
      
      final success = await DriveService.instance.uploadFile(
        fileName: 'wallet_data.enc',
        encryptedData: encryptedData,
        authHeaders: authHeaders,
        simulate: _isSimulate,
      );

      _isLoading = false;
      notifyListeners();
      return success ? null : "Upload failed";
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  /// Cloud Restore Flow: downloads, decrypts, and returns payload
  Future<Map<String, dynamic>?> restoreFromCloud({String? keyToUse}) async {
    if (_user == null) return null;

    final targetKey = keyToUse ?? _backupKey;
    if (targetKey == null || targetKey.isEmpty) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final authHeaders = _isSimulate ? null : await AuthService.instance.getAuthHeaders();
      final encryptedData = await DriveService.instance.downloadFile(
        fileName: 'wallet_data.enc',
        authHeaders: authHeaders,
        simulate: _isSimulate,
      );

      if (encryptedData == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final decryptedPayload = EncryptionService.decrypt(encryptedData, targetKey);
      
      // If decryption succeeds, store this as our active key
      _backupKey = targetKey;
      await SettingsService.saveBackupKey(targetKey);

      _isLoading = false;
      notifyListeners();
      return decryptedPayload;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Checks if backup exists
  Future<bool> hasCloudBackup() async {
    if (_user == null) return false;
    final authHeaders = _isSimulate ? null : await AuthService.instance.getAuthHeaders();
    return await DriveService.instance.hasBackup(
      authHeaders: authHeaders,
      simulate: _isSimulate,
    );
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    await AuthService.instance.signOut(simulate: _isSimulate);
    _user = null;
    _backupKey = null;
    _geminiApiKey = null;
    await SettingsService.saveUserSession(null);
    await SettingsService.saveBackupKey('');
    await SettingsService.saveGeminiApiKey(null);
    
    _isLoading = false;
    notifyListeners();
  }
}
