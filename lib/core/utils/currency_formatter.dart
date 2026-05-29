import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  static String format(double amount) => _formatter.format(amount);

  static String formatShort(double amount) {
    if (amount >= 1000) {
      return '₺${(amount / 1000).toStringAsFixed(1)}B';
    }
    return '₺${amount.toStringAsFixed(0)}';
  }
}
