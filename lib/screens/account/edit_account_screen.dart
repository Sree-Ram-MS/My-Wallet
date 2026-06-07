import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/account.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({Key? key}) : super(key: key);

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _balanceController;

  String _selectedCurrency = 'INR';
  String _selectedColor = '0xFF1A237E';
  
  Account? _account;
  bool _initialized = false;

  final List<Map<String, String>> _colors = const [
    {'name': 'Indigo', 'value': '0xFF1A237E'},
    {'name': 'Emerald', 'value': '0xFF009688'},
    {'name': 'Crimson', 'value': '0xFFC62828'},
    {'name': 'Ocean Blue', 'value': '0xFF0277BD'},
    {'name': 'Forest Green', 'value': '0xFF2E7D32'},
    {'name': 'Grape', 'value': '0xFF6A1B9A'},
    {'name': 'Pumpkin', 'value': '0xFFD84315'},
    {'name': 'Rose Gold', 'value': '0xFFAD1457'},
    {'name': 'Slate Grey', 'value': '0xFF37474F'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _account = ModalRoute.of(context)!.settings.arguments as Account;
      _nameController = TextEditingController(text: _account!.name);
      _numberController = TextEditingController(text: _account!.accountNumber ?? '');
      _balanceController = TextEditingController(text: _account!.balance.toString());
      _selectedCurrency = _account!.currency;
      _selectedColor = _account!.color;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_account == null) {
      return const Scaffold(body: Center(child: Text("Loading account data...")));
    }

    final walletProv = Provider.of<WalletProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Text(
          'Edit Account',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_account!.isArchived) ...[
            IconButton(
              icon: const Icon(Icons.unarchive_outlined, color: Colors.green),
              onPressed: () async {
                await walletProv.unarchiveAccount(_account!.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Account "${_account!.name}" unarchived.')),
                  );
                }
              },
              tooltip: 'Unarchive Account',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context, walletProv),
              tooltip: 'Delete Account',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.archive_outlined, color: Colors.orange),
              onPressed: () => _confirmArchive(context, walletProv),
              tooltip: 'Archive Account',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Color(int.parse(_selectedColor)).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 48,
                      color: Color(int.parse(_selectedColor)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                _buildSectionTitle('Account Details'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _getInputDecoration('Account Name', Icons.credit_card),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter an account name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  decoration: _getInputDecoration('Account Number (Optional)', Icons.pin),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _getInputDecoration('Current Balance', Icons.account_balance),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter balance';
                          }
                          if (double.tryParse(val) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                          DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                          DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCurrency = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Warning note about editing balance manually
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Modifying balance directly creates a ledger offset without transaction logs.',
                        style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                _buildSectionTitle('Choose Card Accent Color'),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _colors.length,
                  itemBuilder: (context, idx) {
                    final colorData = _colors[idx];
                    final String hexStr = colorData['value']!;
                    final Color color = Color(int.parse(hexStr));
                    final isSelected = _selectedColor == hexStr;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = hexStr;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                                : Colors.transparent,
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final updatedAccount = _account!.copyWith(
                          name: _nameController.text.trim(),
                          accountNumber: _numberController.text.trim().isEmpty ? null : _numberController.text.trim(),
                          currency: _selectedCurrency,
                          color: _selectedColor,
                          balance: double.parse(_balanceController.text.trim()),
                        );

                        await walletProv.updateAccount(updatedAccount);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account updated successfully!')),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmArchive(BuildContext context, WalletProvider walletProv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Account?'),
        content: Text('Are you sure you want to archive "${_account!.name}"? It will be hidden from the active dashboard, but transaction logs remain intact.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              await walletProv.archiveAccount(_account!.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return home
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Account "${_account!.name}" archived.')),
                );
              }
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WalletProvider walletProv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Text('Are you sure you want to completely delete "${_account!.name}"? This will wipe the card and all associated transactions from your records. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await walletProv.deleteAccount(_account!.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return home
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Account "${_account!.name}" completely deleted.')),
                );
              }
            },
            child: const Text('Delete Completely'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF37474F),
        letterSpacing: 0.8,
      ),
    );
  }

  InputDecoration _getInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }
}
