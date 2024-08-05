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
  final TextEditingController _clubController = TextEditingController();

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
        'club': user.club,
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
      setState(() {
        _isLoading = true;
      });
      try {
        String name = _nameController.text;
        String surname = _surnameController.text;
        String email = _emailController.text;
        String password = _passwordController.text;
        String birthdate = _birthdateController.text;
        String club = _clubController.text;

        await _auth.createUserWithEmailAndPassword(
            email: email, password: password);

        String tokenKey = await _firebaseMessaging();

        var user = ClubUser(
          name: name,
          surname: surname,
          email: email,
          password: password,
          birthdate: birthdate,
          club: club,
          role: '',
          club_class: '',
          soccer_class: '',
          status: '',
          token: tokenKey,
          created_time: DateTime.now(),
        );

        await _saveUser(user);

        List<String> token = await retrieveToken('status', 'Admin', _clubController.text);
        sendNotification(token, 'Nuova registrazione!', 'Accetta il nuovo utente', 'new_user');

        setState(() {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const VerifyEmailPage()));
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

  String? _selectedClub;

  void _clubDialog() async {
    bool? isTiberClubChecked = _selectedClub == 'Tiber Club';
    bool? isDeltaClubChecked = _selectedClub == 'Delta Club';

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Scegli il Club'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('Tiber Club'),
                    subtitle: const Text('Roma'),
                    value: isTiberClubChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isTiberClubChecked = value ?? false;
                        isDeltaClubChecked = false;
                        _selectedClub = '';
                        if (isTiberClubChecked!) {
                          _selectedClub = 'Tiber Club';
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Delta Club'),
                    subtitle: const Text('Milano'),
                    value: isDeltaClubChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isDeltaClubChecked = value ?? false;
                        isTiberClubChecked = false;
                        _selectedClub = '';
                        if (isDeltaClubChecked!) {
                          _selectedClub = 'Delta Club';
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    if (_selectedClub != null) {
                      _clubController.text = _selectedClub!;
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isObscure = false;
  bool _isObscureConfirm = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
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
                    Form(
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
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Inserisci una mail valida';
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
                                    return 'Inserisci la data di nascita';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: () => _clubDialog(),
                            child: IgnorePointer(
                              child: TextFormField(
                                controller: _clubController,
                                decoration: const InputDecoration(
                                  labelText: 'Club',
                                  icon: Icon(Icons.class_),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Scegli il Club';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isObscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              icon: const Icon(Icons.password_rounded),
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
                                icon: Icon(_isObscureConfirm
                                    ? Icons.visibility
                                    : Icons.visibility_off),
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
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignup,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Registrati',
                                    style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
