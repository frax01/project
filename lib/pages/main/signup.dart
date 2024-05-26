import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/functions/notificationFunctions.dart';
import 'package:club/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'verify.dart';

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
    return token != null && token.isNotEmpty ? token : '';
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
      setState(() {
        _isLoading = true;
      });
      try {
        String name = _nameController.text;
        String surname = _surnameController.text;
        String email = _emailController.text;
        String password = _passwordController.text;
        String birthdate = _birthdateController.text;

        await _auth.createUserWithEmailAndPassword(
            email: email, password: password);

        String tokenKey = await _firebaseMessaging();

        var user = ClubUser(
          name: name,
          surname: surname,
          email: email,
          password: password,
          birthdate: birthdate,
          role: '',
          club_class: '',
          status: '',
          token: tokenKey,
          created_time: DateTime.now(),
        );

        await _saveUser(user);

        List<String> token = await retrieveToken('status', 'Admin');
        sendNotification(
            token, 'Nuova registrazione!', 'Accetta il nuovo utente', 'new_user');

        setState(() {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => VerifyEmailPage()));
          _isLoading = false;
        });
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          setState(() {
            _passwordErrorMsg = 'La password è troppo debole';
            _isLoading = false;
          });
        } else if (e.code == 'email-already-in-use') {
          setState(() {
            _emailErrorMsg = 'Questa mail è già in uso';
            _isLoading = false;
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
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != DateTime.now()) {
      String formattedDate = DateFormat('dd-MM-yyyy').format(picked);
      setState(() {
        _birthdateController.text = formattedDate;
      });
    }
  }

  bool _isObscure = false;
  bool _isObscureConfirm = false;
  bool _isLoading = false;

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
            obscureText: !_isObscure,
            decoration: InputDecoration(
              labelText: 'Password',
              icon: const Icon(Icons.password_rounded),
              suffixIcon: IconButton(
                icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),
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
            obscureText: !_isObscureConfirm,
            decoration: InputDecoration(
              labelText: 'Conferma password',
              icon: const Icon(Icons.password_rounded),
              suffixIcon: IconButton(
                icon: Icon(_isObscureConfirm ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _isObscureConfirm = !_isObscureConfirm;
                  });
                },
              ),
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
                  labelText: 'Data di nascita',
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
            onPressed: _isLoading ? null : _handleSignup,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Registrati', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  _smallScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SafeArea(child: BackButton()),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Registrazione',
                    style: TextStyle(fontSize: 30),
                  ),
                  const SizedBox(height: 20),
                  _form(),
                ],
              ),
            ),
          ),
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
