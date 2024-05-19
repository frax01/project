import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BirthdayPage extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
                return Card(
                  color: birthday['day'] == DateTime.now().day && birthday['month'] == DateTime.now().month ? Color.fromARGB(255, 231, 230, 230) : null,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${birthday['day']}',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _getMonthAbbreviation(birthday['month']),
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                        VerticalDivider(
                          width: 32,
                          thickness: 2,
                          color: Colors.black,
                        ),
                        Expanded(
                          child: Text(
                            '${birthday['name']} ${birthday['surname']}',
                            style: TextStyle(fontSize: 18),
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