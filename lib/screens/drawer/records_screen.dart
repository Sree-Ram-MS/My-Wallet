import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/transaction_item.dart';
import '../navigation_drawer.dart';
import '../../models/record.dart';
import '../../models/category.dart';
import '../../models/account.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({Key? key}) : super(key: key);

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String _searchQuery = '';
  String _selectedType = 'all'; // 'all' | 'expense' | 'income' | 'transfer'
  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedDateFilter = 'all'; // 'all' | 'today' | 'week' | 'month' | 'year' | 'custom'

  String get _selectedDateFilterLabel {
    switch (_selectedDateFilter) {
      case 'all': return 'All Time';
      case 'today': return 'Today';
      case 'week': return 'This Week';
      case 'month': return 'This Month';
      case 'year': return 'This Year';
      case 'custom':
        if (_startDate != null && _endDate != null) {
          return '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}';
        }
        return 'Custom';
      default: return 'All Time';
    }
  }

  void _applyDateFilter(String type) {
    final now = DateTime.now();
    switch (type) {
      case 'all':
        _startDate = null;
        _endDate = null;
        break;
      case 'today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'week':
        final weekday = now.weekday;
        final start = now.subtract(Duration(days: weekday - 1));
        _startDate = DateTime(start.year, start.month, start.day);
        final end = start.add(const Duration(days: 6));
        _endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        _endDate = DateTime(now.year, now.month, lastDay, 23, 59, 59);
        break;
      case 'year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = Provider.of<WalletProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);

    // 1. Process Filtering & Searching
    final filteredRecords = walletProv.records.where((rec) {
      // Search note query match
      final noteMatch = rec.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      
      // Category name query match
      String catName = '';
      if (rec.categoryId != null) {
        final match = walletProv.categories.where((c) => c.id == rec.categoryId);
        if (match.isNotEmpty) catName = match.first.name;
      }
      final catMatch = catName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesSearch = _searchQuery.isEmpty || noteMatch || catMatch || rec.type.contains(_searchQuery.toLowerCase());

      // Type filter match
      final matchesType = _selectedType == 'all' || rec.type == _selectedType;

      // Account filter match
      final matchesAccount = _selectedAccountId == null || 
          rec.accountId == _selectedAccountId || 
          rec.fromAccountId == _selectedAccountId || 
          rec.toAccountId == _selectedAccountId;

      // Category filter match
      final matchesCategory = _selectedCategoryId == null || rec.categoryId == _selectedCategoryId;

      // Date range filter match
      bool matchesDate = true;
      if (_startDate != null) {
        matchesDate = matchesDate && rec.dateTime.isAfter(_startDate!.subtract(const Duration(seconds: 1)));
      }
      if (_endDate != null) {
        matchesDate = matchesDate && rec.dateTime.isBefore(_endDate!.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesType && matchesAccount && matchesCategory && matchesDate;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const CustomNavigationDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Text(
          'Transactions Ledger',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedAccountId != null || _selectedCategoryId != null || _selectedType != 'all' || _startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.orange),
              onPressed: () {
                setState(() {
                  _selectedType = 'all';
                  _selectedAccountId = null;
                  _selectedCategoryId = null;
                  _startDate = null;
                  _endDate = null;
                  _selectedDateFilter = 'all';
                });
              },
              tooltip: 'Clear Filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Box Bar
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by notes, category or type...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E333F) : const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // 2. Interactive Quick Horizontal Filters
          Container(
            height: 52,
            color: Theme.of(context).cardColor,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                // Date Filter Selector
                _buildQuickFilterDropdown<String>(
                  hint: 'Date: $_selectedDateFilterLabel',
                  value: _selectedDateFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Time')),
                    DropdownMenuItem(value: 'today', child: Text('Today')),
                    DropdownMenuItem(value: 'week', child: Text('This Week')),
                    DropdownMenuItem(value: 'month', child: Text('This Month')),
                    DropdownMenuItem(value: 'year', child: Text('This Year')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom Range...')),
                  ],
                  onChanged: (val) async {
                    if (val == 'custom') {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDateRange: _startDate != null && _endDate != null
                            ? DateTimeRange(start: _startDate!, end: _endDate!)
                            : null,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDateFilter = 'custom';
                          _startDate = picked.start;
                          _endDate = picked.end;
                        });
                      }
                    } else {
                      setState(() {
                        _selectedDateFilter = val;
                        _applyDateFilter(val);
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                // Type Filter Selector
                _buildQuickFilterDropdown<String>(
                  hint: 'Type: ${_selectedType.toUpperCase()}',
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Types')),
                    DropdownMenuItem(value: 'expense', child: Text('Expenses')),
                    DropdownMenuItem(value: 'income', child: Text('Incomes')),
                    DropdownMenuItem(value: 'transfer', child: Text('Transfers')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
                const SizedBox(width: 8),

                // Account Filter Selector
                _buildQuickFilterDropdown<String?>(
                  hint: _selectedAccountId == null 
                      ? 'Select Account' 
                      : 'Account: ${walletProv.accounts.firstWhere((a) => a.id == _selectedAccountId).name}',
                  value: _selectedAccountId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Accounts')),
                    ...walletProv.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                  ],
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                ),
                const SizedBox(width: 8),

                // Category Filter Selector
                _buildQuickFilterDropdown<String?>(
                  hint: _selectedCategoryId == null 
                      ? 'Select Category' 
                      : 'Category: ${walletProv.categories.firstWhere((c) => c.id == _selectedCategoryId).name}',
                  value: _selectedCategoryId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Categories')),
                    ...walletProv.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 3. Transactions List
          Expanded(
            child: filteredRecords.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No records found matching filters.',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try clearing active search terms or toggling type and account dropdown selections.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, idx) {
                      final rec = filteredRecords[idx];
                      
                      final cat = walletProv.categories.firstWhere(
                        (c) => c.id == rec.categoryId,
                        orElse: () => Category(id: '', name: 'Uncategorized', color: '0xFF9E9E9E', icon: 'category', isArchived: false),
                      );
                      final acc = walletProv.accounts.firstWhere(
                        (a) => a.id == rec.accountId,
                        orElse: () => Account(id: '', name: 'Account', currency: 'INR', color: '0xFF9E9E9E', balance: 0.0, isArchived: false, createdAt: DateTime.now()),
                      );
                      final toAcc = rec.toAccountId != null
                          ? walletProv.accounts.firstWhere(
                              (a) => a.id == rec.toAccountId,
                              orElse: () => Account(id: '', name: 'Target Account', currency: 'INR', color: '0xFF9E9E9E', balance: 0.0, isArchived: false, createdAt: DateTime.now()),
                            )
                          : null;

                      return TransactionItem(
                        record: rec,
                        category: cat,
                        account: acc,
                        toAccount: toAcc,
                        onDelete: (r) {
                          walletProv.deleteRecord(r);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaction deleted.')),
                          );
                        },
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/record/edit',
                          arguments: rec,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterDropdown<T>({
    required String hint,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E333F) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: isDark ? const Color(0xFF1E333F) : Colors.white,
          style: TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : const Color(0xFF37474F),
          ),
          items: items,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}
