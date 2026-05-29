class CurrencyFormatter {
  static String format(double amount) {
    final isNegative = amount < 0;
    final abs = amount.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    // Add thousands separator
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }

    return '${isNegative ? "-" : ""}₺${buffer.toString()},$decPart';
  }

  static String formatShort(double amount) {
    if (amount >= 1000) {
      return '₺${(amount / 1000).toStringAsFixed(1)}B';
    }
    return '₺${amount.toStringAsFixed(0)}';
  }
}
