import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/pages/main/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'status.dart';
import 'package:club/functions/tokenFunctions.dart';
import 'package:club/main.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage(
      {super.key,
      required this.id,
      required this.classes,
      required this.name,
      required this.surname,
      required this.email,
      required this.isAdmin,
      required this.club});

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
  Future<String?> _askPassword() async {
    final TextEditingController controller = TextEditingController();
    final String? password = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma con la password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Conferma'),
              onPressed: () => Navigator.of(context).pop(controller.text),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return password;
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
    if (confirm != true) return;

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      _showMessage('Sessione scaduta: esci e accedi di nuovo');
      return;
    }

    // Re-authenticate BEFORE deleting anything: the Auth deletion needs a
    // recent login, and when it failed (after the profile had already been
    // deleted) the user was left with an account and no profile, unable to
    // use the app again.
    final String? password = await _askPassword();
    if (password == null) return;
    try {
      await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password));
    } on FirebaseAuthException {
      _showMessage('Password errata');
      return;
    }

    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('email', isEqualTo: user.email)
          .get();
      for (final DocumentSnapshot doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      await user.delete();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      _showMessage('Errore durante l\'eliminazione dell\'account');
    }
  }

  Future<void> _logout() async {
    final NavigatorState navigator = Navigator.of(context);
    final User? user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? widget.email;

    // Best effort: a failure here must never keep the user logged in.
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('email', isEqualTo: email)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final DocumentSnapshot userDoc = querySnapshot.docs.first;
        final Map<String, dynamic> data =
            userDoc.data() as Map<String, dynamic>;
        // The token list holds {device: token} maps, so remove(token) on the
        // list never matched and the device kept receiving this user's
        // notifications after logout.
        await userDoc.reference.update({
          'token': removeDeviceToken(
              List<dynamic>.from(data['token'] ?? const []), token)
        });
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      print('Errore durante la rimozione del token: $e');
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();

    // Replace the whole stack: with push, the back button of the login page
    // went back into the app.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (Route<dynamic> route) => false,
    );
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
      _logout();
    }
  }

  void restartApp(BuildContext context, String club) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String ccRole = prefs.getString('ccRole') ?? '';
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => MyApp(
                club: club,
                cc: 'no',
                ccRole: ccRole,
                nome: '${widget.name} ${widget.surname}',
              )),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _showConfirmDialogVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    bool isChecked = false;
    final bool confirm = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return AlertDialog(
                  title: const Text('Conferma'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Aggiornare alla versione ${packageInfo.version}?'),
                      const SizedBox(height: 15),
                      CheckboxListTile(
                        value: isChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            isChecked = value ?? false;
                          });
                        },
                        title: const Text("Obbligatorio"),
                      ),
                    ],
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
            );
          },
        ) ??
        false;

    if (confirm) {
      _updateVersion(isChecked);
    }
  }

  Future<void> _showConfirmDialog(String club) async {
    final bool confirm = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Conferma'),
              content: Text(
                //widget.club == 'Tiber Club'
                //    ? 'Sei sicuro di voler passare al Delta?'
                //    : 
                    'Sei sicuro di voler passare al $club?',
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
        ) ??
        false;
    if (confirm) {
      _updateClub(club);
    }
  }

  Future<void> _updateVersion(bool isChecked) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    await FirebaseFirestore.instance
        .collection('aggiornamento')
        .doc('unico')
        .update({
      'versione': packageInfo.version,
      'obbligatorio': isChecked,
    });
  }

  Future<void> _updateClub(String club) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String newClub = club;

    await prefs.setString('club', newClub);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef =
          FirebaseFirestore.instance.collection('user').doc(widget.id);
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                    ),
                    ListTile(
                      leading: const Icon(Icons.class_rounded),
                      title: medie.length == 1
                          ? const Text('Classe')
                          : const Text('Classi'),
                      subtitle: AutoSizeText(
                        '${medie.join(', ')}${medie.isNotEmpty && liceo.isNotEmpty ? ', ' : ''}${liceo.join(', ')}',
                        style: const TextStyle(fontSize: 20.0),
                        maxLines: 2,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                    ),
                    widget.isAdmin
                        ? ListTile(
                            leading: const Icon(Icons.check_circle),
                            title: const Text('Richieste'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 20),
                            subtitle: const AutoSizeText(
                              'Accetta i nuovi utenti',
                              style: TextStyle(fontSize: 20.0),
                              maxLines: 1,
                              minFontSize: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 10.0),
                            onTap: () {
                              Navigator.pushNamed(context, '/acceptance');
                            },
                          )
                        : const SizedBox.shrink(),
                    widget.isAdmin
                        ? ListTile(
                            leading: const Icon(Icons.build),
                            title: const Text('Iscritti'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 20),
                            subtitle: const AutoSizeText(
                              'Modifica utenti',
                              style: TextStyle(fontSize: 20.0),
                              maxLines: 1,
                              minFontSize: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 10.0),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          Status(club: widget.club)));
                            },
                          )
                        : const SizedBox.shrink(),
                    widget.email == 'francescomartignoni1@gmail.com' && widget.club!= 'Tiber Club'
                        ? ListTile(
                            leading: Image.asset(
                              'images/tiberlogo.png',
                              width: 30,
                            ),
                            title: const Text('Sezione'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 20),
                            subtitle: const AutoSizeText(
                              'Tiber Club',
                              style: TextStyle(fontSize: 20.0),
                              maxLines: 1,
                              minFontSize: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 10.0),
                            onTap: () async {
                              await _showConfirmDialog('Tiber Club');
                            },
                          )
                        : const SizedBox.shrink(),
                    widget.email == 'francescomartignoni1@gmail.com' && widget.club!= 'Delta Club'
                        ? ListTile(
                            leading: Image.asset(
                              'images/deltalogo.jpg',
                              width: 30,
                            ),
                            title: const Text('Sezione'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 20),
                            subtitle: const AutoSizeText(
                              'Centro Delta',
                              style: TextStyle(fontSize: 20.0),
                              maxLines: 1,
                              minFontSize: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 10.0),
                            onTap: () async {
                              await _showConfirmDialog('Delta Club');
                            },
                          )
                        : const SizedBox.shrink(),
                    widget.email == 'francescomartignoni1@gmail.com' && widget.club!= 'Rampa Club'
                        ? ListTile(
                            leading: Image.asset(
                              'images/rampalogo.jpg',
                              width: 30,
                            ),
                            title: const Text('Sezione'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 20),
                            subtitle: const AutoSizeText(
                              'Rampa Club',
                              style: TextStyle(fontSize: 20.0),
                              maxLines: 1,
                              minFontSize: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 10.0),
                            onTap: () async {
                              await _showConfirmDialog('Rampa Club');
                            },
                          )
                        : const SizedBox.shrink(),
                    widget.email == 'francescomartignoni1@gmail.com'
                        ? ListTile(
                            leading: const Icon(Icons.update),
                            title: const Text('Nuova versione'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 20),
                            subtitle: const AutoSizeText(
                              'Aggiornamento',
                              style: TextStyle(fontSize: 20.0),
                              maxLines: 1,
                              minFontSize: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 10.0),
                            onTap: () async {
                              await _showConfirmDialogVersion();
                            },
                          )
                        : const SizedBox.shrink(),
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
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
