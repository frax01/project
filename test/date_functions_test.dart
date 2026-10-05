import 'package:club/functions/dateFunctions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('datePickerLastDate', () {
    test('lets users pick dates well past the next 1 January', () {
      final now = DateTime(2026, 10, 5);
      final last = datePickerLastDate(now: now, firstDate: now);

      // Regression: it used to be DateTime(now.year + 1) == 2027-01-01.
      expect(last.isAfter(DateTime(2027, 12, 31)), isTrue);
      // The club calendar goes up to 2030-12-31; pickers must reach it too.
      expect(last.isBefore(DateTime(2030, 12, 31)), isFalse);
    });

    test('is never before firstDate (trip end date picked after a far start)',
        () {
      final now = DateTime(2026, 10, 5);
      final firstDate = DateTime(2030, 12, 31).add(const Duration(days: 1));
      final last = datePickerLastDate(now: now, firstDate: firstDate);

      expect(last.isBefore(firstDate), isFalse);
    });
  });

  group('showDatePicker with datePickerLastDate', () {
    Future<DateTime?> openAndPick(
      WidgetTester tester, {
      required DateTime now,
      required DateTime initialDate,
      required int monthsForward,
      required String day,
    }) async {
      DateTime? picked;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: initialDate,
                lastDate: datePickerLastDate(now: now, firstDate: initialDate),
              );
            },
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      for (var i = 0; i < monthsForward; i++) {
        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(day));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      return picked;
    }

    testWidgets('program date: 15 January 2027 can be selected',
        (tester) async {
      final now = DateTime(2026, 10, 5);
      final picked = await openAndPick(
        tester,
        now: now,
        initialDate: now,
        monthsForward: 3, // Oct -> Nov -> Dec -> Jan
        day: '15',
      );

      expect(tester.takeException(), isNull);
      expect(picked, DateTime(2027, 1, 15));
    });

    testWidgets(
        'trip end date: start 15 January 2027 opens the picker and allows 20 January',
        (tester) async {
      final now = DateTime(2026, 10, 5);
      final picked = await openAndPick(
        tester,
        now: now,
        initialDate: DateTime(2027, 1, 16), // start (15/01) + 1 day
        monthsForward: 0,
        day: '20',
      );

      expect(tester.takeException(), isNull);
      expect(picked, DateTime(2027, 1, 20));
    });
  });
}
