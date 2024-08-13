import 'package:flutter/material.dart';

class Lunch extends StatefulWidget {
  const Lunch(
      {super.key,
      });

  @override
  State<Lunch> createState() => _LunchState();
}

class _LunchState extends State<Lunch> {

  String _getMonthAbbreviation(int month) {
    const months = [
      'GEN',
      'FEB',
      'MAR',
      'APR',
      'MAG',
      'GIU',
      'LUG',
      'AGO',
      'SET',
      'OTT',
      'NOV',
      'DIC'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height / 4,
        child: const Card(
        margin: EdgeInsets.symmetric(
            vertical: 8, horizontal: 16),
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lunedì',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '12 AGO',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'H 14:30',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  //Text(
                  //  '${birthday['day']}',
                  //  style: const TextStyle(
                  //      fontSize: 24,
                  //      fontWeight: FontWeight.bold),
                  //),
                  //Text(
                  //  _getMonthAbbreviation(birthday['month']),
                  //  style: const TextStyle(
                  //      fontSize: 18, color: Colors.grey),
                  //),
                ],
              ),
              const SizedBox(width: 20),
              VerticalDivider(
                color: Colors.grey,
                thickness: 2,
                width: 20,
                indent: 10,
                endIndent: 10,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.check_circle_outline),
                    Icon(Icons.cancel_outlined),
                    Icon(Icons.info_outline),
                  ],
                ),
              ),
            ],
          ),
        ),
      ))
    );
  }
}