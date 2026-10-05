/// Last selectable day for the date pickers.
///
/// It used to be `DateTime(DateTime.now().year + 1)`, i.e. 1 January of next
/// year, which made every later date impossible to pick (e.g. in October 2026
/// nothing after 1 January 2027). The result is always after [firstDate], so
/// `showDatePicker` never gets `lastDate < firstDate`.
DateTime datePickerLastDate({DateTime? now, DateTime? firstDate}) {
  final DateTime today = now ?? DateTime.now();
  final DateTime base =
      (firstDate != null && firstDate.isAfter(today)) ? firstDate : today;
  return DateTime(base.year + 5, 12, 31);
}
