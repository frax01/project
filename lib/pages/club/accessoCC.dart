import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:club/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccessoCC extends StatefulWidget {
  const AccessoCC({super.key, required this.email, required this.club});

  final String email;
  final String club;

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
          await _updateUser('staff');
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('cc',
              'yes'); //da qui bisogna fare che quando arriva una notifica del tuo club e tu la apri ti fa andare direttamente al club e non alla CC anche se hai cc nelle sharedPreferences
          await prefs.setString('ccRole', 'staff');
          await prefs.setString('nome', nome);
          await prefs.setString('club', newclub ?? '');
          restartApp(context, prefs.getString('club') ?? '',
              prefs.getString('cc') ?? '', 'staff', nome);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password errata'),
            ),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nome utente errato'),
          ),
        );
        return;
      }
    } else {
      if (enteredPassword == staffPassword) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('ccStaff')
            .doc(nome)
            .get();

        if (snapshot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esiste già un utente con questo nome'),
            ),
          );
          return;
        } else {
          await FirebaseFirestore.instance.collection('ccStaff').doc(nome).set({
            'nome': nome,
          });
          await _updateUser('staff');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password errata'),
          ),
        );
        return;
      }
    }
  }

  void _checkPasswordTutor(String role, String? newclub) async {
    String enteredPassword;
    print('newclub: $newclub');
    enteredPassword = tutorPasswordController.text;
    if (newclub == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci il tuo club'),
        ),
      );
      return;
    }
    if (enteredPassword == tutorPassword) {
      await _updateUser('tutor');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password errata'),
        ),
      );
      return;
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  bool _isObscure = false;

  InputDecoration getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelStyle: const TextStyle(color: Colors.black),
      suffixIcon: IconButton(
        icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
        onPressed: () {
          setState(() {
            _isObscure = !_isObscure;
          });
        },
      ),
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
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('ccPassword')
        .doc('password')
        .get();
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
                              floatingLabelStyle:
                                  TextStyle(color: Colors.black),
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
                  Column(children: [
                    if (oldclub == '') const SizedBox(height: 15),
                    TextField(
                      controller: tutorPasswordController,
                      decoration: getInputDecoration('Password tutor'),
                      obscureText: !_isObscure,
                      cursorColor: Colors.black54,
                    ),
                  ]),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _checkPasswordTutor(
                            'tutor', oldclub != '' ? oldclub : newclub),
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
                        cursorColor: Colors.black54,
                        controller: staffDataController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci nome e cognome';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Nome e cognome',
                          floatingLabelStyle: TextStyle(color: Colors.black),
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
                    obscureText: !_isObscure,
                    controller: staffPasswordController,
                    decoration: getInputDecoration('Password staff'),
                    cursorColor: Colors.black54,
                  ),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _checkPasswordStaff('staff',
                            widget.club, staffDataController.text, 'login'),
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
                        onPressed: () => _checkPasswordStaff(
                            'staff',
                            widget.club,
                            staffDataController.text,
                            'registrati'),
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
