import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/wallet_provider.dart';
import '../../models/credit.dart';
import '../../models/account.dart';
import '../../utils/currency_helper.dart';
import '../../utils/date_helper.dart';
import '../navigation_drawer.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({Key? key}) : super(key: key);

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
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

    final unpaidCredits = walletProv.credits.where((c) => !c.isPaid).toList();
    final paidCredits = walletProv.credits.where((c) => c.isPaid).toList();

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
            'Credits Ledger (I Borrowed)',
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
              Tab(text: 'Repaid (Settled)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCreditList(unpaidCredits, walletProv, false),
            _buildCreditList(paidCredits, walletProv, true),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          onPressed: () => _showAddCreditSheet(context, walletProv),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCreditList(List<Credit> list, WalletProvider walletProv, bool isPaid) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPaid ? Icons.assignment_turned_in_outlined : Icons.assignment_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                isPaid ? 'No settled credits.' : 'No active borrowed amounts!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                isPaid 
                    ? 'Credits you repay will show up here as completed history.' 
                    : 'Log when you borrow money from banks or friends. Balance credits automatically.',
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
        final credit = list[idx];
        final acc = walletProv.accounts.firstWhere(
          (a) => a.id == credit.accountId,
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
                            credit.lenderName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Borrowed on: ${DateHelper.formatShort(credit.date)} • Account: ${acc.name}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyHelper.format(credit.amount, 'INR'),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isPaid ? const Color(0xFFEF5350) : const Color(0xFF66BB6A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPaid ? 'REPAID' : 'DUE: ${DateHelper.formatShort(credit.dueDate)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? const Color(0xFFEF5350) : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (credit.notes != null && credit.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    credit.notes!,
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
                          backgroundColor: const Color(0xFFEF5350),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Repay Outstanding'),
                        onPressed: () => _showRepaySheet(context, walletProv, credit),
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

  void _showAddCreditSheet(BuildContext context, WalletProvider walletProv) {
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
                        'Record Money Borrowed (Credit)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'Lender Name e.g., SBI Bank, Friend'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'Amount Borrowed'),
                              validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedAccountId,
                              decoration: const InputDecoration(labelText: 'Deposit Card'),
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
                          Text('Borrowed Date: ${DateHelper.formatShort(_date)}'),
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
                              final String creditId = uuid.v4();
                              final String recId = uuid.v4();

                              final newCredit = Credit(
                                id: creditId,
                                lenderName: _nameController.text.trim(),
                                accountId: _selectedAccountId!,
                                amount: double.parse(_amountController.text.trim()),
                                notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                                date: _date,
                                dueDate: _dueDate,
                                isPaid: false,
                                recordId: recId,
                              );

                              await walletProv.addCredit(newCredit, categoryId: _selectedCategoryId);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Credit logged and companion transaction posted.')),
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

  void _showRepaySheet(BuildContext context, WalletProvider walletProv, Credit credit) {
    String? payAccountId = walletProv.accounts.first.id;

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
                    'Repay Outstanding Credit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose the payment account card to repay Ravi/SBI the sum of ${CurrencyHelper.format(credit.amount, 'INR')}.',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: payAccountId,
                    decoration: const InputDecoration(labelText: 'Paying Account'),
                    items: walletProv.accounts.map((a) {
                      return DropdownMenuItem(value: a.id, child: Text(a.name));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => payAccountId = val),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF5350),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (payAccountId != null) {
                          await walletProv.markCreditAsPaid(credit.id, payAccountId!);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Credit from ${credit.lenderName} repaid. Account debited.')),
                            );
                          }
                        }
                      },
                      child: const Text('Confirm Repayment', style: TextStyle(fontWeight: FontWeight.bold)),
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
