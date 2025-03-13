import 'package:animations/animations.dart';
import 'package:club/pages/club/homePage.dart';
import 'package:club/pages/club/profilePage.dart';
import 'package:club/pages/club/torneoPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'info.dart';
import 'calendar.dart';
import 'lunch.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:club/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'accessoCC.dart';

class ClubPage extends StatefulWidget {
  const ClubPage({
    super.key,
    required this.club,
    required this.classes,
    required this.status,
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    this.selectedIndex = 0,
    required this.role,
  });

  final String club;
  final List classes;
  final bool status;
  final String id;
  final String name;
  final String surname;
  final String email;
  final int selectedIndex;
  final String role;

  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  static const String section = 'CLUB';
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  Future<void> _fetchVersion() async {
    String versione = '';
    bool obbligatorio = false;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('aggiornamento')
        .doc('unico')
        .get();
    if (querySnapshot.exists) {
      versione = querySnapshot.data()!['versione'];
      obbligatorio = querySnapshot.data()!['obbligatorio'];
    }
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (versione != packageInfo.version) {
      await showDialog<bool>(
            context: context,
            barrierDismissible: obbligatorio ? false : true,
            barrierColor: const Color.fromARGB(255, 206, 203, 203),
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return AlertDialog(
                    title: const Center(
                        child: Text('Aggiornamento',
                            style: TextStyle(fontSize: 35))),
                    content: obbligatorio
                        ? const Text(
                            'È necessario installare l\'ultima versione dell\'app per continuare ad usarla',
                            style: TextStyle(fontSize: 20))
                        : const Text('Scarica la nuova versione dell\'app',
                            style: TextStyle(fontSize: 20)),
                    actions: <Widget>[
                      Center(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            !obbligatorio
                                ? TextButton(
                                    child: const Text('Più tardi',
                                        style: TextStyle(fontSize: 20)),
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                  )
                                : Container(),
                            TextButton(
                              child: const Text('Aggiorna',
                                  style: TextStyle(fontSize: 20)),
                              onPressed: () {
                                if (Platform.isAndroid) {
                                  FlutterWebBrowser.openWebPage(
                                      url:
                                          'https://play.google.com/store/apps/details?id=com.mycompany.dima');
                                } else if (Platform.isIOS) {
                                  FlutterWebBrowser.openWebPage(
                                      url:
                                          'https://apps.apple.com/it/app/club-app/id6642671734');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Aggiornamento non disponibile, contatta il tuo tutor'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ]))
                    ],
                  );
                },
              );
            },
          ) ??
          false;
    } else {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.id)
          .update({'versione': versione});
    }
  }

  @override
  void initState() {
    super.initState();

    _fetchVersion();

    _selectedIndex = widget.selectedIndex;

    _widgetOptions = <Widget>[
      PopScope(
        onPopInvoked: (_) {
          SystemNavigator.pop();
        },
        child: HomePage(
          club: widget.club,
          selectedClass: widget.classes,
          section: section.toLowerCase(),
          isAdmin: widget.status,
          name: '${widget.name} ${widget.surname}',
          role: widget.role,
        ),
      ),
      PopScope(
        onPopInvoked: (_) {
          SystemNavigator.pop();
        },
        child: Calendar(
            isAdmin: widget.status,
            club: widget.club,
            name: '${widget.name} ${widget.surname}',
            email: widget.email,
            selectedClass: widget.classes,
            role: widget.role),
      ),
      if (widget.club == 'Tiber Club')
        PopScope(
          onPopInvoked: (_) {
            SystemNavigator.pop();
          },
          child: TabScorer(
            isAdmin: widget.status,
          ),
        ),
      if (widget.club == 'Delta Club')
        PopScope(
          onPopInvoked: (_) {
            SystemNavigator.pop();
          },
          child: Lunch(
              isAdmin: widget.status,
              name: '${widget.name} ${widget.surname}',
              role: widget.role,
              club: widget.club,
              classes: widget.classes),
        ),
    ];
  }

  Future<void> _showConfirmDialog(String ccRole) async {
    final bool confirm = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Conferma'),
              content: const Text('Sei sicuro di voler passare alla CC?'),
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
      _updateCC(ccRole);
    }
  }

  Future<void> _updateCC(String ccRole) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('cc',
        'yes'); //da qui bisogna fare che quando arriva una notifica del tuo club e tu la apri ti fa andare direttamente al club e non alla CC anche se hai cc nelle sharedPreferences
    await prefs.setString('ccRole', ccRole);
    await prefs.setString('nome', '${widget.name} ${widget.surname}');
    restartApp(context, prefs.getString('club') ?? '',
        prefs.getString('cc') ?? '', prefs.getString('ccRole') ?? '');
  }

  void restartApp(BuildContext context, String club, String cc, String ccRole) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => MyApp(
              club: club,
              cc: cc,
              ccRole: ccRole,
              nome: '${widget.name} ${widget.surname}',)),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
              title: widget.club == 'Delta Club'
                  ? const Text('Centro Delta')
                  : Text(widget.club),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                    icon: const Icon(Icons.emoji_events),
                    onPressed: () async {
                      final querySnapshot = await FirebaseFirestore.instance
                          .collection('user')
                          .where('email', isEqualTo: widget.email)
                          .get();

                      if (querySnapshot.docs.isNotEmpty) {
                        for (var doc in querySnapshot.docs) {
                          if (doc.data()['ccRole'] == null ||
                              doc.data()['ccRole'] == '' ||
                              doc.data()['ccRole'] == 'user') {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => AccessoCC(
                                      email: widget.email,
                                    )));
                          } else {
                            await _showConfirmDialog(doc.data()['ccRole']);
                          }
                        }
                      }
                    }),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => Info(
                              club: widget.club,
                              role: widget.role,
                              isAdmin: widget.status,
                            )));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person_outlined),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => SettingsPage(
                            id: widget.id,
                            classes: widget.classes,
                            name: widget.name,
                            surname: widget.surname,
                            email: widget.email,
                            isAdmin: widget.status,
                            club: widget.club)));
                  },
                ),
              ]),
          body: PageTransitionSwitcher(
            transitionBuilder: (Widget child, Animation<double> animation,
                Animation<double> secondaryAnimation) {
              return FadeThroughTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                child: child,
              );
            },
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month),
                label: 'Calendario',
              ),
              if (widget.club == 'Tiber Club') ...[
                const BottomNavigationBarItem(
                  icon: Icon(Icons.sports_soccer_outlined),
                  activeIcon: Icon(Icons.sports_soccer),
                  label: '11 ideale',
                ),
              ],
              if (widget.club == 'Delta Club') ...[
                const BottomNavigationBarItem(
                  icon: Icon(Icons.fastfood_outlined),
                  activeIcon: Icon(Icons.fastfood),
                  label: 'Pasti',
                ),
              ],
            ],
          ),
        ));
  }
}
