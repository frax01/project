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
import 'package:club/pages/cc/ccHomePage.dart';

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
                IconButton(
                  icon: const Icon(Icons.emoji_events),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CCHomePage()));
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
