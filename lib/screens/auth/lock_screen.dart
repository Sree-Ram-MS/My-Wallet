import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Trigger biometric prompt right after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;

      if (!isSupported && !canCheck) {
        // Biometrics not available on device, bypass lock
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your wallet',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // fallback to passcode/pin if biometrics fail/unavailable
        ),
      );

      if (authenticated && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      debugPrint("Error during biometric auth: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top padding spacer
              const SizedBox(height: 40),

              // Middle Lock Icon & App Title
              Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF00E676),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'My Wallet Locked',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verification required to unlock',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Unlock Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: const Color(0xFF0F2027),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size(double.infinity, 54),
                        elevation: 4,
                      ),
                      onPressed: _authenticate,
                      icon: const Icon(Icons.fingerprint, size: 24),
                      label: Text(
                        _isAuthenticating ? 'Authenticating...' : 'Tap to Unlock',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () async {
                        await authProv.logout();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/auth');
                        }
                      },
                      child: Text(
                        'Switch Account / Sign Out',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom spacing
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
