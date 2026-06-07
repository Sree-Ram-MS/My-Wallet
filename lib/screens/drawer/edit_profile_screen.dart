import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/theme_provider.dart';
import '../navigation_drawer.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _picUrlController;
  late TextEditingController _apiKeyController;
  late String _currency;

  bool _hasBackup = false;
  bool _initialized = false;
  bool _syncing = false;
  bool _obscureKey = true;
  bool _obscureApiKey = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final authProv = Provider.of<AuthProvider>(context);
      _nameController = TextEditingController(text: authProv.user?.name ?? 'Guest User');
      _picUrlController = TextEditingController(text: authProv.user?.profilePicUrl ?? '');
      _apiKeyController = TextEditingController(text: authProv.geminiApiKey ?? '');
      _currency = authProv.defaultCurrency;
      _checkBackupPresence(authProv);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _picUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _checkBackupPresence(AuthProvider authProv) async {
    final hasBkp = await authProv.hasCloudBackup();
    if (mounted) {
      setState(() {
        _hasBackup = hasBkp;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final walletProv = Provider.of<WalletProvider>(context, listen: false);
    final themeProv = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const CustomNavigationDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Text(
          'Settings & Cloud Backup',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PROFILE DETAILS CARD
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'USER SETTINGS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Display Name'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _picUrlController,
                          decoration: const InputDecoration(labelText: 'Profile Picture URL (e.g. http...)'),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _currency,
                          decoration: const InputDecoration(labelText: 'Default Wallet Currency'),
                          items: const [
                            DropdownMenuItem(value: 'INR', child: Text('INR (₹) - Indian Rupee')),
                            DropdownMenuItem(value: 'USD', child: Text('USD (\$) - US Dollar')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR (€) - Euro')),
                            DropdownMenuItem(value: 'GBP', child: Text('GBP (£) - British Pound')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _currency = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                authProv.updateProfile(
                                  _nameController.text.trim(), 
                                  _currency,
                                  newProfilePicUrl: _picUrlController.text.trim(),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Preferences updated successfully!')),
                                );
                              }
                            },
                            child: const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (authProv.user?.authType == 'guest') ...[
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LINK ACCOUNT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'You are currently signed in as a Guest. Connect your account to Google to enable secure encrypted cloud backups and sync across devices.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E333F) : Colors.white,
                              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF263238),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            icon: const Image(
                              image: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.png'),
                              height: 18,
                              width: 18,
                            ),
                            label: const Text('Connect with Google', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final error = await authProv.linkWithGoogle();
                              if (context.mounted) {
                                if (error == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Successfully connected to Google Account!')),
                                  );
                                  Navigator.pushReplacementNamed(context, '/profile/edit');
                                } else if (error != "Google sign in canceled by user") {
                                  _showGoogleSignInErrorDialog(context, error);
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // THEME & SECURITY CARD
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THEME & SECURITY',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Use midnight blue/teal theme for dark mode', style: TextStyle(fontSize: 12)),
                        secondary: Icon(
                          themeProv.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        value: themeProv.isDarkMode,
                        onChanged: (val) {
                          themeProv.toggleTheme();
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(height: 24),
                      SwitchListTile(
                        title: const Text('Biometric App Lock', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Protect app startup with biometrics (Face/Fingerprint)', style: TextStyle(fontSize: 12)),
                        secondary: Icon(
                          Icons.fingerprint,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        value: authProv.isBiometricEnabled,
                        onChanged: (val) {
                          authProv.setBiometricEnabled(val);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // GEMINI AI INTEGRATION CARD
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'GEMINI AI INTEGRATION',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.psychology, color: Colors.purple, size: 10),
                                SizedBox(width: 4),
                                Text(
                                  'GEMINI AI',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.purple),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter your Gemini API key to enable natural language transaction entry. Your key is stored securely on your local device.',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apiKeyController,
                        obscureText: _obscureApiKey,
                        decoration: InputDecoration(
                          labelText: 'Gemini API Key',
                          hintText: 'Enter your API key',
                          suffixIcon: IconButton(
                            icon: Icon(_obscureApiKey ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscureApiKey = !_obscureApiKey;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Get Gemini API Key'),
                                  content: const Text(
                                    '1. Go to Google AI Studio (aistudio.google.com)\n'
                                    '2. Sign in with your Google account.\n'
                                    '3. Click on "Get API Key" and create a new key.\n'
                                    '4. Copy the key and paste it here.',
                                    style: TextStyle(fontSize: 13, height: 1.5),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text(
                              'Get a free Gemini API Key',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final key = _apiKeyController.text.trim();
                            await authProv.setGeminiApiKey(key.isEmpty ? null : key);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gemini API Key saved successfully!')),
                              );
                            }
                          },
                          child: const Text('Save API Key', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. ENCRYPTED CLOUD BACKUP CARD
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'AES-256 CLOUD BACKUP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.security, color: Colors.green, size: 10),
                                SizedBox(width: 4),
                                Text(
                                  'AES SECURE',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your wallet databases are serialized, encrypted locally with AES-256 using your account key, and synchronized safely with Google Drive. Zero plaintext data is uploaded.',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Status row
                      Row(
                        children: [
                          Icon(
                            _hasBackup ? Icons.cloud_done : Icons.cloud_queue,
                            color: _hasBackup ? Colors.green : (Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _hasBackup ? 'Cloud Backup Found' : 'No Backup Found on Cloud',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _hasBackup ? Colors.green : (Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (authProv.backupKey != null) ...[
                        Text(
                          'BACKUP RECOVERY KEY',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E333F) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.key, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _obscureKey ? '••••-••••-••••-••••' : authProv.backupKey!,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _obscureKey = !_obscureKey;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: authProv.backupKey!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Recovery Key copied to clipboard!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Keep this key safe. You will need it to decrypt and restore your backups if you reinstall the app.',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (_syncing)
                        Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(strokeWidth: 3),
                              const SizedBox(height: 12),
                              Text(
                                'Syncing with Google Drive...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Backup button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: const Text('Backup Ledger to Cloud', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _triggerBackup(authProv, walletProv),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Restore button (only active if has backup)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _hasBackup
                                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.green[400] : Colors.green[700])
                                  : (Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey),
                              side: BorderSide(
                                color: _hasBackup
                                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.green[400]! : Colors.green[700]!)
                                    : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey[300]!),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.cloud_download_outlined),
                            label: const Text('Restore Ledger from Cloud', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: _hasBackup ? () => _triggerRestore(authProv, walletProv) : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (walletProv.archivedAccounts.isNotEmpty)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ARCHIVED ACCOUNTS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: walletProv.archivedAccounts.length,
                          itemBuilder: (context, i) {
                            final acc = walletProv.archivedAccounts[i];
                            Color accColor;
                            try {
                              accColor = Color(int.parse(acc.color));
                            } catch (_) {
                              accColor = Colors.grey;
                            }
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: accColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.archive, color: accColor, size: 18),
                              ),
                              title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(
                                'Balance: ${acc.balance} ${acc.currency}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_note, color: Colors.blue),
                                onPressed: () => Navigator.pushNamed(context, '/account/edit', arguments: acc),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _triggerBackup(AuthProvider authProv, WalletProvider walletProv) async {
    setState(() {
      _syncing = true;
    });

    try {
      // 1. Gather all rows from sqlite
      final payload = await walletProv.exportDatabaseAsJson();
      
      // 2. Encrypt & upload
      final error = await authProv.syncToCloud(payload);
      
      if (context.mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ledger backups securely encrypted and uploaded!')),
          );
          _checkBackupPresence(authProv);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sync failed: $error')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }

  Future<void> _promptForRecoveryKeyAndRestore(AuthProvider authProv, WalletProvider walletProv) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Backup Recovery Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A Backup Recovery Key is required to decrypt your cloud backup. Please enter your 16-character key (format: XXXX-YYYY-ZZZZ-WWWW):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Recovery Key',
                hintText: 'ABCD-EF12-34GH-56IJ',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              Navigator.pop(context);
              if (key.length != 19 && key.length != 16) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid key length. Must be 16 characters.')),
                );
                return;
              }
              await _executeRestore(authProv, walletProv, keyToUse: key);
            },
            child: const Text('Decrypt & Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeRestore(AuthProvider authProv, WalletProvider walletProv, {String? keyToUse}) async {
    setState(() {
      _syncing = true;
    });

    try {
      final payload = await authProv.restoreFromCloud(keyToUse: keyToUse);
      
      if (payload != null && context.mounted) {
        await walletProv.importDatabaseFromJson(payload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ledger completely restored and local databases updated!')),
        );
        _checkBackupPresence(authProv);
      } else if (context.mounted) {
        if (keyToUse == null) {
          _promptForRecoveryKeyAndRestore(authProv, walletProv);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Decryption failed. Please check your Backup Recovery Key.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }

  Future<void> _triggerRestore(AuthProvider authProv, WalletProvider walletProv) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Cloud Backups?'),
        content: const Text('WARNING: This replaces all current local ledger entries with the cloud backup snapshot. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _executeRestore(authProv, walletProv);
            },
            child: const Text('Confirm Restore'),
          ),
        ],
      ),
    );
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
              'TIP: You can toggle "OAuth Simulation Mode" in the login screen to simulate a successful sign-in without Firebase keys.',
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
}
