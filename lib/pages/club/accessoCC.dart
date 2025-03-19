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
  final staffDataController = TextEditingController();
  String tutorPassword = '';
  String staffPassword = '';

  void restartApp(BuildContext context, String club, String cc, String ccRole,
      String nome) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) =>
              MyApp(club: club, cc: cc, ccRole: ccRole, nome: nome)),
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

  void _checkPasswordStaff(
      String role, String? newclub, String nome, String mood) async {
    String enteredPassword = staffPasswordController.text;
    if (mood == 'login') {
      //QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('ccStaff').where('nome', isEqualTo: nome).get();
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('ccStaff')
          .doc(nome)
          .get();
      if (snapshot.exists) {
        if (enteredPassword == staffPassword) {
          _updateUser('staff');
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('cc',
              'yes'); //da qui bisogna fare che quando arriva una notifica del tuo club e tu la apri ti fa andare direttamente al club e non alla CC anche se hai cc nelle sharedPreferences
          await prefs.setString('ccRole', 'staff');
          await prefs.setString('nome', nome);
          await prefs.setString('club', newclub ?? '');
          restartApp(context, prefs.getString('club') ?? '',
              prefs.getString('cc') ?? '', 'staff', nome);
        } else {
          _showErrorDialog();
        }
      } else {
        _showErrorNomeDialog();
      }
    } else {
      if (enteredPassword == staffPassword) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('ccStaff')
            .doc(nome)
            .get();

        if (snapshot.exists) {
          _showErrorNomeEsistenteDialog();
        } else {
          await FirebaseFirestore.instance.collection('ccStaff').doc(nome).set({
            'nome': nome,
          });
          _updateUser('staff');
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('cc',
              'yes'); //da qui bisogna fare che quando arriva una notifica del tuo club e tu la apri ti fa andare direttamente al club e non alla CC anche se hai cc nelle sharedPreferences
          await prefs.setString('ccRole', 'staff');
          await prefs.setString('nome', nome);
          await prefs.setString('club', newclub ?? '');
          restartApp(context, prefs.getString('club') ?? '',
              prefs.getString('cc') ?? '', 'staff', nome);
        }
      } else {
        _showErrorDialog();
      }
    }
  }

  void _checkPasswordTutor(String role, String? newclub) async {
    String enteredPassword;
    print('newclub: $newclub');
    enteredPassword = tutorPasswordController.text;
    if (enteredPassword == tutorPassword) {
      _updateUser('tutor');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cc',
          'yes'); //da qui bisogna fare che quando arriva una notifica del tuo club e tu la apri ti fa andare direttamente al club e non alla CC anche se hai cc nelle sharedPreferences
      await prefs.setString('ccRole', 'tutor');
      await prefs.setString('club', newclub ?? '');
      restartApp(
          context,
          newclub != '' ? newclub ?? '' : prefs.getString('club') ?? '',
          prefs.getString('cc') ?? '',
          'tutor',
          '');
    } else {
      _showErrorDialog();
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

  void _showErrorNomeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Errore'),
        content: const Text('Nome errato. Riprova.'),
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

  void _showErrorNomeEsistenteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Errore'),
        content: const Text('Nome già inserito. Riprova.'),
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

  InputDecoration getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black54),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black54),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 25, 84, 132)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _retrieveClubs();
    _retrievePw();
  }

  Future<void> _retrievePw() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('ccPassword').doc('password').get();
    if (snapshot.exists) {
      setState(() {
        staffPassword = snapshot['staffPw'];
        tutorPassword = snapshot['tutorPw'];
      });
    }
  }

  List<dynamic> clubs = [''];

  Future<void> _retrieveClubs() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('ccSquadre').get();
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
        backgroundColor: const Color(0xFF00296B),
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
                        prefs.getString('cc') ?? '', 'user', '');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showUserPasswordField
                        ? const Color.fromARGB(255, 39, 132, 207)
                        : const Color(0xFF00296B),
                  ),
                  child: const Text('Entra come utente'),
                ),
              )
            ]),
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
                        ? const Color.fromARGB(255, 39, 132, 207)
                        : const Color(0xFF00296B),
                  ),
                  child: const Text('Entra come tutor'),
                ),
              )
            ]),
            if (showTutorPasswordField)
              Column(
                children: [
                  const SizedBox(height: 15),
                  if (oldclub == '')
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Expanded(
                        //child: Center(
                        child: DropdownButtonFormField<String>(
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
                            decoration: const InputDecoration(
                              labelText: 'Club',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black54),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black54),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 39, 132, 207)),
                              ),
                            )),
                      ) //)
                    ]),
                  const SizedBox(height: 15),
                  TextField(
                    controller: tutorPasswordController,
                    decoration: getInputDecoration('Password tutor'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _checkPasswordTutor('tutor', newclub),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 39, 132, 207),
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
                        ? const Color.fromARGB(255, 39, 132, 207)
                        : const Color(0xFF00296B),
                  ),
                  child: const Text('Entra come staff'),
                ),
              )
            ]),
            if (showStaffPasswordField)
              Column(
                children: [
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        textCapitalization: TextCapitalization.sentences,
                        controller: staffDataController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci nome e cognome';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Nome e cognome',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 39, 132, 207)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 15),
                  TextField(
                    controller: staffPasswordController,
                    decoration: getInputDecoration('Password staff'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _checkPasswordStaff(
                            'staff', '', staffDataController.text, 'login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 39, 132, 207),
                        ),
                        child: const Text('Login'),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _checkPasswordStaff('staff', '',
                            staffDataController.text, 'registrati'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 39, 132, 207),
                        ),
                        child: const Text('Registrati'),
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
