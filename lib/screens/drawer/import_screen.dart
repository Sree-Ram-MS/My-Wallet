import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/import_service.dart';
import '../navigation_drawer.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({Key? key}) : super(key: key);

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _csvController = TextEditingController();

  // Pre-seed a valid CSV template to let the user immediately test it in one click!
  final String _sampleCSV = 
      "date,type,amount,currency,account,category,note,fromAccount,toAccount\n"
      "2026-06-02,expense,450.00,INR,Cash Wallet,Food & Dining,Premium Dinner,,\n"
      "2026-06-02,income,45000.00,INR,HDFC Bank,Salary & Income,Monthly Paycheck,,\n"
      "2026-06-02,transfer,5000.00,INR,HDFC Bank,,ATM Withdrawal,HDFC Bank,Cash Wallet";

  @override
  void initState() {
    super.initState();
    _csvController.text = _sampleCSV;
  }

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = Provider.of<WalletProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const CustomNavigationDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Text(
          'Import CSV/Excel',
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
              // Info panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CSV Batch Importing Engine',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'This tool parses standard CSV lines. If the specified accounts or categories do not exist, they will be created automatically in your local SQLite wallet.',
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF37474F), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Format Header Rules
              Text(
                'Required CSV Columns Format:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF37474F)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.withOpacity(0.2)),
                ),
                child: const Text(
                  'date,type,amount,currency,account,category,note,fromAccount,toAccount',
                  style: TextStyle(fontFamily: 'Courier', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ),
              const SizedBox(height: 24),

              // Paste field
              Text(
                'Paste Comma-Separated Values (CSV) Below:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF37474F)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _csvController,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'date,type,amount,currency,account,category,note...',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Parse and Import Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () async {
                    final csvText = _csvController.text.trim();
                    if (csvText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter or paste CSV records.')),
                      );
                      return;
                    }

                    try {
                      // 1. Parse using service
                      final List<Map<String, dynamic>> parsedList = 
                          ImportService.instance.parseCSV(csvText);

                      if (parsedList.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to parse any valid records. Check headers.')),
                        );
                        return;
                      }

                      // 2. Insert into sqlite
                      await walletProv.importParsedRecords(parsedList);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Successfully imported ${parsedList.length} transactions!')),
                        );
                        Navigator.pushReplacementNamed(context, '/home');
                      }

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Import failed: $e')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              
              // Reset sample shortcut
              Center(
                child: TextButton(
                  onPressed: () => _csvController.text = _sampleCSV,
                  child: const Text('Reset to Sample CSV Template'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
