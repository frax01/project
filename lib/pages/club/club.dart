import 'package:animations/animations.dart';
import 'package:club/pages/club/homePage.dart';
import 'package:club/pages/club/profilePage.dart';
import 'package:club/pages/club/torneoPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'birthdayPage.dart';

class ClubPage extends StatefulWidget {
  const ClubPage(
      {super.key,
        required this.title,
        required this.classes,
        required this.status,
        required this.id,
        required this.name,
        required this.surname,
        required this.email,
      });

  final String title;
  final List classes;
  final bool status;
  final String id;
  final String name;
  final String surname;
  final String email;


  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  static const String section = 'CLUB';
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();

    _widgetOptions = <Widget>[
      PopScope(
        onPopInvoked: (_) {
          SystemNavigator.pop();
        },
        child: HomePage(
          selectedClass: widget.classes,
          section: section.toLowerCase(),
          isAdmin: widget.status,
        ),
      ),
      PopScope(
        onPopInvoked: (_) {
          SystemNavigator.pop();
        },
        child: TabScorer(
          isAdmin: widget.status,
        ),
      ),
      PopScope(
        onPopInvoked: (_) {
          SystemNavigator.pop();
        },
        child: const BirthdayPage(),
      ),
      PopScope(
        onPopInvoked: (_) {
          SystemNavigator.pop();
        },
        child: SettingsPage(
          id: widget.id,
          classes: widget.classes,
          name: widget.name,
          surname: widget.surname,
          email: widget.email,
          isAdmin: widget.status,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiber Club'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer_outlined),
            activeIcon: Icon(Icons.sports_soccer),
            label: '11 ideale',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cake_outlined),
            activeIcon: Icon(Icons.cake),
            label: 'Compleanni',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Utente',
          ),
        ],
      ),
    );
  }
}
