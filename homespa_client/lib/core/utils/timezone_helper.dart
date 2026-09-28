/// West Indonesia Time (WIB) = UTC+7.
/// All display, comparison, and day-boundary logic must go through this class.
class WIB {
  static const int offsetHours = 7;

  /// Convert any DateTime (UTC or local) to its WIB equivalent.
  static DateTime toWIB(DateTime dt) =>
      dt.toUtc().add(const Duration(hours: offsetHours));

  /// Current time expressed in WIB.
  static DateTime now() =>
      DateTime.now().toUtc().add(const Duration(hours: offsetHours));

  /// UTC DateTime for midnight WIB today (for use as Supabase lower bound).
  static DateTime startOfTodayUtc() {
    final w = now();
    // midnight WIB = DateTime.utc(y,m,d,0,0) shifted back 7 h
    return DateTime.utc(
      w.year,
      w.month,
      w.day,
    ).subtract(const Duration(hours: offsetHours));
  }

  /// UTC DateTime for midnight WIB tomorrow (for use as Supabase upper bound).
  static DateTime endOfTodayUtc() =>
      startOfTodayUtc().add(const Duration(days: 1));

  /// UTC instant for a WIB wall-clock time. Only the date/time fields of
  /// [wib] are read, so 17:00 WIB → 10:00 UTC.
  static DateTime wibToUtc(DateTime wib) => DateTime.utc(
    wib.year,
    wib.month,
    wib.day,
    wib.hour,
    wib.minute,
  ).subtract(const Duration(hours: offsetHours));

  /// UTC instant for midnight WIB on [wibDate]'s calendar day.
  static DateTime startOfDayUtc(DateTime wibDate) =>
      wibToUtc(DateTime.utc(wibDate.year, wibDate.month, wibDate.day));

  /// 'HH:mm' string in WIB from a UTC DateTime.
  static String formatTime(DateTime utcDt) {
    final w = toWIB(utcDt);
    return '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
  }

  /// 'd/M/yyyy' string in WIB from a UTC DateTime.
  static String formatDate(DateTime utcDt) {
    final w = toWIB(utcDt);
    return '${w.day}/${w.month}/${w.year}';
  }
}
