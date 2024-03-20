import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:animations/animations.dart';
import 'package:club/pages/club/homePage.dart';
import 'package:club/pages/club/settingsPage.dart';
import 'package:club/pages/club/torneoPage.dart';
import 'package:club/pages/main/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClubPage extends StatefulWidget {
  const ClubPage({super.key, required this.title, required this.document});

  final Map document;
  final String title;

  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  static const String section = 'CLUB';
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  bool _isSidebarExtended = false;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomePage(
        selectedClass: widget.document['club_class'],
        section: section.toLowerCase(),
        isAdmin: widget.document['status'] == 'Admin',
      ),
      TabScorer(
        document: widget.document,
      ),
      SettingsPage(
        id: widget.document["id"],
        document: widget.document,
      ),
    ];
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();

    await FirebaseAuth.instance.signOut();
    setState(() {
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Login()));
    });
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  Widget smallScreen() {
    return Scaffold(
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer),
            selectedIcon: Icon(Icons.sports_soccer),
            label: '11 ideale',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Utente',
          ),
        ],
      ),
    );
  }

  Widget bigScreen() {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                  padding: EdgeInsets.only(top: 8.0),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.sports_soccer),
                  selectedIcon: Icon(Icons.sports_soccer),
                  label: Text('11 ideale'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_box),
                  selectedIcon: Icon(Icons.account_box),
                  label: Text('Account'),
                ),
              ],
              extended: _isSidebarExtended,
              leading: IconButton(
                icon: Icon(_isSidebarExtended ? Icons.arrow_back : Icons.menu),
                onPressed: () {
                  setState(() {
                    _isSidebarExtended = !_isSidebarExtended;
                  });
                },
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: _logout,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // This is the main content.
            Expanded(
              child: Scaffold(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: PopScope(
        canPop: false,
        child: AdaptiveLayout(
          smallLayout: smallScreen(),
          largeLayout: bigScreen(),
        ),
      ),
    );
  }
}
