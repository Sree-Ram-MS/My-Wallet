import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    await authProv.initSession();
    if (authProv.user != null && mounted) {
      if (authProv.isBiometricEnabled) {
        Navigator.pushReplacementNamed(context, '/lock');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  void _showGoogleSignInErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Sign-in Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Sign-in failed. This is common when testing locally if the SHA-1 signing fingerprint is not configured in Firebase.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Error details: $error',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'TIP: You can toggle "OAuth Simulation Mode" at the bottom of the screen to simulate a successful sign-in without Firebase keys.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Beautiful Background Gradient
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // 2. Glowing Bubble Art
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2196F3).withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF009688).withOpacity(0.12),
              ),
            ),
          ),

          // 3. Foreground content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo Image
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676).withOpacity(0.35),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // App Name
                      const Text(
                        'My Wallet',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      const Text(
                        'Secure ledger, smart tracking.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 56),

                      if (authProv.isLoading)
                        const Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Syncing credentials...',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        )
                      else ...[
                        // Google Login Button
                        _buildButton(
                          onPressed: () async {
                            final errorMsg = await authProv.loginWithGoogle();
                            if (errorMsg == null) {
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(context, '/home');
                              }
                            } else {
                              if (context.mounted && errorMsg != "Google sign in canceled by user") {
                                _showGoogleSignInErrorDialog(context, errorMsg);
                              }
                            }
                          },
                          icon: Icons.g_mobiledata,
                          text: 'Log In with Google',
                          color: Colors.white,
                          textColor: const Color(0xFF263238),
                          isGoogle: true,
                        ),
                        const SizedBox(height: 16),

                        // Guest Login Button
                        _buildButton(
                          onPressed: () async {
                            await authProv.loginAsGuest();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/home');
                            }
                          },
                          icon: Icons.person_outline,
                          text: 'Skip Login (Guest Mode)',
                          color: Colors.white.withOpacity(0.08),
                          textColor: Colors.white,
                          isGoogle: false,
                        ),
                      ],
                      const SizedBox(height: 48),
                      
                      // Simulation toggle footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'OAuth Simulation Mode',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 24,
                            child: Switch(
                              value: authProv.isSimulate,
                              activeColor: const Color(0xFF00E676),
                              onChanged: (val) => authProv.toggleSimulation(val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
    required Color color,
    required Color textColor,
    required bool isGoogle,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isGoogle ? BorderSide.none : const BorderSide(color: Colors.white24, width: 1.5),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGoogle)
              const Image(
                image: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.png'),
                height: 22,
                width: 22,
                errorBuilder: _fallbackIcon,
              )
            else
              Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _fallbackIcon(BuildContext context, Object error, StackTrace? stack) {
    return const Icon(Icons.g_mobiledata, size: 24, color: Colors.blue);
  }
}
