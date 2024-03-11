import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:club/pages/club/club.dart';

class Login extends StatefulWidget {
  const Login({Key? key, required this.title}) : super(key: key);

  final String title;

  //final bool logout;

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? status;

  bool rememberMe = false;
  List<String> emailSuggestions = [];
  Map<String, String> savedCredentials = {};
  Map<String, dynamic> document = {};

  @override
  void initState() {
    super.initState();
    //if (widget.logout == true) {
    //  emailController.text = '';
    //  passwordController.text = '';
    //  rememberMe = false;
    //  //emailController.addListener(_fillPassword);
    //} else {
    //  _loadLoginInfo().then((_) {
    //    if (rememberMe &&
    //        emailController.text.isNotEmpty &&
    //        passwordController.text.isNotEmpty) {
    //      _handleLogin();
    //    }
    //  });
    //}
  }

  _loadLoginInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = (prefs.getString('email') ?? '');
      passwordController.text = (prefs.getString('password') ?? '');
      rememberMe = (prefs.getBool('rememberMe') ?? false);
      emailSuggestions = (prefs.getStringList('emailSuggestions') ?? []);
    });
  }

  //_fillPassword() {
  //  if (savedCredentials.containsKey(emailController.text)) {
  //    passwordController.text = savedCredentials[emailController.text]!;
  //  }
  //}

  _saveLoginInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('email', emailController.text);
    prefs.setString('password', passwordController.text);
    prefs.setBool('rememberMe', rememberMe);
    if (!emailSuggestions.contains(emailController.text)) {
      emailSuggestions.add(emailController.text);
      prefs.setStringList('emailSuggestions', emailSuggestions);
    }

    Map<String, dynamic> allPrefs = prefs.getKeys().fold<Map<String, dynamic>>(
      {},
      (Map<String, dynamic> acc, String key) {
        acc[key] = prefs.get(key);
        return acc;
      },
    );

    print("SharedPreferences: $allPrefs");
  }

  _loadLastPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastPage = (prefs.getString('lastPage') ?? 'FootballPage');

    if (lastPage == 'ClubPage') {
      loadClubPage(status);
    } //else if (lastPage == 'FootballPage') {
    //  print(emailController.text);
    //  loadFootballPage(status);
    //}
  }

  loadClubPage(status) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ClubPage(title: "Phoenix United", document: document)));
  }

  //loadFootballPage(status) {
  //  Navigator.push(
  //      context,
  //      MaterialPageRoute(
  //          builder: (context) =>
  //              FootballPage(title: "Phoenix United", document: document)));
  //}

  _saveLastPage(String page) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('lastPage', page);
  }

  Future<void> _handleLogin() async {
    try {
      String email = emailController.text;
      String password = passwordController.text;

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userEmail = userCredential.user?.email ?? '';
      CollectionReference user = FirebaseFirestore.instance.collection('user');
      QuerySnapshot querySnapshot1 =
          await user.where('email', isEqualTo: userEmail).get();

      document = {
        'name': querySnapshot1.docs.first['name'],
        'surname': querySnapshot1.docs.first['surname'],
        'email': querySnapshot1.docs.first['email'],
        'role': querySnapshot1.docs.first['role'],
        'club_class': querySnapshot1.docs.first['club_class'],
        'soccer_class': querySnapshot1.docs.first['soccer_class'],
        'status': querySnapshot1.docs.first['status'],
        'birthdate': querySnapshot1.docs.first['birthdate'],
        'token': querySnapshot1.docs.first['token'],
        'id': querySnapshot1.docs.first.id,
      };

      //gestire il caso di waiting
      setState(() {
        if (document['role'] == "") {
          Navigator.pushNamed(context, '/waiting');
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ClubPage(title: "Tiber Club", document: document)));
        }
      });
      if (rememberMe) {
        _saveLoginInfo();
      }
    } catch (e) {
      print('Error during login: $e');
    }
  }

  Future<void> _handleSignUp() async {
    setState(() {
      Navigator.pushNamed(context, '/signup');
    });
  }

  void _handleForgotPassword() {
    // Implementa la logica per il ripristino della password qui
    print('Forgot Password tapped');
  }

  Column buildForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Center(
          child: Column(
            children: [
              Text('Log In',
                  style:
                      TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
              Text('Complete the fields below',
                  style: TextStyle(fontSize: 14.0)),
            ],
          ),
        ),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 15.0),
        CheckboxListTile(
          title: const Text('Remember me'),
          value: rememberMe,
          onChanged: (bool? value) {
            setState(() {
              rememberMe = value!;
            });
          },
        ),
        const SizedBox(height: 6),
        ElevatedButton(
          onPressed: _handleLogin,
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
          ),
          child: const Text('Login'),
        ),
        const SizedBox(height: 6),
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
        const SizedBox(height: 16.0),
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                TextEditingController resetEmailController =
                    TextEditingController();
                return AlertDialog(
                  title: const Text('Recover password'),
                  content: TextField(
                    controller: resetEmailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Send'),
                      onPressed: () async {
                        if (resetEmailController.text.isNotEmpty) {
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                                email: resetEmailController.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Password recovery email sent')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Error sending password recovery email')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Insert a mail address')),
                          );
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: const Text(
            'Forgot password?',
          ),
        ),
      ],
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
                        child: Column(
                          children: [
                            Image.asset("images/logo.png", width: 150),
                            const SizedBox(
                              height: 20,
                            ),
                            Container(
                              child: buildForm(),
                            ),
                          ],
                        ),
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
