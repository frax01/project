import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'ccCapocannonieri.dart';
import 'ccCalendario.dart';
import 'ccGironi.dart';
import 'ccProgramma.dart';
import 'package:flutter/services.dart';
import 'ccAggiungiSquadre.dart';

class CCHomePage extends StatefulWidget {
  const CCHomePage({
    super.key,
    this.selectedIndex = 0,
  });

  final int selectedIndex;

  @override
  State<CCHomePage> createState() => _CCHomePageState();
}

class _CCHomePageState extends State<CCHomePage> {
  late List<Widget> _ccWidgetOptions;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _ccWidgetOptions = <Widget>[
      PopScope(
        onPopInvoked: (_) {
          SystemNavigator.pop();
        },
        child: const CCProgramma(),
      ),
      PopScope(
        onPopInvoked: (_) {
          SystemNavigator.pop();
        },
        child: const CCGironi(),
      ),
      PopScope(
        onPopInvoked: (_) {
          SystemNavigator.pop();
        },
        child: const CCCalendario(),
      ),
      PopScope(
        onPopInvoked: (_) {
          SystemNavigator.pop();
        },
        child: const CCCapocannonieri(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Champions Club"),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 25, 84, 132),
          ),
        ),
      ),
       drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 25, 84, 132),
              ),
              child: Image.asset(
                'images/logo_champions_bianco.png',
                width: 24,
                height: 24,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Aggiungi squadre'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => CcAggiungiSquadre()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Iscrivi squadre'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
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
        child: _ccWidgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color.fromARGB(255, 25, 84, 132),
        unselectedItemColor: Colors.black54,
        selectedIconTheme: const IconThemeData(color: Color.fromARGB(255, 25, 84, 132)),
        unselectedIconTheme: const IconThemeData(color: Colors.black54),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Programma',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart_outlined),
            activeIcon: Icon(Icons.table_chart),
            label: 'Gironi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer_outlined),
            activeIcon: Icon(Icons.sports_soccer),
            label: 'Marcatori',
          ),
        ],
      ),
    );
  }
}
