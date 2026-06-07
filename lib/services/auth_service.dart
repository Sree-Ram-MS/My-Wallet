import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.appdata',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  AuthService._init();

  /// Logs in using Google OAuth (or simulated mode if credentials are not configured/unavailable)
  Future<UserProfile?> signInWithGoogle({bool simulate = true}) async {
    if (simulate) {
      // Simulate OAuth network latency
      await Future.delayed(const Duration(milliseconds: 1500));
      return UserProfile(
        id: 'google-simulated-user-12345',
        name: 'Simulated Google User',
        email: 'wallet.demo@gmail.com',
        profilePicUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        authType: 'google',
      );
    }

    try {
      // Force account selector and permission chooser to display
      try {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
      } catch (_) {
        // Ignored if not signed in
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      return UserProfile(
        id: googleUser.id,
        name: googleUser.displayName ?? 'Google User',
        email: googleUser.email,
        profilePicUrl: googleUser.photoUrl,
        authType: 'google',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Registers or returns Guest User Profile
  Future<UserProfile> signInAsGuest() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return UserProfile(
      id: 'guest-local-user',
      name: 'Guest User',
      email: 'guest@local.device',
      authType: 'guest',
    );
  }

  /// Signs out
  Future<void> signOut({bool simulate = true}) async {
    if (simulate) return;
    await _googleSignIn.signOut();
  }

  /// Exposes the Google Sign-In authentication headers (access tokens)
  Future<Map<String, String>?> getAuthHeaders() async {
    var account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    if (account == null) return null;
    return await account.authHeaders;
  }
}
