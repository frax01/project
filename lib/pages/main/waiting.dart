import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Waiting extends StatelessWidget {
  const Waiting({super.key});

  Future<void> _logout(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();

    await FirebaseAuth.instance.signOut();
    Navigator.pushNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (canPop) async {
        Navigator.pushNamed(context, '/login');
      },
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("images/tiberlogo.png", width: 150),
                const SizedBox(height: 20),
                const Text(
                  "In attesa di approvazione",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "La tua richiesta è stata inviata, attendi l'approvazione dell'admin",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.0),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _logout(context),
                  child: const Text("Esci"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
