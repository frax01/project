import 'package:club/functions/timeFunctions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatTimeHHmm', () {
    test('always 24-hour with two digits (regression: 12h devices)', () {
      expect(formatTimeHHmm(const TimeOfDay(hour: 14, minute: 30)), '14:30');
      expect(formatTimeHHmm(const TimeOfDay(hour: 9, minute: 5)), '09:05');
      expect(formatTimeHHmm(const TimeOfDay(hour: 0, minute: 0)), '00:00');
    });
  });

  group('parseTimeToMinutes', () {
    test('24-hour values', () {
      expect(parseTimeToMinutes('14:30'), 870);
      expect(parseTimeToMinutes('9:05'), 545);
      expect(parseTimeToMinutes('00:00'), 0);
      expect(parseTimeToMinutes(' 23:59 '), 1439);
    });

    test('12-hour values written by devices with a 12h clock', () {
      expect(parseTimeToMinutes('2:30 PM'), 870);
      expect(parseTimeToMinutes('2:30 pm'), 870);
      expect(parseTimeToMinutes('12:00 AM'), 0);
      expect(parseTimeToMinutes('12:15 PM'), 735);
      expect(parseTimeToMinutes('9:05 AM'), 545);
    });

    test('invalid values give null instead of throwing', () {
      expect(parseTimeToMinutes(''), isNull);
      expect(parseTimeToMinutes('abc'), isNull);
      expect(parseTimeToMinutes('25:00'), isNull);
      expect(parseTimeToMinutes('10:75'), isNull);
      expect(parseTimeToMinutes(null), isNull);
    });
  });
}
