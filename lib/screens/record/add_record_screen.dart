import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/record.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/template.dart';
import '../../utils/date_helper.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({Key? key}) : super(key: key);

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TabController _typeTabController;
  
  String _selectedType = 'expense'; // 'expense' | 'income' | 'transfer'
  String? _selectedAccountId;
  String? _selectedFromAccountId; // Only if transfer
  String? _selectedToAccountId;   // Only if transfer
  String? _selectedCategoryId;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _typeTabController = TabController(length: 3, vsync: this);
    _typeTabController.addListener(_handleTabSelection);

    // Default account & category IDs
    final walletProv = Provider.of<WalletProvider>(context, listen: false);
    if (walletProv.accounts.isNotEmpty) {
      _selectedAccountId = walletProv.accounts.first.id;
      _selectedFromAccountId = walletProv.accounts.first.id;
      if (walletProv.accounts.length > 1) {
        _selectedToAccountId = walletProv.accounts[1].id;
      } else {
        _selectedToAccountId = walletProv.accounts.first.id;
      }
    }
    if (walletProv.categories.isNotEmpty) {
      _selectedCategoryId = walletProv.categories.first.id;
    }
  }

  void _handleTabSelection() {
    if (_typeTabController.indexIsChanging) return;
    setState(() {
      if (_typeTabController.index == 0) {
        _selectedType = 'expense';
      } else if (_typeTabController.index == 1) {
        _selectedType = 'income';
      } else {
        _selectedType = 'transfer';
      }
    });
  }

  @override
  void dispose() {
    _typeTabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Auto-populates transaction details from templates
  void _applyTemplate(Template temp) {
    setState(() {
      _selectedType = temp.type;
      if (temp.type == 'expense') {
        _typeTabController.index = 0;
      } else if (temp.type == 'income') {
        _typeTabController.index = 1;
      } else {
        _typeTabController.index = 2;
      }
      
      if (temp.amount != null) {
        _amountController.text = temp.amount.toString();
      }
      if (temp.accountId != null) {
        _selectedAccountId = temp.accountId;
        _selectedFromAccountId = temp.accountId;
      }
      if (temp.categoryId != null) {
        _selectedCategoryId = temp.categoryId;
      }
      if (temp.note != null) {
        _noteController.text = temp.note!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = Provider.of<WalletProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final currency = authProv.defaultCurrency;

    if (walletProv.accounts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Transaction')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_card, size: 64, color: Colors.blueGrey),
                const SizedBox(height: 16),
                const Text(
                  'No accounts found!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You must create at least one account card before registering standard financial records.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/account/add'),
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isTransfer = _selectedType == 'transfer';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Text(
          'Add Transaction',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (walletProv.templates.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_all_outlined, color: Colors.blue),
              onPressed: () => _showTemplatesSelector(context, walletProv),
              tooltip: 'Apply Template',
            ),
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
                // 1. Double/Triple Sliding Segmented TabBar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _typeTabController,
                    indicatorColor: Colors.transparent,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF37474F),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: _selectedType == 'expense'
                          ? const Color(0xFFEF5350)
                          : _selectedType == 'income'
                              ? const Color(0xFF66BB6A)
                              : const Color(0xFF42A5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tabs: const [
                      Tab(text: 'Expense'),
                      Tab(text: 'Income'),
                      Tab(text: 'Transfer'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Amount Entry
                _buildSectionTitle('Transaction Amount'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      padding: const EdgeInsets.only(left: 18, right: 12),
                      child: Text(
                        currency == 'INR' ? '₹' : '\$',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.blueGrey,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter amount';
                    final numVal = double.tryParse(val);
                    if (numVal == null || numVal <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 3. Dynamic Account Dropdowns
                if (!isTransfer) ...[
                  _buildSectionTitle('Select Account'),
                  const SizedBox(height: 8),
                  _buildAccountDropdown(
                    value: _selectedAccountId,
                    accounts: walletProv.accounts,
                    onChanged: (val) => setState(() => _selectedAccountId = val),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('From Account'),
                            const SizedBox(height: 8),
                            _buildAccountDropdown(
                              value: _selectedFromAccountId,
                              accounts: walletProv.accounts,
                              onChanged: (val) => setState(() => _selectedFromAccountId = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('To Account'),
                            const SizedBox(height: 8),
                            _buildAccountDropdown(
                              value: _selectedToAccountId,
                              accounts: walletProv.accounts,
                              onChanged: (val) => setState(() => _selectedToAccountId = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                // 4. Category Selector (Only for Income and Expense)
                if (!isTransfer) ...[
                  _buildSectionTitle('Category'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showCategorySheet(context, walletProv),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.grid_view, color: Theme.of(context).colorScheme.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedCategoryId == null
                                    ? 'Select Category'
                                    : walletProv.categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => Category(id: '', name: 'Select Category', color: '0xFF9E9E9E', icon: 'category', isArchived: false)).name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF263238),
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 5. Date & Time Selection
                _buildSectionTitle('Date & Time'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _pickDateTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.blueGrey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${DateHelper.formatShort(_selectedDateTime)} • ${DateHelper.formatTime(_selectedDateTime)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF263238),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.edit,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Notes Field
                _buildSectionTitle('Note / Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add description, notes, tags...',
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                ),
                const SizedBox(height: 48),

                // Save button
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
                        final String recordId = uuid.v4();

                        // Balance validations for transfer
                        if (isTransfer && _selectedFromAccountId == _selectedToAccountId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Source and Destination accounts cannot be the same!')),
                          );
                          return;
                        }

                        final Record newRecord = Record(
                          id: recordId,
                          type: _selectedType,
                          amount: double.parse(_amountController.text.trim()),
                          currency: currency,
                          accountId: isTransfer ? _selectedFromAccountId! : _selectedAccountId!,
                          fromAccountId: isTransfer ? _selectedFromAccountId : null,
                          toAccountId: isTransfer ? _selectedToAccountId : null,
                          categoryId: isTransfer ? null : _selectedCategoryId,
                          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                          dateTime: _selectedDateTime,
                          createdAt: DateTime.now(),
                        );

                        await walletProv.addRecord(newRecord);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaction saved successfully!')),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF37474F),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildAccountDropdown({
    required String? value,
    required List<Account> accounts,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: accounts.map((acc) {
        return DropdownMenuItem(
          value: acc.id,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: Color(int.parse(acc.color)), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  void _showCategorySheet(BuildContext context, WalletProvider walletProv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: walletProv.categories.length,
                  itemBuilder: (context, idx) {
                    final cat = walletProv.categories[idx];
                    final isSelected = _selectedCategoryId == cat.id;

                    Color catColor;
                    try {
                      catColor = Color(int.parse(cat.color));
                    } catch (_) {
                      catColor = Colors.grey;
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = cat.id;
                        });
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? catColor : catColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconData(cat.icon),
                              color: isSelected ? Colors.white : catColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF37474F),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTemplatesSelector(BuildContext context, WalletProvider walletProv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply Template',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: walletProv.templates.length,
                  itemBuilder: (context, idx) {
                    final temp = walletProv.templates[idx];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: temp.type == 'expense' 
                                ? const Color(0xFFEF5350).withOpacity(0.15) 
                                : const Color(0xFF66BB6A).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            temp.type == 'expense' ? Icons.arrow_downward : Icons.arrow_upward,
                            color: temp.type == 'expense' ? const Color(0xFFEF5350) : const Color(0xFF66BB6A),
                            size: 18,
                          ),
                        ),
                        title: Text(temp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${temp.type.toUpperCase()}${temp.amount != null ? " • ₹${temp.amount}" : ""}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          _applyTemplate(temp);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    if (context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (pickedTime == null) return;

      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'restaurant': return Icons.restaurant;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'directions_car': return Icons.directions_car;
      case 'sports_esports': return Icons.sports_esports;
      case 'electrical_services': return Icons.electrical_services;
      case 'monetization_on': return Icons.monetization_on;
      case 'category': return Icons.category;
      case 'work': return Icons.work;
      case 'flight': return Icons.flight;
      case 'medical_services': return Icons.medical_services;
      case 'school': return Icons.school;
      case 'fitness_center': return Icons.fitness_center;
      default: return Icons.category;
    }
  }
}
