class DateFormatter {
  static const _months = [
    '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
  ];
  static const _fullMonths = [
    '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  static String formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  /// Alias for formatDate, used in share/export contexts.
  static String format(DateTime dt) => formatDate(dt);

  /// Short format: "15 Oca 14:30"
  static String formatShort(DateTime dt) =>
      '${dt.day} ${_months[dt.month]} ${formatTime(dt)}';

  static String formatDateTime(DateTime dt) =>
      '${formatDate(dt)} ${formatTime(dt)}';

  static String formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Bugün ${formatTime(dt)}';
    if (diff == 1) return 'Dün ${formatTime(dt)}';
    return '${dt.day} ${_months[dt.month]} ${formatTime(dt)}';
  }
}
