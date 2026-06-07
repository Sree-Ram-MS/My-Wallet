import 'package:intl/intl.dart';

class CurrencyHelper {
  /// Formats currency based on regional conventions (e.g. en_IN for INR with lakhs/crores formatting)
  static String format(double amount, String currencyCode) {
    try {
      final code = currencyCode.toUpperCase();
      final isINR = code == 'INR';
      final symbol = isINR ? '₹' : (code == 'USD' ? '\$' : (code == 'EUR' ? '€' : (code == 'GBP' ? '£' : '$code ')));
      
      final formatter = NumberFormat.currency(
        locale: isINR ? 'en_IN' : 'en_US',
        symbol: symbol,
        decimalDigits: 2,
      );
      
      return formatter.format(amount);
    } catch (e) {
      return "${currencyCode.toUpperCase()} ${amount.toStringAsFixed(2)}";
    }
  }

  /// Gets the standard currency symbol
  static String getSymbol(String currencyCode) {
    final code = currencyCode.toUpperCase();
    if (code == 'INR') return '₹';
    if (code == 'USD') return '\$';
    if (code == 'EUR') return '€';
    if (code == 'GBP') return '£';
    return code;
  }
}
