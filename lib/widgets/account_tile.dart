import 'package:flutter/material.dart';
import '../models/account.dart';
import '../utils/currency_helper.dart';

class AccountTile extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;

  const AccountTile({
    Key? key,
    required this.account,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert hex color string to Color object
    Color cardColor;
    try {
      cardColor = Color(int.parse(account.color));
    } catch (_) {
      cardColor = const Color(0xFF2196F3);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cardColor,
              cardColor.withBlue((cardColor.blue + 30).clamp(0, 255)).withGreen((cardColor.green + 20).clamp(0, 255)),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.35),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    account.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  account.isArchived ? Icons.archive : Icons.account_balance_wallet,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT BALANCE',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyHelper.format(account.balance, account.currency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (account.accountNumber != null && account.accountNumber!.isNotEmpty)
              Text(
                '•••• •••• ${account.accountNumber!.length > 4 ? account.accountNumber!.substring(account.accountNumber!.length - 4) : account.accountNumber}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              )
            else
              const Text(
                '•••• •••• ••••',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontFamily: 'Courier',
                  letterSpacing: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
