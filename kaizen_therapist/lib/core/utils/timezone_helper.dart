class WIB {
  static DateTime toWIB(DateTime utc) =>
      utc.toUtc().add(const Duration(hours: 7));

  static DateTime now() =>
      DateTime.now().toUtc().add(const Duration(hours: 7));

  /// Returns the UTC equivalent of midnight today in WIB.
  /// Pass this directly to .toIso8601String() — Supabase treats it as UTC.
  static DateTime startOfTodayUTC() {
    final wib = now();
    final start = DateTime(wib.year, wib.month, wib.day);
    return start.subtract(const Duration(hours: 7));
  }

  /// Returns the UTC equivalent of midnight tomorrow in WIB (= end of today WIB).
  static DateTime endOfTodayUTC() =>
      startOfTodayUTC().add(const Duration(days: 1));

  static String formatTime(DateTime utcTime) {
    final wib = toWIB(utcTime);
    return '${wib.hour.toString().padLeft(2, '0')}:${wib.minute.toString().padLeft(2, '0')}';
  }
}
