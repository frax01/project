import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/pages/main/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.id, required this.document});

  final String id;
  final Map document;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser!.reload();
  }

  Future<void> _showDetailsDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cos\'è il Tiber Club?'),
          content: const SingleChildScrollView(
            child: Text(
              'Il Tiber Club è un\'associazione familiare e giovanile volta allo scopo di promuovere la crescita umana, culturale ' 
              'e spirituale della persona attraverso attività formative, sportive e culturali. Si rivolge a tutti i ragazzi, dalle '
              'scuole primarie a quelle superiori e alle loro famiglie, che trovano nel Tiber un modo di dedicare tempo alla formazione '
              'dei propri ragazzi. Così, il Club, diventa una realtà di supporto alle famiglie nella crescita dei loro figli nella società '
              'attuale. Il Tiber è nato da una convinzione, che la gioventù non è un tempo morto, ma il tempo dei più grandi ideali!',
              style: TextStyle(fontSize: 16),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Chiudi'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteAccountDialog() async {
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
      if (_currentUser != null) {
        try {
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('user')
              .where('email', isEqualTo: _currentUser.email)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
            DocumentReference userDoc = documentSnapshot.reference;
            await userDoc.delete();
            await _currentUser.delete();
          }
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.clear();
          Navigator.of(context).pushReplacementNamed('/login');
        } catch (e) {
          print('Errore durante l\'eliminazione dell\'account: $e');
        }
      }
    }
  }

  Future<void> _logout(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('email', isEqualTo: email)
        .get();
    String? token = await FirebaseMessaging.instance.getToken();
    assert(token != null);
    DocumentSnapshot userDoc = querySnapshot.docs.first;
    List<dynamic> tokens = userDoc["token"];
    tokens.remove(token);
    await userDoc.reference.update({'token': tokens});

    await FirebaseAuth.instance.signOut();
    setState(() {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login()));
    });
  }

  Future<void> _showLogoutDialog() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma'),
          content: const Text('Sei sicuro di voler effettuare il logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      _logout(_currentUser!.email!);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> medie = [];
  List<String> liceo = [];

  (widget.document['club_class'] as List<dynamic>).forEach((club) {
    if (club.toString().contains("media")) {
      medie.add(club.toString());
    } else if (club.toString().contains("liceo")) {
      liceo.add(club.toString());
    }
  });
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(height: 20),
              Column(
                children: [
                  Image.asset(
                    'images/logo.png',
                    width: 150,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${widget.document['name']} ${widget.document['surname']}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.document['email'],
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    if (medie.isNotEmpty) ...medie.map((club) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 1),
                          child: Chip(
                            label: Text(
                              club,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )),
                  ],
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    if (liceo.isNotEmpty) ...liceo.map((club) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 1),
                          child: Chip(
                            label: Text(
                              club,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )),
                  ],
                ),
                ]
              ),
              const SizedBox(height: 20),
              ListView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: ListTile.divideTiles(
                  context: context,
                  tiles: [
                    ListTile(
                      leading: const Icon(Icons.question_mark),
                      title: const Text('Cos\'è il Tiber Club?'),
                      onTap: () {
                        _showDetailsDialog();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Dove siamo?'),
                      onTap: () async {
                        MapsLauncher.launchCoordinates(41.918306, 12.474556);
                      },
                    ),
                    widget.document['status'] == 'Admin'
                    ? ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Richieste utenti'),
                        onTap: () {
                          Navigator.pushNamed(context, '/acceptance');
                        },
                      )
                    : const SizedBox.shrink(),
                    ListTile(
                      leading: const Icon(Icons.policy),
                      title: const Text('Privacy e policy'),
                      onTap: () {
                        launchUrl(Uri.parse('https://www.iubenda.com/privacy-policy/73232344'));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever),
                      title: const Text('Elimina account'),
                      onTap: () {
                        _showDeleteAccountDialog();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.exit_to_app),
                      title: const Text('Logout'),
                      onTap: () {
                        _showLogoutDialog();
                      },
                    ),
                  ],
                ).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
