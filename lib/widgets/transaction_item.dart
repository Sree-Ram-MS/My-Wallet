import 'package:flutter/material.dart';
import '../models/record.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../utils/currency_helper.dart';
import '../utils/date_helper.dart';

class TransactionItem extends StatelessWidget {
  final Record record;
  final Category? category;
  final Account? account;
  final Account? toAccount; // If transfer
  final Function(Record)? onDelete;
  final VoidCallback? onTap;

  const TransactionItem({
    Key? key,
    required this.record,
    this.category,
    this.account,
    this.toAccount,
    this.onDelete,
    this.onTap,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final isExpense = record.type == 'expense';
    final isIncome = record.type == 'income';
    final isTransfer = record.type == 'transfer';

    Color amtColor = isExpense
        ? const Color(0xFFEF5350) // Red
        : isIncome 
            ? const Color(0xFF66BB6A) // Green
            : const Color(0xFF42A5F5); // Blue (Transfer)

    String amtSign = isExpense ? '-' : (isIncome ? '+' : '');

    // Resolve Category Theme
    Color categoryColor;
    IconData categoryIcon;
    try {
      categoryColor = category != null ? Color(int.parse(category!.color)) : const Color(0xFF9E9E9E);
    } catch (_) {
      categoryColor = const Color(0xFF9E9E9E);
    }
    categoryIcon = _getIconData(category?.icon ?? 'category');

    Widget itemTile = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isTransfer 
                ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E333F) : const Color(0xFFE3F2FD)) 
                : categoryColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isTransfer ? Icons.swap_horiz : categoryIcon,
            color: isTransfer ? const Color(0xFF2196F3) : categoryColor,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isTransfer 
                    ? 'Transfer' 
                    : (category?.name ?? 'Uncategorized'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF263238),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$amtSign${CurrencyHelper.format(record.amount, record.currency)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: amtColor,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isTransfer
                      ? 'From: ${account?.name ?? "..."} ➔ To: ${toAccount?.name ?? "..."}'
                      : (record.note?.isNotEmpty == true ? record.note! : 'No notes added'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateHelper.formatRelative(record.dateTime),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white30 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onDelete == null) {
      return itemTile;
    }

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 26,
        ),
      ),
      onDismissed: (_) {
        onDelete!(record);
      },
      child: itemTile,
    );
  }
}
