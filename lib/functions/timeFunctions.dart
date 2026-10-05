import 'package:flutter/material.dart';

/// "HH:mm" (24-hour, two digits), independent of the device clock setting.
/// `TimeOfDay.format(context)` gives "2:30 PM" on 12-hour devices, which the
/// meal list could not parse.
String formatTimeHHmm(TimeOfDay time) {
  final String hh = time.hour.toString().padLeft(2, '0');
  final String mm = time.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

final RegExp _timePattern =
    RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$');

/// Minutes since midnight for "14:30", "9:05" or "2:30 PM"; null if the text
/// is not a valid time.
int? parseTimeToMinutes(String? text) {
  final Match? match = _timePattern.firstMatch((text ?? '').trim());
  if (match == null) return null;
  int hour = int.parse(match.group(1)!);
  final int minute = int.parse(match.group(2)!);
  final String? period = match.group(3)?.toLowerCase();
  if (minute > 59) return null;
  if (period != null) {
    if (hour < 1 || hour > 12) return null;
    hour = hour % 12 + (period == 'pm' ? 12 : 0);
  } else if (hour > 23) {
    return null;
  }
  return hour * 60 + minute;
}
