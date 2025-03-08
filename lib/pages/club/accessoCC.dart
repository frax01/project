import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:club/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccessoCC extends StatefulWidget {
  const AccessoCC({super.key, required this.email});

  final String email;

  @override
  _AccessoCCState createState() => _AccessoCCState();
}

class _AccessoCCState extends State<AccessoCC> {
  bool showUserPasswordField = false;
  bool showTutorPasswordField = false;
  bool showStaffPasswordField = false;
  final userPasswordController = TextEditingController();
  final tutorPasswordController = TextEditingController();
  final staffPasswordController = TextEditingController();
  final String userPassword = 'utenteCC';
  final String tutorPassword = 'tutorCC';
  final String staffPassword = 'staffCC';

  void restartApp(BuildContext context, String club, String cc, String ccRole) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => MyApp(
                club: club,
                cc: cc,
                ccRole: ccRole,
              )),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _updateUser(String role) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('email', isEqualTo: widget.email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('user')
            .doc(doc.id)
            .update({'ccRole': role});
      }
    }
  }

  void _checkPassword(String role, String? newclub) async {
    String enteredPassword;
    //if (role == 'user') {
    //  enteredPassword = userPasswordController.text;
    //  if (enteredPassword == userPassword) {
    //    _updateUser('user');
    //    final SharedPreferences prefs = await SharedPreferences.getInstance();
    //    await prefs.setString('cc', 'yes'); //da qui bisogna fare che quando arriva una notifica del tuo club e tu la apri ti fa andare direttamente al club e non alla CC anche se hai cc nelle sharedPreferences
    //    await prefs.setString('ccRole', 'user');
    //    restartApp(context, prefs.getString('club') ?? '', prefs.getString('cc') ?? '', 'user');
    //  } else {
    //    _showErrorDialog();
    //  }
    //} else
    if (role == 'tutor') {
      print('newclub: $newclub');
      enteredPassword = tutorPasswordController.text;
      if (enteredPassword == tutorPassword) {
        _updateUser('tutor');
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('cc',
            'yes'); //da qui bisogna fare che quando arriva una notifica del tuo club e tu la apri ti fa andare direttamente al club e non alla CC anche se hai cc nelle sharedPreferences
        await prefs.setString('ccRole', 'tutor');
        restartApp(context, newclub!='' ? newclub ?? '' : prefs.getString('club') ?? '',
            prefs.getString('cc') ?? '', 'tutor');
      } else {
        _showErrorDialog();
      }
    } else if (role == 'staff') {
      enteredPassword = staffPasswordController.text;
      if (enteredPassword == staffPassword) {
        _updateUser('staff');
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('cc',
            'yes'); //da qui bisogna fare che quando arriva una notifica del tuo club e tu la apri ti fa andare direttamente al club e non alla CC anche se hai cc nelle sharedPreferences
        await prefs.setString('ccRole', 'staff');
        restartApp(context, prefs.getString('club') ?? '',
            prefs.getString('cc') ?? '', 'staff');
      } else {
        _showErrorDialog();
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Errore'),
        content: const Text('Password errata. Riprova.'),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _retrieveClubs();
  }

  List<dynamic> clubs = [''];

  Future<void> _retrieveClubs() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('ccSquadre').get();
    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        clubs.add(doc['club']);
      }
    }
    setState(() {});
  }

  String oldclub = '';
  String newclub = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Champions Club'),
      ),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      showUserPasswordField = !showUserPasswordField;
                      showTutorPasswordField = false;
                      showStaffPasswordField = false;
                    });
                    widget.email != '' ? _updateUser('user') : null;
                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setString('cc',
                        'yes'); //da qui bisogna fare che quando arriva una notifica del tuo club e tu la apri ti fa andare direttamente al club e non alla CC anche se hai cc nelle sharedPreferences
                    await prefs.setString('ccRole', 'user');
                    restartApp(context, prefs.getString('club') ?? '',
                        prefs.getString('cc') ?? '', 'user');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showUserPasswordField
                        ? const Color.fromARGB(255, 25, 84, 132)
                        : null,
                  ),
                  child: const Text('Entra come utente'),
                ),
              )
            ]),
            //if (showUserPasswordField)
            //  Column(
            //    children: [
            //      const SizedBox(height: 15),
            //      TextField(
            //        controller: userPasswordController,
            //        decoration:
            //            const InputDecoration(labelText: 'Password Utente'),
            //        obscureText: true,
            //      ),
            //      const SizedBox(height: 15),
            //      Row(children: [
            //        Expanded(
            //          child: ElevatedButton(
            //            onPressed: () => _checkPassword('user'),
            //            style: ElevatedButton.styleFrom(
            //              backgroundColor:
            //                  const Color.fromARGB(255, 25, 84, 132),
            //            ),
            //            child: const Text('Entra'),
            //          ),
            //        )
            //      ]),
            //    ],
            //  ),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    setState(() {
                      showUserPasswordField = false;
                      showTutorPasswordField = !showTutorPasswordField;
                      showStaffPasswordField = false;
                      oldclub = prefs.getString('club') ?? '';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showTutorPasswordField
                        ? const Color.fromARGB(255, 25, 84, 132)
                        : null,
                  ),
                  child: const Text('Entra come tutor'),
                ),
              )
            ]),
            if (showTutorPasswordField)
              Column(
                children: [
                  if (oldclub == '')
                    Row(children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: clubs.isEmpty ? null : newclub,
                          hint: const Text('Seleziona club'),
                          items: clubs.map((dynamic value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              newclub = newValue!;
                            });
                          },
                        ),
                      )
                    ]),
                  const SizedBox(height: 15),
                  TextField(
                    controller: tutorPasswordController,
                    decoration:
                        const InputDecoration(labelText: 'Password Tutor'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _checkPassword('tutor', newclub),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 25, 84, 132),
                        ),
                        child: const Text('Entra'),
                      ),
                    )
                  ]),
                ],
              ),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showUserPasswordField = false;
                      showTutorPasswordField = false;
                      showStaffPasswordField = !showStaffPasswordField;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showStaffPasswordField
                        ? const Color.fromARGB(255, 25, 84, 132)
                        : null,
                  ),
                  child: const Text('Entra come staff'),
                ),
              )
            ]),
            if (showStaffPasswordField)
              Column(
                children: [
                  const SizedBox(height: 15),
                  TextField(
                    controller: staffPasswordController,
                    decoration:
                        const InputDecoration(labelText: 'Password Staff'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _checkPassword('staff', ''),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 25, 84, 132),
                        ),
                        child: const Text('Entra'),
                      ),
                    )
                  ]),
                ],
              ),
          ],
        ),
      )),
    );
  }
}

class CCHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CC Home Page'),
      ),
      body: Center(
        child: Text('Benvenuto nella CC Home Page!'),
      ),
    );
  }
}
