import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'ccCapocannonieri.dart';
import 'ccCalendario.dart';
import 'ccGironi.dart';
import 'ccProgramma.dart';
import 'package:flutter/services.dart';
import 'ccAggiungiSquadre.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:club/main.dart';
import 'ccIscriviSquadre.dart';
import 'ccCreazioneGironi.dart';
import 'package:club/pages/main/login.dart';

class CCHomePage extends StatefulWidget {
  const CCHomePage(
      {super.key,
      this.selectedIndex = 0,
      this.club,
      this.ccRole,
      required this.email,
      required this.user,
      required this.nome});

  final int selectedIndex;
  final String? club;
  final String? ccRole;
  final bool user;
  final String email;
  final String
      nome; //se il nome è vuoto prenderlo dalla tabella user (nome+cognome) solo se ccRole==staff

  @override
  State<CCHomePage> createState() => _CCHomePageState();
}

class _CCHomePageState extends State<CCHomePage> {
  late List<Widget> _ccWidgetOptions;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    print("nome: ${widget.nome}");
    print("email: ${widget.email}");

    _ccWidgetOptions = <Widget>[
      PopScope(
        onPopInvoked: (_) {
          SystemNavigator.pop();
        },
        child: CCProgramma(ccRole: widget.ccRole ?? ''),
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
        child: CCCalendario(ccRole: widget.ccRole ?? '', nome: widget.nome), //se widget.nome in calendario è vuoto allora niente, altrimenti si vedono le partite
      ),
      PopScope(
        onPopInvoked: (_) {
          SystemNavigator.pop();
        },
        child: const CCCapocannonieri(),
      ),
    ];
  }

  Future<void> _showConfirmDialog() async {
    final bool confirm = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Conferma'),
              content: const Text('Sei sicuro di voler passare al Club?'),
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
      _updateClub();
    }
  }

  Future<void> _updateClub() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('cc', 'no');
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
                nome: widget.nome,
              )),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Champions Club"),
        automaticallyImplyLeading: false,
        actions: [
          widget.ccRole == 'staff'
              ? IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CcAggiungiSquadre()));
                  },
                )
              : Container(),
          widget.ccRole == 'staff' || widget.ccRole == 'tutor'
              ? IconButton(
                  icon: const Icon(Icons.people),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CcIscriviSquadre(
                            club: widget.club ?? '',
                            ccRole: widget.ccRole ?? '')));
                  },
                )
              : Container(),
          widget.ccRole == 'staff'
              ? IconButton(
                  icon: const Icon(Icons.group_work),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ccCreazioneGironi()));
                  },
                )
              : Container(),
          widget.user == true
              ? IconButton(
                  icon: const Icon(Icons.class_),
                  onPressed: () async {
                    await _showConfirmDialog();
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.class_),
                  onPressed: () async {
                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setString('cc', 'no');
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => const Login()));
                  },
                )
        ],
        //leading: Builder(
        //  builder: (BuildContext context) {
        //    return IconButton(
        //      icon: const Icon(Icons.menu),
        //      onPressed: () {
        //        Scaffold.of(context).openDrawer();
        //      },
        //    );
        //  },
        //),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF00296B), //Color.fromARGB(255, 25, 84, 132),
          ),
        ),
      ),
      //drawer: Drawer(
      //  child: ListView(
      //    padding: EdgeInsets.zero,
      //    children: <Widget>[
      //      DrawerHeader(
      //        decoration: const BoxDecoration(
      //          color: Color.fromARGB(255, 25, 84, 132),
      //        ),
      //        child: Image.asset(
      //          'images/logo_champions_bianco.png',
      //          width: 24,
      //          height: 24,
      //        ),
      //      ),
      //      ListTile(
      //        leading: const Icon(Icons.add),
      //        title: const Text('Aggiungi squadre'),
      //        onTap: () {
      //          Navigator.of(context).push(MaterialPageRoute(
      //              builder: (context) => CcAggiungiSquadre()));
      //        },
      //      ),
      //      ListTile(
      //        leading: const Icon(Icons.people),
      //        title: const Text('Iscrivi giocatori'),
      //        onTap: () {
      //          Navigator.of(context).push(MaterialPageRoute(
      //              builder: (context) => CcIscriviSquadre(club: widget.club?? '')));
      //        },
      //      ),
      //      ListTile(
      //        leading: const Icon(Icons.group_work),
      //        title: const Text('Creazione gironi'),
      //        onTap: () {
      //          Navigator.of(context).push(MaterialPageRoute(
      //              builder: (context) => ccCreazioneGironi()));
      //        },
      //      ),
      //      ListTile(
      //        leading: const Icon(Icons.class_rounded),
      //        title: const Text('Torna al Club'),
      //        onTap: () async {
      //          await _showConfirmDialog();
      //        },
      //      ),
      //    ],
      //  ),
      //),
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
        selectedIconTheme:
            const IconThemeData(color: Color.fromARGB(255, 25, 84, 132)),
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
