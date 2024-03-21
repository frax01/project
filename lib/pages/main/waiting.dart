import 'package:adaptive_layout/adaptive_layout.dart';
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

  _content(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset("images/logo.png", width: 150),
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
    );
  }

  _smallScreen(context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: _content(context),
      ),
    );
  }

  _bigScreen(context) {
    return Stack(
      children: [
        Image.asset(
          "images/Tiber.jpg",
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
        ),
        Center(
          child: SizedBox(
            height: 700,
            width: 700,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 10.0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: _content(context),
                  ),
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
    return PopScope(
      canPop: true,
      onPopInvoked: (canPop) async {
        Navigator.pushNamed(context, '/login');
      },
      child: Scaffold(
        body: AdaptiveLayout(
          smallLayout: _smallScreen(context),
          largeLayout: _bigScreen(context),
        ),
      ),
    );
  }
}
