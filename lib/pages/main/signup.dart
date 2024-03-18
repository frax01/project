import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:club/user.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:club/functions/notificationFunctions.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key, required this.title});

  final String title;

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUp> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController =
      TextEditingController();
  final TextEditingController birthdateController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> firebaseMessaging() async {
    String? token = await FirebaseMessaging.instance.getToken();
    assert(token != null);
    print('FCM Token: $token');

    if (token != null && token.isNotEmpty) {
      return token;
    } else {
      return '';
    }
  }

  Future<void> _handleSignUp() async {
    try {
      if (_formKey.currentState?.validate() ?? false) {
        String name = nameController.text;
        String surname = surnameController.text;
        String email = emailController.text;
        String password = passwordController.text;
        String birthdate = birthdateController.text;

        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        //await userCredential.user!.sendEmailVerification();

        String confirmPassword = passwordConfirmController.text;
        if (password != confirmPassword) {
          print('Passwords do not match');
          return;
        }

        String tokenKey = await firebaseMessaging();

        await _saveUserToDatabase(ClubUser(
            name: name,
            surname: surname,
            email: email,
            password: password,
            birthdate: birthdate,
            role: "",
            club_class: "",
            soccer_class: "",
            status: "",
            token: tokenKey,
            created_time: DateTime.now()));

        print('Sign up successful: ${userCredential.user?.email}');
        setState(() {
          Navigator.pushNamed(context, '/waiting');
        });
        List<String> token = await fetchToken('status', 'Admin');
        print(token);
        sendNotification(token, "Tiber Club", "Un nuovo utente si è registrato", 'new_user', {}, {});
      }
      // Puoi aggiungere qui la navigazione a una nuova schermata, se necessario
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _saveUserToDatabase(ClubUser user) async {
    try {
      // Ottieni un riferimento al tuo database Firestore
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Aggiungi l'utente al database
      await firestore.collection('user').add({
        'name': user.name,
        'surname': user.surname,
        'email': user.email,
        'birthdate': user.birthdate,
        'role': user.role,
        'club_class': user.club_class,
        'soccer_class': user.soccer_class,
        'status': user.status,
        'token': user.token,
        'created_time': user.created_time
      });
    } catch (e) {
      print('Error saving user to database: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      String formattedDate = DateFormat('dd-MM-yyyy').format(picked);
      setState(() {
        birthdateController.text = formattedDate;
      });
    }
  }

  Form buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BackButton(),
          const Center(
            child: Column(
              children: [
                Text('Sign up',
                    style:
                        TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                Text('Complete the fields below',
                    style: TextStyle(fontSize: 14.0)),
              ],
            ),
          ),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              return null; // Il valore è valido
            },
          ),
          TextFormField(
            controller: surnameController,
            decoration: const InputDecoration(labelText: 'Surname'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Surname is required';
              }
              return null; // Il valore è valido
            },
          ),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              return null; // Il valore è valido
            },
          ),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null; // Il valore è valido
            },
          ),
          TextFormField(
            controller: passwordConfirmController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password confirm'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password confirm is required';
              }
              return null; // Il valore è valido
            },
          ),
          InkWell(
            onTap: () => _selectDate(context),
            child: IgnorePointer(
              child: TextFormField(
                controller: birthdateController,
                decoration: const InputDecoration(labelText: 'Birthdate'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Birthdate is required';
                  }
                  return null; // Il valore è valido
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _handleSignUp,
            style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ),
            child: const Text('Sign up'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Image.asset(
            "images/CC.jpeg",
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.cover,
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: SizedBox(
                width: 600,
                height: 620,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 10.0,
                    shadowColor: Colors.black,
                    surfaceTintColor: Colors.white54,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: buildForm(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
