import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/currency_helper.dart';
import '../../widgets/account_tile.dart';
import '../../widgets/transaction_item.dart';
import '../../widgets/donut_chart.dart';
import '../../widgets/line_graph.dart';
import '../../widgets/ai_quick_entry_sheet.dart';
import '../navigation_drawer.dart';
import '../../models/account.dart';
import '../../models/category.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Automatically load all local records when home screen starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = Provider.of<WalletProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final currency = authProv.defaultCurrency;

    // 1. Calculate Summary Metrics
    double totalBalance = 0.0;
    for (var acc in walletProv.accounts) {
      totalBalance += acc.balance;
    }

    final now = DateTime.now();
    double monthlyIncome = 0.0;
    double monthlyExpense = 0.0;

    for (var r in walletProv.records) {
      if (r.dateTime.year == now.year && r.dateTime.month == now.month) {
        if (r.type == 'income') {
          monthlyIncome += r.amount;
        } else if (r.type == 'expense') {
          monthlyExpense += r.amount;
        }
      }
    }

    double netSavings = monthlyIncome - monthlyExpense;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const CustomNavigationDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Row(
          children: [
            Image.asset('assets/images/app_logo.png', height: 26, width: 26),
            const SizedBox(width: 8),
            Text(
              'My Wallet',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.titleTextStyle?.color,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology, color: Colors.purpleAccent),
            tooltip: 'AI Assistant Entry',
            onPressed: () {
              if (authProv.geminiApiKey == null || authProv.geminiApiKey!.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Gemini API Key Needed'),
                    content: const Text(
                      'To use AI Quick Entry, please configure your Gemini API Key in Settings first.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/profile/edit');
                        },
                        child: const Text('Go to Settings'),
                      ),
                    ],
                  ),
                );
              } else {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  builder: (context) => const AiQuickEntrySheet(),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.blue),
            onPressed: () async {
              await walletProv.loadAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Balances refreshed successfully!')),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                authProv.user?.name.isNotEmpty == true ? authProv.user!.name[0].toUpperCase() : 'G',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: walletProv.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => walletProv.loadAllData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // 1. DYNAMIC HEADER CARD (GLASSMORPHISM PANEL)
                    // ==========================================
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A237E).withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NET WALLET BALANCE',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyHelper.format(totalBalance, currency),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 16),
                          // Row showing Income vs Expense vs Savings
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetricItem(
                                title: 'Monthly Inflow',
                                amount: monthlyIncome,
                                currency: currency,
                                color: const Color(0xFF66BB6A),
                                icon: Icons.arrow_upward,
                              ),
                              _buildMetricItem(
                                title: 'Monthly Outflow',
                                amount: monthlyExpense,
                                currency: currency,
                                color: const Color(0xFFEF5350),
                                icon: Icons.arrow_downward,
                              ),
                              _buildMetricItem(
                                title: 'Savings',
                                amount: netSavings,
                                currency: currency,
                                color: netSavings >= 0 ? Colors.cyanAccent : Colors.orangeAccent,
                                icon: Icons.savings_outlined,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ==========================================
                    // 2. ACCOUNTS CAROUSEL
                    // ==========================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Accounts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF263238),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/accounts'),
                            child: const Text('Manage', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 180,
                      child: walletProv.accounts.isEmpty
                          ? GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/account/add'),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_card, color: Colors.blue, size: 36),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Create your first account',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: walletProv.accounts.length + 1,
                              itemBuilder: (context, idx) {
                                if (idx < walletProv.accounts.length) {
                                  final acc = walletProv.accounts[idx];
                                  return SizedBox(
                                    width: 280,
                                    child: AccountTile(
                                      account: acc,
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/account/edit',
                                        arguments: acc,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Shortcut to add account card
                                  return GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/account/add'),
                                    child: Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(left: 8, right: 16, top: 6, bottom: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.02),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary, size: 30),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Add Card',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                    ),
                    const SizedBox(height: 16),

                    // ==========================================
                    // 3. TABBED CHARTS SECTION
                    // ==========================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.transparent,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : const Color(0xFF37474F),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tabs: const [
                            Tab(text: 'Categories'),
                            Tab(text: 'Historical'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 290,
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: DonutChart(
                              records: walletProv.records,
                              categories: walletProv.categories,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: LineGraph(
                              records: walletProv.records,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ==========================================
                    // 4. RECENT TRANSACTIONS
                    // ==========================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF263238),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/records'),
                            child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    
                    walletProv.records.isEmpty
                        ? Container(
                            height: 120,
                            alignment: Alignment.center,
                            child: Text(
                              'No transactions registered yet.',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: walletProv.records.length > 5 ? 5 : walletProv.records.length,
                            itemBuilder: (context, idx) {
                              final rec = walletProv.records[idx];
                              // Fetch Category & Account details
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
                    const SizedBox(height: 80), // FAB spacing
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.pushNamed(context, '/record/add'),
      ),
    );
  }

  Widget _buildMetricItem({
    required String title,
    required double amount,
    required String currency,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyHelper.format(amount, currency),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
