import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/wallet_provider.dart';
import '../../models/debt.dart';
import '../../models/account.dart';
import '../../utils/currency_helper.dart';
import '../../utils/date_helper.dart';
import '../navigation_drawer.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({Key? key}) : super(key: key);

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _date = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

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

    final unpaidDebts = walletProv.debts.where((d) => !d.isPaid).toList();
    final paidDebts = walletProv.debts.where((d) => d.isPaid).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: const CustomNavigationDrawer(),
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          iconTheme: Theme.of(context).appBarTheme.iconTheme,
          title: Text(
            'Debts Ledger (I Lent)',
            style: TextStyle(
              color: Theme.of(context).appBarTheme.titleTextStyle?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Active (Unpaid)'),
              Tab(text: 'Recovered (Paid)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDebtList(unpaidDebts, walletProv, false),
            _buildDebtList(paidDebts, walletProv, true),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          onPressed: () => _showAddDebtSheet(context, walletProv),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildDebtList(List<Debt> list, WalletProvider walletProv, bool isPaid) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPaid ? Icons.assignment_turned_in_outlined : Icons.handshake_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                isPaid ? 'No settled debts.' : 'No active outstanding debts!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                isPaid 
                    ? 'Lent records you resolve will show up here as completed history.' 
                    : 'Log when you lend money to friends or colleagues. Balance deducts automatically.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final debt = list[idx];
        final acc = walletProv.accounts.firstWhere(
          (a) => a.id == debt.accountId,
          orElse: () => Account(id: '', name: 'Account', currency: 'INR', color: '0xFF9E9E9E', balance: 0.0, isArchived: false, createdAt: DateTime.now()),
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
                            debt.borrowerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lent on: ${DateHelper.formatShort(debt.date)} • Account: ${acc.name}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyHelper.format(debt.amount, 'INR'),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isPaid ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPaid ? 'RECOVERED' : 'DUE: ${DateHelper.formatShort(debt.dueDate)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? const Color(0xFF66BB6A) : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (debt.notes != null && debt.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    debt.notes!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
                if (!isPaid) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF66BB6A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Mark as Recovered'),
                        onPressed: () => _showRecoverySheet(context, walletProv, debt),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddDebtSheet(BuildContext context, WalletProvider walletProv) {
    if (walletProv.accounts.isEmpty) return;
    _selectedAccountId = walletProv.accounts.first.id;
    if (walletProv.categories.isNotEmpty) {
      _selectedCategoryId = walletProv.categories.first.id;
    }
    _nameController.clear();
    _amountController.clear();
    _notesController.clear();
    _date = DateTime.now();
    _dueDate = DateTime.now().add(const Duration(days: 30));

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
                        'Record Money Lent (Debt)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'Borrower Name e.g., Amit Sharma'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'Amount Lent'),
                              validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedAccountId,
                              decoration: const InputDecoration(labelText: 'Source Card'),
                              items: walletProv.accounts.map((a) {
                                return DropdownMenuItem(value: a.id, child: Text(a.name));
                              }).toList(),
                              onChanged: (val) => setDialogState(() => _selectedAccountId = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (walletProv.categories.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: walletProv.categories.map((c) {
                            return DropdownMenuItem(value: c.id, child: Text(c.name));
                          }).toList(),
                          onChanged: (val) => setDialogState(() => _selectedCategoryId = val),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Lent Date: ${DateHelper.formatShort(_date)}'),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  _date = picked;
                                });
                              }
                            },
                            child: const Text('Pick Date'),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Due Date: ${DateHelper.formatShort(_dueDate)}'),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _dueDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  _dueDate = picked;
                                });
                              }
                            },
                            child: const Text('Pick Date'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(hintText: 'Notes (Optional)'),
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
                              final String debtId = uuid.v4();
                              final String recId = uuid.v4();

                              final newDebt = Debt(
                                id: debtId,
                                borrowerName: _nameController.text.trim(),
                                accountId: _selectedAccountId!,
                                amount: double.parse(_amountController.text.trim()),
                                notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                                date: _date,
                                dueDate: _dueDate,
                                isPaid: false,
                                recordId: recId,
                              );

                              await walletProv.addDebt(newDebt, categoryId: _selectedCategoryId);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Debt logged and companion transaction posted.')),
                                );
                              }
                            }
                          },
                          child: const Text('Save Record', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showRecoverySheet(BuildContext context, WalletProvider walletProv, Debt debt) {
    String? recAccountId = walletProv.accounts.first.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recover Money Lent',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose the receiving account card where ${debt.borrowerName} paid back the sum of ${CurrencyHelper.format(debt.amount, 'INR')}.',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: recAccountId,
                    decoration: const InputDecoration(labelText: 'Receiving Account'),
                    items: walletProv.accounts.map((a) {
                      return DropdownMenuItem(value: a.id, child: Text(a.name));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => recAccountId = val),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (recAccountId != null) {
                          await walletProv.markDebtAsPaid(debt.id, recAccountId!);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Debt from ${debt.borrowerName} resolved! Account credited.')),
                            );
                          }
                        }
                      },
                      child: const Text('Confirm Payback', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
