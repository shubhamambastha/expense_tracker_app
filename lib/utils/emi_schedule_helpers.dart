/// Helpers for EMI tenure ↔ recurrence end date on the Add Transaction screen.
class EmiScheduleHelpers {
  EmiScheduleHelpers._();

  /// Total months between [start] and [end] (inclusive of start month).
  static int tenureMonthsFromDates({
    required DateTime start,
    required DateTime end,
  }) {
    final months =
        (end.year - start.year) * 12 + (end.month - start.month) + 1;
    return months.clamp(1, 999);
  }

  /// End date for an EMI that runs [tenureMonths] from [startDate].
  static DateTime endDateFromTenure({
    required DateTime startDate,
    required int tenureMonths,
  }) {
    final months = tenureMonths.clamp(1, 999);
    final year = startDate.year + (startDate.month - 1 + months - 1) ~/ 12;
    final month = (startDate.month - 1 + months - 1) % 12 + 1;
    final day = startDate.day;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay));
  }

  /// Approximate installments remaining from today until [endDate].
  static int remainingInstallments({
    required DateTime endDate,
    DateTime? from,
  }) {
    final now = from ?? DateTime.now();
    if (!endDate.isAfter(now)) return 0;

    final months =
        (endDate.year - now.year) * 12 + (endDate.month - now.month);
    return months.clamp(0, 999);
  }
}
