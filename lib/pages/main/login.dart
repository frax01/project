import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/pages/club/club.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../functions/dataFunctions.dart';
import 'waiting.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loginFailed = false;

  List classes = [];
  bool status = false;
  String id = '';
  String name = '';
  String surname = '';
  String email = '';
  String role = '';

  Widget buildClubPage() {
    return ClubPage(
      classes: classes,
      status: status,
      id: id,
      name: name,
      surname: surname,
      email: email,
    );
  }

  _goToWaiting() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const Waiting()));
  }

  _goToHome() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => buildClubPage()
        )
    );
  }

  _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        var credentials = await _auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        email = credentials.user?.email ?? '';
        var store = FirebaseFirestore.instance.collection('user');
        var user = await store.where('email', isEqualTo: email).get();

        DocumentSnapshot userDoc = user.docs.first;
        List<dynamic> tokens = userDoc["token"];
        try {
          String? token = await FirebaseMessaging.instance.getToken();
          assert(token != null);
          if (user.docs.isNotEmpty) {
            if (!tokens.contains(token)) {
              tokens.add(token!);
              await userDoc.reference.update({'token': tokens});
            }
          }
        } catch (e) {
          print('Error fetching tokens, notifications will not be available');
        }

        QueryDocumentSnapshot value = await data('user', 'email', email);

        name = value['name'];
        surname = value['surname'];
        email = value['email'];
        classes = value['club_class'];
        status = value['status'] == 'Admin'? true : false;
        role = value['role'];
        id = value.id;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('email', _emailController.text);

        role == '' ? _goToWaiting() : _goToHome();
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        _passwordController.clear();
        setState(() {
          _isLoading = false;
          _loginFailed = true;
        });
      }
    }
  }

  _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController resetEmailController = TextEditingController();
        return AlertDialog(
          title: const Text('Recupera password'),
          content: TextField(
            controller: resetEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              icon: Icon(Icons.mail),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancella'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Invia'),
              onPressed: () async {
                if (resetEmailController.text.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: resetEmailController.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Email per il recupero della password inviata')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Error sending password recovery email')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inserisci l\'email')),
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  bool _isObscure = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("images/logo.png", width: 150),
                const SizedBox(height: 20),
                const Text(
                  'Tiber Club',
                  style: TextStyle(fontSize: 30),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_loginFailed)
                        const Text(
                          'Credenziali non valide... Riprova!',
                          style: TextStyle(color: Colors.red),
                        ),
                      if (_loginFailed) const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Mail',
                          icon: Icon(Icons.mail),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci la mail';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Inserisci una mail valida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isObscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          icon: const Icon(Icons.key),
                          suffixIcon: IconButton(
                            icon: Icon(_isObscure
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                        ),
                        keyboardType: TextInputType.visiblePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci la password';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          _handleLogin();
                        },
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/signup');
                                },
                                child: const Text('Registrati'),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text('Accedi',
                                        style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text(
                          'Password dimenticata?',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
