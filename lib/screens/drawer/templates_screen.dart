import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/wallet_provider.dart';
import '../../models/template.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../navigation_drawer.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({Key? key}) : super(key: key);

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedType = 'expense';
  String? _selectedAccountId;
  String? _selectedCategoryId;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = Provider.of<WalletProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const CustomNavigationDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Text(
          'Quick Templates',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: walletProv.templates.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.copy_all_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No transaction templates created.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Build quick shortcuts for frequent expenses (like Coffee or Uber) or repeating income streams.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: walletProv.templates.length,
              itemBuilder: (context, idx) {
                final temp = walletProv.templates[idx];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: temp.type == 'expense'
                            ? const Color(0xFFEF5350).withOpacity(0.12)
                            : temp.type == 'income'
                                ? const Color(0xFF66BB6A).withOpacity(0.12)
                                : const Color(0xFF42A5F5).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        temp.type == 'expense'
                            ? Icons.arrow_downward
                            : temp.type == 'income'
                                ? Icons.arrow_upward
                                : Icons.swap_horiz,
                        color: temp.type == 'expense'
                            ? const Color(0xFFEF5350)
                            : temp.type == 'income'
                                ? const Color(0xFF66BB6A)
                                : const Color(0xFF42A5F5),
                        size: 20,
                      ),
                    ),
                    title: Text(temp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${temp.type.toUpperCase()}${temp.amount != null ? " • ₹${temp.amount}" : ""}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF5350)),
                      onPressed: () => walletProv.deleteTemplate(temp.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddSheet(context, walletProv),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WalletProvider walletProv) {
    if (walletProv.accounts.isNotEmpty) {
      _selectedAccountId = walletProv.accounts.first.id;
    }
    if (walletProv.categories.isNotEmpty) {
      _selectedCategoryId = walletProv.categories.first.id;
    }

    _nameController.clear();
    _amountController.clear();
    _noteController.clear();
    _selectedType = 'expense';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isTransfer = _selectedType == 'transfer';
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Quick Template',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'Template Name e.g., Starbucks Coffee'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter template name' : null,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(labelText: 'Transaction Type'),
                        items: const [
                          DropdownMenuItem(value: 'expense', child: Text('Expense')),
                          DropdownMenuItem(value: 'income', child: Text('Income')),
                          DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                        ],
                        onChanged: (val) => setDialogState(() {
                          if (val != null) _selectedType = val;
                        }),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'Prefilled Amount (Optional)'),
                            ),
                          ),
                          if (walletProv.accounts.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedAccountId,
                                decoration: const InputDecoration(labelText: 'Default Card'),
                                items: walletProv.accounts.map((a) {
                                  return DropdownMenuItem(value: a.id, child: Text(a.name));
                                }).toList(),
                                onChanged: (val) => setDialogState(() => _selectedAccountId = val),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      if (!isTransfer && walletProv.categories.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(labelText: 'Default Category'),
                          items: walletProv.categories.map((c) {
                            return DropdownMenuItem(value: c.id, child: Text(c.name));
                          }).toList(),
                          onChanged: (val) => setDialogState(() => _selectedCategoryId = val),
                        ),
                      ],
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(hintText: 'Prefilled Note / Tag (Optional)'),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final uuid = const Uuid();
                              
                              final amtVal = double.tryParse(_amountController.text.trim());

                              final newTemp = Template(
                                id: uuid.v4(),
                                name: _nameController.text.trim(),
                                type: _selectedType,
                                amount: amtVal,
                                accountId: _selectedAccountId,
                                categoryId: isTransfer ? null : _selectedCategoryId,
                                note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                              );

                              await walletProv.addTemplate(newTemp);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Template shortcut created!')),
                                );
                              }
                            }
                          },
                          child: const Text('Add Template', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
