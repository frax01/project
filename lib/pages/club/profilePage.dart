import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/pages/main/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'status.dart';
import 'package:club/main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.id,
    required this.classes,
    required this.name,
    required this.surname,
    required this.email,
    required this.isAdmin,
    required this.club
  });

  final String id;
  final List classes;
  final String name;
  final String surname;
  final String email;
  final bool isAdmin;
  final String club;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore durante l\'eliminazione dell\'account'),
            ),
          );
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
      print("email: ${_currentUser}");
      _logout(_currentUser!.email!);
    }
  }

  void restartApp(BuildContext context, String club) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (BuildContext context) => MyApp(club: club, startWidget: const Login(),)),
          (Route<dynamic> route) => false,
    );
  }

  Future<void> _showConfirmDialog() async {
    final bool confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma'),
          content: Text(
            widget.club == 'Tiber Club'
                ? 'Sei sicuro di voler passare al Delta?'
                : 'Sei sicuro di voler passare al Tiber?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Conferma'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
    if (confirm) {
      _updateClub();
    }
  }

  Future<void> _updateClub() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String newClub = widget.club == 'Tiber Club'
        ? 'Delta Club'
        : 'Tiber Club';

    await prefs.setString('club', newClub);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('user').doc(widget.id);
      await userRef.update({'club': newClub});
    }
    restartApp(context, newClub);
  }

  @override
  Widget build(BuildContext context) {

    List<String> medie = [];
    List<String> liceo = [];
  
    for (var club in widget.classes) {
      if (club.toString().contains("media")) {
        medie.add(club.toString());
      } else if (club.toString().contains("liceo")) {
        liceo.add(club.toString());
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ListView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: ListTile.divideTiles(
                  context: context,
                  tiles: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Nome'),
                      subtitle: AutoSizeText(
                        '${widget.name} ${widget.surname}',
                        style: const TextStyle(fontSize: 20.0),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    ),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: AutoSizeText(
                        widget.email,
                        style: const TextStyle(fontSize: 20.0),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    ),
                    ListTile(
                      leading: const Icon(Icons.class_rounded),
                      title: medie.length==1? const Text('Classe') : const Text('Classi'),
                      subtitle: AutoSizeText(
                        '${medie.join(', ')}${medie.isNotEmpty && liceo.isNotEmpty ? ', ' : ''}${liceo.join(', ')}',
                        style: const TextStyle(fontSize: 20.0),
                        maxLines: 2,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    ),
                    widget.isAdmin
                    ? ListTile(
                        leading: const Icon(Icons.check_circle),
                        title: const Text('Richieste'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                        subtitle: const AutoSizeText(
                          'Accetta i nuovi utenti',
                          style: TextStyle(fontSize: 20.0),
                          maxLines: 1,
                          minFontSize: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        onTap: () {
                          Navigator.pushNamed(context, '/acceptance');
                        },
                      )
                    : const SizedBox.shrink(),
                    widget.isAdmin
                        ? ListTile(
                      leading: const Icon(Icons.build),
                      title: const Text('Iscritti'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                      subtitle: const AutoSizeText(
                        'Modifica utenti',
                        style: TextStyle(fontSize: 20.0),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Status(club: widget.club)));
                      },
                    ) : const SizedBox.shrink(),
                    widget.email == 'francescomartignoni1@gmail.com'
                        ? ListTile(
                      leading: const Icon(Icons.change_circle),
                      title: const Text('Sezione'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                      subtitle: const AutoSizeText(
                        'Cambia Club',
                        style: TextStyle(fontSize: 20.0),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      onTap: () async {
                        await _showConfirmDialog();
                        //SharedPreferences prefs = await SharedPreferences.getInstance();
                        //if(widget.club=='Tiber Club') {
                        //  prefs.setString('club', 'Delta Club');
                        //} else {
                        //  prefs.setString('club', 'Tiber Club');
                        //}
                        //String club = prefs.getString('club') ?? '';
                      },
                    ) : const SizedBox.shrink(),
                    ListTile(
                      leading: const Icon(Icons.delete_forever),
                      title: const Text('Elimina account'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                      subtitle: const AutoSizeText(
                        'Cancella l\'iscrizione',
                        style: TextStyle(fontSize: 20.0),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      onTap: () {
                        _showDeleteAccountDialog();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.exit_to_app),
                      title: const Text('Logout'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                      subtitle: const AutoSizeText(
                        'Esci dall\'app',
                        style: TextStyle(fontSize: 20.0),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
