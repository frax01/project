import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';

class BirthdayPage extends StatefulWidget {
  @override
  _BirthdayPageState createState() => _BirthdayPageState();
}

class _BirthdayPageState extends State<BirthdayPage> {

  Future<List<Map<String, dynamic>>> _fetchBirthdays() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('role', whereIn: ['Ragazzo', 'Tutor'])
        .get();

    List<QueryDocumentSnapshot> docs = querySnapshot.docs;

    List<Map<String, dynamic>> futureBirthdays = [];
    List<Map<String, dynamic>> pastBirthdays = [];

    DateTime now = DateTime.now();

    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<String> dateParts = (data['birthdate'] as String).split('-');
      DateTime birthdayDate = DateTime(now.year, int.parse(dateParts[1]), int.parse(dateParts[0]));
      DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
      if (birthdayDate.isAfter(yesterday)) {
        futureBirthdays.add({
          'name': data['name'],
          'surname': data['surname'],
          'day': int.parse(dateParts[0]),
          'month': int.parse(dateParts[1]),
          'year': int.parse(dateParts[2]),
        });
      } else {
        pastBirthdays.add({
          'name': data['name'],
          'surname': data['surname'],
          'day': int.parse(dateParts[0]),
          'month': int.parse(dateParts[1]),
          'year': int.parse(dateParts[2]),
        });
      }
    }

    futureBirthdays.sort((a, b) {
      DateTime birthdayA = DateTime(now.year, a['month'], a['day']);
      DateTime birthdayB = DateTime(now.year, b['month'], b['day']);
      Duration differenceA = birthdayA.difference(now);
      Duration differenceB = birthdayB.difference(now);
      return differenceA.compareTo(differenceB);
    });

    pastBirthdays.sort((a, b) {
      DateTime birthdayA = DateTime(now.year, a['month'], a['day']);
      DateTime birthdayB = DateTime(now.year, b['month'], b['day']);
      return birthdayA.compareTo(birthdayB);
    });

    List<Map<String, dynamic>> allBirthdays = [];
    allBirthdays.addAll(futureBirthdays);
    allBirthdays.addAll(pastBirthdays);

    return allBirthdays;
  }

  String _getMonthAbbreviation(int month) {
    const months = ['GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU', 'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'];
    return months[month - 1];
  }

  Future<void> _startConfettiIfTodayBirthday() async {
    final List<Map<String, dynamic>> birthdays = await _fetchBirthdays();
    final DateTime now = DateTime.now();

    for (var birthday in birthdays) {
      if (birthday['day'] == now.day && birthday['month'] == now.month) {
        _confettiController.play();
        break;
      }
    }
  }

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startConfettiIfTodayBirthday();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchBirthdays(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Errore: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Non ci sono compleanni'));
            } else {
              List<Map<String, dynamic>> birthdays = snapshot.data!;
              return ListView.builder(
                itemCount: birthdays.length,
                itemBuilder: (context, index) {
                  var birthday = birthdays[index];
                  bool isToday = birthday['day'] == DateTime.now().day && birthday['month'] == DateTime.now().month;
                  bool isTomorrow = ((birthday['day'] == DateTime.now().add(Duration(days: 1)).day &&
                    birthday['month'] == DateTime.now().month)) ||
                    (birthday['day'] == 1 && birthday['month'] == DateTime.now().month + 1 && DateTime(DateTime.now().year, DateTime.now().month + 1, 0)==DateTime.now().day);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${birthday['day']}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _getMonthAbbreviation(birthday['month']),
                                style: const TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${birthday['name']} ${birthday['surname']}',
                                    style: const TextStyle(fontSize: 17),
                                  ),
                                ),
                                if (isToday)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          'images/birthday_cake.png',
                                          width: 24,
                                          height: 24,
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'oggi',
                                          style: TextStyle(fontSize: 16, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ),

                                if (isTomorrow)
                                  Column(
                                    children: [
                                      Image.asset(
                                        'images/hourglass.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'domani',
                                        style: TextStyle(fontSize: 16, color: Colors.black),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0.0, -1.25),
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.9,
              shouldLoop: false,
              numberOfParticles: 10,
              gravity: 0.2,
              colors: const [Colors.yellow, Colors.orange, Colors.red, Colors.green, Colors.blue],
            ),
          ),
        ),
      ],
    ),
  );
}

}

Future<List<Map<String, dynamic>>> _fetchBirthdays() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('role', whereIn: ['Ragazzo', 'Tutor'])
        .get();

    List<QueryDocumentSnapshot> docs = querySnapshot.docs;

    List<Map<String, dynamic>> futureBirthdays = [];
    List<Map<String, dynamic>> pastBirthdays = [];

    DateTime now = DateTime.now();

    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<String> dateParts = (data['birthdate'] as String).split('-');
      DateTime birthdayDate = DateTime(now.year, int.parse(dateParts[1]), int.parse(dateParts[0]));
      DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
      if (birthdayDate.isAfter(yesterday)) {
        futureBirthdays.add({
          'name': data['name'],
          'surname': data['surname'],
          'day': int.parse(dateParts[0]),
          'month': int.parse(dateParts[1]),
          'year': int.parse(dateParts[2]),
        });
      } else {
        pastBirthdays.add({
          'name': data['name'],
          'surname': data['surname'],
          'day': int.parse(dateParts[0]),
          'month': int.parse(dateParts[1]),
          'year': int.parse(dateParts[2]),
        });
      }
    }

    futureBirthdays.sort((a, b) {
      DateTime birthdayA = DateTime(now.year, a['month'], a['day']);
      DateTime birthdayB = DateTime(now.year, b['month'], b['day']);
      Duration differenceA = birthdayA.difference(now);
      Duration differenceB = birthdayB.difference(now);
      return differenceA.compareTo(differenceB);
    });

    pastBirthdays.sort((a, b) {
      DateTime birthdayA = DateTime(now.year, a['month'], a['day']);
      DateTime birthdayB = DateTime(now.year, b['month'], b['day']);
      return birthdayA.compareTo(birthdayB);
    });

    List<Map<String, dynamic>> allBirthdays = [];
    allBirthdays.addAll(futureBirthdays);
    allBirthdays.addAll(pastBirthdays);

    return allBirthdays;
  }