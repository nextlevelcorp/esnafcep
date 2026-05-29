import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime dt) =>
      DateFormat('dd.MM.yyyy', 'tr_TR').format(dt);

  static String formatDateTime(DateTime dt) =>
      DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(dt);

  static String formatTime(DateTime dt) =>
      DateFormat('HH:mm', 'tr_TR').format(dt);

  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Bugün ${formatTime(dt)}';
    if (diff.inDays == 1) return 'Dün ${formatTime(dt)}';
    return formatDate(dt);
  }
}
