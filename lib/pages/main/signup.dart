import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/functions/notificationFunctions.dart';
import 'package:club/user.dart';
import 'package:club/pages/main/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();

  String? _emailErrorMsg;
  String? _passwordErrorMsg;

  _firebaseMessaging() async {
    String? token = await FirebaseMessaging.instance.getToken();
    assert(token != null);
    return token != null && token.isNotEmpty ? [token] : [];
  }

  _saveUser(ClubUser user) async {
    try {
      await _firestore.collection('user').add({
        'name': user.name,
        'surname': user.surname,
        'email': user.email,
        'birthdate': user.birthdate,
        'role': user.role,
        'club_class': user.club_class,
        'soccer_class': user.soccer_class,
        'status': user.status,
        'token': [user.token],
        'created_time': user.created_time
      });
    } catch (e) {
      print('Error saving user to database: $e');
    }
  }

  _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      try {
        String name = _nameController.text;
        String surname = _surnameController.text;
        String email = _emailController.text;
        String password = _passwordController.text;
        String birthdate = _birthdateController.text;

        await _auth.createUserWithEmailAndPassword(email: email, password: password);

        List tokenKey = await _firebaseMessaging();

        var user = ClubUser(
          name: name,
          surname: surname,
          email: email,
          password: password,
          birthdate: birthdate,
          role: '',
          club_class: [],
          soccer_class: '',
          status: '',
          token: tokenKey,
          created_time: DateTime.now(),
        );

        await _saveUser(user);

        List<String> token = await fetchToken('status', 'Admin');
        sendNotification(token, "Tiber Club", "Un nuovo utente si è registrato",
            'new_user', {}, {});

        setState(() {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const Login()));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrazione avvenuta con successo'),
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          setState(() {
            _passwordErrorMsg = 'La password è troppo debole';
          });
        } else if (e.code == 'email-already-in-use') {
          setState(() {
            _emailErrorMsg = 'Questa mail è già in uso';
          });
        }
      }
    }
  }

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      String formattedDate = DateFormat('dd-MM-yyyy').format(picked);
      setState(() {
        _birthdateController.text = formattedDate;
      });
    }
  }

  _form() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome',
              icon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci il tuo nome';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _surnameController,
            decoration: const InputDecoration(
              labelText: 'Cognome',
              icon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci il tuo cognome';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Mail',
              icon: const Icon(Icons.mail),
              errorText: _emailErrorMsg,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci la tua mail';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Inserisci una mail valida';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              icon: const Icon(Icons.password_rounded),
              errorText: _passwordErrorMsg,
            ),
            keyboardType: TextInputType.visiblePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci la tua password';
              }
              if (value.length < 6) {
                return 'La password deve essere lunga almeno 6 caratteri';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordConfirmController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Conferma password',
              icon: Icon(Icons.password_rounded),
            ),
            keyboardType: TextInputType.visiblePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Conferma la tua password';
              }
              if (value != _passwordController.text) {
                _passwordConfirmController.clear();
                return 'Le password non corrispondono';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => _selectDate(context),
            child: IgnorePointer(
              child: TextFormField(
                controller: _birthdateController,
                decoration: const InputDecoration(
                  labelText: 'Birthdate',
                  icon: Icon(Icons.calendar_today_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Birthdate is required';
                  }
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleSignup,
            child: const Text('Registrati'),
          ),
        ],
      ),
    );
  }

  _smallScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BackButton(),
          const SizedBox(height: 20),
          const Text(
            'Registrazione',
            style: TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 20),
          _form(),
        ],
      ),
    );
  }

  _bigScreen() {
    return Stack(
      children: [
        Image.asset(
          "images/CC.jpeg",
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
        ),
        Center(
          child: SizedBox(
            width: 700,
            height: 700,
            child: Card(
              elevation: 10,
              surfaceTintColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Stack(
                  children: [
                    const BackButton(),
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Registrazione',
                            style: TextStyle(fontSize: 30),
                          ),
                          const SizedBox(height: 20),
                          _form(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdaptiveLayout(
        smallLayout: _smallScreen(),
        largeLayout: _bigScreen(),
      ),
    );
  }
}
