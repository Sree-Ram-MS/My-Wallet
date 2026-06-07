import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/planned_payment.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../utils/currency_helper.dart';
import '../../utils/date_helper.dart';
import '../navigation_drawer.dart';

class PlannedPaymentsScreen extends StatefulWidget {
  const PlannedPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PlannedPaymentsScreen> createState() => _PlannedPaymentsScreenState();
}

class _PlannedPaymentsScreenState extends State<PlannedPaymentsScreen> {
  // Let's implement State variables for adding planned payment
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedAccountId;
  String? _selectedCategoryId;
  String _frequency = 'recurring'; // 'one-time' | 'recurring'
  String _recurrence = 'monthly';  // 'daily' | 'weekly' | 'monthly' | 'yearly'
  String _endType = 'forever';     // 'forever' | 'until-date' | 'occurrences'
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = Provider.of<WalletProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final currency = authProv.defaultCurrency;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const CustomNavigationDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Text(
          'Planned Payments',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: walletProv.plannedPayments.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No planned payments scheduled.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Schedule future bills, rents, or subscriptions to trigger them easily in a single click.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: walletProv.plannedPayments.length,
              itemBuilder: (context, idx) {
                final payment = walletProv.plannedPayments[idx];
                
                final acc = walletProv.accounts.firstWhere(
                  (a) => a.id == payment.accountId,
                  orElse: () => Account(id: '', name: 'Account', currency: 'INR', color: '0xFF9E9E9E', balance: 0.0, isArchived: false, createdAt: DateTime.now()),
                );

                final cat = walletProv.categories.firstWhere(
                  (c) => c.id == payment.categoryId,
                  orElse: () => Category(id: '', name: 'Bills', color: '0xFFFFC107', icon: 'electrical_services', isArchived: false),
                );

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    payment.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A237E).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${payment.frequency.toUpperCase()} - ${payment.recurrence?.toUpperCase() ?? "ONCE"}',
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'From: ${acc.name}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyHelper.format(payment.amount, payment.currency),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFEF5350)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Next: ${DateHelper.formatShort(payment.startDate)}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            payment.notes!,
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF5350)),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Delete'),
                              onPressed: () => walletProv.deletePlannedPayment(payment.id),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.payment, size: 18),
                              label: const Text('Pay Now'),
                              onPressed: () async {
                                await walletProv.triggerPlannedPayment(payment);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Payment "${payment.name}" processed successfully!')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddDialog(context, walletProv, currency),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WalletProvider walletProv, String defaultCurrency) {
    if (walletProv.accounts.isEmpty) return;
    _selectedAccountId = walletProv.accounts.first.id;
    if (walletProv.categories.isNotEmpty) {
      _selectedCategoryId = walletProv.categories.first.id;
    }

    _nameController.clear();
    _amountController.clear();
    _notesController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                        'Add Planned Payment',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'Subscription / Bill Name e.g., Netflix'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'Amount'),
                              validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedAccountId,
                              items: walletProv.accounts.map((a) {
                                return DropdownMenuItem(value: a.id, child: Text(a.name));
                              }).toList(),
                              onChanged: (val) => setDialogState(() => _selectedAccountId = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              items: walletProv.categories.map((c) {
                                return DropdownMenuItem(value: c.id, child: Text(c.name));
                              }).toList(),
                              onChanged: (val) => setDialogState(() => _selectedCategoryId = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _frequency,
                              items: const [
                                DropdownMenuItem(value: 'one-time', child: Text('One-time')),
                                DropdownMenuItem(value: 'recurring', child: Text('Recurring')),
                              ],
                              onChanged: (val) => setDialogState(() {
                                if (val != null) _frequency = val;
                              }),
                            ),
                          ),
                        ],
                      ),
                      
                      if (_frequency == 'recurring') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _recurrence,
                          decoration: const InputDecoration(labelText: 'Recurrence Cycle'),
                          items: const [
                            DropdownMenuItem(value: 'daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                            DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                          ],
                          onChanged: (val) => setDialogState(() {
                            if (val != null) _recurrence = val;
                          }),
                        ),
                      ],
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(hintText: 'Notes / Description (Optional)'),
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
                              final planned = PlannedPayment(
                                id: uuid.v4(),
                                name: _nameController.text.trim(),
                                categoryId: _selectedCategoryId!,
                                accountId: _selectedAccountId!,
                                amount: double.parse(_amountController.text.trim()),
                                currency: defaultCurrency,
                                notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                                frequency: _frequency,
                                startDate: _startDate,
                                recurrence: _frequency == 'recurring' ? _recurrence : null,
                                endType: _endType,
                              );

                              await walletProv.addPlannedPayment(planned);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Planned payment scheduled!')),
                                );
                              }
                            }
                          },
                          child: const Text('Add Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
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
