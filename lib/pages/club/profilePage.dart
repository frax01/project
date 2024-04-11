import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/pages/main/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shimmer/shimmer.dart';

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

  Future<void> _deleteAccount(String email) async {
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
          }
          await _currentUser.delete();
          Navigator.of(context).pushReplacementNamed('/login');
        } catch (e) {
          print('Errore durante l\'eliminazione dell\'account: $e');
        }
      }
    }
  }

  Future<void> _showLocationDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dove siamo?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  'https://maps.locationiq.com/v3/staticmap?key=pk.b63d7f8ea78402e4ce0f6151f5434613&center=41.918306,12.474556&zoom=15&size=400x400&markers=icon:large-blue-cutout%7C41.918306,12.47455',
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    } else {
                      return SizedBox(
                        height: 400,
                        width: 400,
                        child: Center(
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              color: Colors.grey[300],
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Text('Via di Villa Giulia, 27\n00197 Roma',
                  style: TextStyle(fontSize: 16)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Apri in Maps'),
              onPressed: () {
                MapsLauncher.launchCoordinates(41.918306, 12.474556);
              },
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
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
                  const SizedBox(height: 10),
                  Text(widget.document['club_class'][0],
                      style: const TextStyle(fontSize: 16)),
                ],
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
                      title: const Text('Cos\'è il club?'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Dove siamo?'),
                      onTap: () async {
                        return _showLocationDialog();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Richieste utenti'),
                      onTap: () {
                        Navigator.pushNamed(context, '/acceptance');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever),
                      title: const Text('Elimina account'),
                      onTap: () {
                        _deleteAccount(_currentUser!.email!);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.exit_to_app),
                      title: const Text('Logout'),
                      onTap: () {
                        _logout(_currentUser!.email!);
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
