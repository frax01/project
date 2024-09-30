import 'package:animations/animations.dart';
import 'package:club/pages/club/homePage.dart';
import 'package:club/pages/club/profilePage.dart';
import 'package:club/pages/club/torneoPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'info.dart';
import 'calendar.dart';
import 'lunch.dart';

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

  @override
  void initState() {
    super.initState();

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
          role: widget.role
        ),
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
              isAdmin: widget.status, name: '${widget.name} ${widget.surname}', role: widget.role, club: widget.club, classes: widget.classes),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    builder: (context) => Info(club: widget.club)));
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
    );
  }
}
