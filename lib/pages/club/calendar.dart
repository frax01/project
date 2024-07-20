import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Calendar extends StatefulWidget {
  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            body: TableCalendar(
              focusedDay: DateTime.now(),
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2025, 12, 31),
              calendarFormat: CalendarFormat.month,
            )));
  }
}