import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/account.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({Key? key}) : super(key: key);

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _balanceController = TextEditingController();

  String _selectedCurrency = 'INR';
  String _selectedColor = '0xFF1A237E'; // Midnight Blue default

  // High-fidelity pre-curated premium colors
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
  void initState() {
    super.initState();
    // Default currency from auth preference
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    _selectedCurrency = authProv.defaultCurrency;
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
    final walletProv = Provider.of<WalletProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Text(
          'Add Account',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon representation card
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

                // Account Name Field
                _buildSectionTitle('Account Details'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _getInputDecoration('Account Name e.g., HDFC Bank, Cash Wallet', Icons.credit_card),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a valid account name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Account Number Field
                TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  decoration: _getInputDecoration('Account Number (Optional)', Icons.pin),
                ),
                const SizedBox(height: 16),

                // Starting Balance & Currency
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _getInputDecoration('Starting Balance', Icons.account_balance),
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
                const SizedBox(height: 28),

                // Premium Palette Color Picker
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
                        final uuid = const Uuid();
                        final newAccount = Account(
                          id: uuid.v4(),
                          name: _nameController.text.trim(),
                          accountNumber: _numberController.text.trim().isEmpty ? null : _numberController.text.trim(),
                          currency: _selectedCurrency,
                          color: _selectedColor,
                          balance: double.parse(_balanceController.text.trim()),
                          isArchived: false,
                          createdAt: DateTime.now(),
                        );

                        await walletProv.addAccount(newAccount);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account added successfully!')),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: const Text('Save Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
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
