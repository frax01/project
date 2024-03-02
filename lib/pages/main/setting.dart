import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/pages/main/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.id, required this.document});

  final String id;
  final Map document;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _emailController = TextEditingController();

  // Assuming you have a method to get the current user's email
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    getUserData().then((userData) {
      _nameController.text = userData['name'];
      _surnameController.text = userData['surname'];
      _birthdateController.text = userData['birthdate'];
      _emailController.text = userData['email'];
    });
    print("id: ${widget.id}");
  }

  Future<Map<String, dynamic>> getUserData() async {
    //print(_currentUser!.uid);
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('user')
        .doc(widget.id)
        .get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Future<void> updateUserData(Map<String, String> updatedData) async {
    await FirebaseFirestore.instance
        .collection('user')
        .doc(_currentUser!.uid)
        .update(updatedData);
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();

    Map<String, dynamic> allPrefs = prefs.getKeys().fold<Map<String, dynamic>>(
      {},
      (Map<String, dynamic> acc, String key) {
        acc[key] = prefs.get(key);
        return acc;
      },
    );

    print("SharedPreferences: $allPrefs");

    await FirebaseAuth.instance.signOut();
    setState(() {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const Login(title: 'Tiber Club')));
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var height = size.height;
    var width = size.width;
    return Scaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image(
                    image: const AssetImage('images/logo.png'),
                    width: width > 700 ? width / 4 : width / 8,
                    height: height / 4,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${widget.document['name']} ',
                          style: TextStyle(fontSize: width > 300 ? 18 : 14)),
                      Text('${widget.document['surname']}',
                          style: TextStyle(fontSize: width > 300 ? 18 : 14))
                    ],
                  ),
                ),
                Padding(
                    padding:
                        const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                    child: Text('${widget.document['club_class']}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: width > 500
                                ? 14
                                : width > 300
                                    ? 10
                                    : 8))),
                Padding(
                    padding:
                        const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                    child: Text('${widget.document['email']}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: width > 500
                                ? 14
                                : width > 300
                                    ? 10
                                    : 8))),
          ]),
            const SizedBox(height: 20.0),
            widget.document['status'] == 'Admin'
                ? ElevatedButton(
                    child: const Icon(
                      Icons.code,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/acceptance');
                    },
                  )
                : Container(),
            const SizedBox(height: 20.0),
            ElevatedButton(
              child: const Icon(
                Icons.logout,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Sei sicuro di uscire?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Yes'),
                          onPressed: () async {
                            await _logout();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Conferma'),
                      content: const Text(
                          'Sei sicuro di voler eliminare definitivamente il tuo account?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Annulla'),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                        TextButton(
                          child: const Text('Elimina'),
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                        ),
                      ],
                    );
                  },
                );
                if (confirm == true) {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    try {
                      QuerySnapshot querySnapshot = await FirebaseFirestore
                          .instance
                          .collection('user')
                          .where('email', isEqualTo: user.email)
                          .get();

                      if (querySnapshot.docs.isNotEmpty) {
                        DocumentSnapshot documentSnapshot =
                            querySnapshot.docs.first;
                        DocumentReference userDoc = documentSnapshot.reference;
                        // Ora puoi utilizzare userDoc per eliminare il documento
                        await userDoc.delete();
                      }
                      // Elimina il documento dell'utente
                      await user.delete();
                      // Dopo l'eliminazione dell'account, reindirizza l'utente alla pagina di login
                      Navigator.of(context).pushReplacementNamed('/login');
                    } catch (e) {
                      print('Errore durante l\'eliminazione dell\'account: $e');
                    }
                  }
                }
              },
              child: const Text('Elimina account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldWithUpdateButton(
      String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: label == 'Birthdate'
              ? _buildDateField(label, controller)
              : _buildTextField(label, controller),
        ),
        TextButton(
          child: const Text('Update'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              updateUserData({label.toLowerCase(): controller.text});
            }
          },
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter your $label',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
      ),
      readOnly: true,
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        final String birthdate = _birthdateController.text;
        final DateTime initialDate = birthdate.isEmpty
            ? DateTime.now()
            : DateTime.parse(
                '${birthdate.substring(6, 10)}-${birthdate.substring(3, 5)}-${birthdate.substring(0, 2)}');
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          _birthdateController.text = picked.toIso8601String();
        }
      },
    );
  }
}
