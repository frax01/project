import 'dart:async';
import 'package:flutter/material.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:club/functions/notificationFunctions.dart';

class VerifyEmailPage extends StatefulWidget {
  @override
  _VerifyEmailPageState createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      sendVerificationEmail();

      timer = Timer.periodic(
          const Duration(seconds: 3), (_) => checkEmailVerified());
    }
  }

  @override
  void dispose() {
    timer?.cancel();

    super.dispose();
  }

  Future checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });
    if (isEmailVerified) timer?.cancel();
  }

  Future sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();

      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 5));
      setState(() => canResendEmail = true);
    } catch (e) {
      print('errore');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEmailVerified) {
      //retrieveToken('status', 'Admin').then((List<String> token) {
      //  sendNotification(
      //      token, 'Tiber Club', 'Un nuovo utente si è registrato', 'new_user');
      //});
      return const Login();
    } else {
      return Scaffold(
          appBar: AppBar(title: const Text('Verifica account')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Una mail di verifica è stata inviata',
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.email, size: 32),
                  label: const Text(
                    'Invia di nuovo',
                    style: TextStyle(fontSize: 24),
                  ),
                  onPressed: canResendEmail ? sendVerificationEmail : null,
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(50),
                  ),
                  child: const Text(
                    'Indietro',
                    style: TextStyle(fontSize: 24),
                  ),
                  onPressed: () => FirebaseAuth.instance.signOut,
                )
              ],
            ),
          ));
    }
  }
}

//@override
//  Widget build(BuildContext context) => isEmailVerified
//      ? const Login()
//      : Scaffold(
//          appBar: AppBar(title: const Text('Verifica account')),
//          body: Padding(
//            padding: const EdgeInsets.all(16),
//            child: Column(
//              mainAxisAlignment: MainAxisAlignment.center,
//              children: [
//                const Text(
//                  'Una mail di verifica è stata inviata',
//                  style: TextStyle(fontSize: 20),
//                  textAlign: TextAlign.center,
//                ),
//                const SizedBox(height: 24),
//                ElevatedButton.icon(
//                  style: ElevatedButton.styleFrom(
//                    minimumSize: Size.fromHeight(50),
//                  ),
//                  icon: const Icon(Icons.email, size: 32),
//                  label: const Text(
//                    'Invia di nuovo',
//                    style: TextStyle(fontSize: 24),
//                  ),
//                  onPressed: canResendEmail ? sendVerificationEmail : null,
//                ),
//                const SizedBox(height: 8),
//                TextButton(
//                  style: ElevatedButton.styleFrom(
//                    minimumSize: Size.fromHeight(50),
//                  ),
//                  child: const Text(
//                    'Indietro',
//                    style: TextStyle(fontSize: 24),
//                  ),
//                  onPressed: () => FirebaseAuth.instance.signOut,
//                )
//              ],
//            ),
//          ));
//}
//