import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/account_tile.dart';

class ManageAccountsScreen extends StatelessWidget {
  const ManageAccountsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final walletProv = Provider.of<WalletProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Cards'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: walletProv.accounts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card_off_outlined,
                      size: 64,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white30
                          : Colors.black26,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Active Cards Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a card using the button below to start managing your accounts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              itemCount: walletProv.accounts.length,
              itemBuilder: (context, idx) {
                final acc = walletProv.accounts[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    height: 170,
                    child: AccountTile(
                      account: acc,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/account/edit',
                        arguments: acc,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/account/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add New Card', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
