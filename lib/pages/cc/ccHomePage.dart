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
import 'ccCreazioneCase.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CCHomePage extends StatefulWidget {
  const CCHomePage(
      {super.key,
      this.selectedIndex = 0,
      required this.club,
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
    print("club: ${widget.club}");

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
        child: CCCalendario(
            ccRole: widget.ccRole ?? '',
            nome: widget
                .nome), //se widget.nome in calendario è vuoto allora niente, altrimenti si vedono le partite
      ),
      PopScope(
        onPopInvoked: (_) {
          SystemNavigator.pop();
        },
        child: const CCCapocannonieri(),
      ),
    ];
  }

  Future<void> _showConfirmDialog(bool user) async {
    if (user) {
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
    } else {
      final bool confirm = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Conferma'),
                content: const Text('Sei sicuro di uscire?'),
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
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('cc', 'no');
        //Navigator.pushReplacement(
        //    context, MaterialPageRoute(builder: (context) => const Login()));
        restartApp(context, prefs.getString('club') ?? '',
            prefs.getString('cc') ?? '', 'user', '');
      }
    }
  }

  void restartApp(BuildContext context, String club, String cc, String ccRole,
      String nome) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) =>
              MyApp(club: club, cc: cc, ccRole: ccRole, nome: nome)),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _updateClub() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('cc', 'no');
    restartApp(context, prefs.getString('club') ?? '',
        prefs.getString('cc') ?? '', prefs.getString('ccRole') ?? '', '');
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> _createExcelPartite() async {
    _showLoadingDialog();

    try {
      // Crea un nuovo file Excel
      var excelFile = excel.Excel.createExcel();

      // Definisci le collezioni Firestore per ogni fase
      final List<Map<String, dynamic>> fasi = [
        {'nome': 'Gironi', 'collezione': 'ccPartiteGironi'},
        {'nome': 'Ottavi', 'collezione': 'ccPartiteOttavi'},
        {'nome': 'Quarti', 'collezione': 'ccPartiteQuarti'},
        {'nome': 'Semifinali', 'collezione': 'ccPartiteSemifinali'},
        {'nome': 'Finali', 'collezione': 'ccPartiteFinali'},
      ];

      for (var fase in fasi) {
        // Ottieni i dati da Firestore per la fase corrente
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection(fase['collezione'])
            .get();
        final List<DocumentSnapshot> documents = result.docs;

        // Crea un foglio per la fase
        var sheet = excelFile[fase['nome']];

        // Aggiungi l'intestazione
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = excel.TextCellValue('Casa');
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = excel.TextCellValue('Fuori');
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = excel.TextCellValue('Tipo');
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = excel.TextCellValue('Gol casa');
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = excel.TextCellValue('Gol fuori');


        for (var doc in documents) {
          final casa = doc['casa'];
          final fuori = doc['fuori'];
          var tipo = '';
          if (fase['nome'] == 'Gironi') {
            tipo = '${doc['tipo']} ${doc['girone']}';
          } else {
            tipo = doc['tipo'];
          }
          
          int golCasa = 0;
          int golFuori = 0;
          List<Map<String, dynamic>> marcatori =
              List<Map<String, dynamic>>.from(doc['marcatori'] ?? []);
          for (var marcatore in marcatori) {
            if (marcatore['dove'] == 'casa' && marcatore['cosa'] == 'gol') {
              golCasa++;
            } else if (marcatore['dove'] == 'fuori' &&
                marcatore['cosa'] == 'gol') {
              golFuori++;
            }
          }

          // Aggiungi la riga al foglio
          sheet.appendRow([
            excel.TextCellValue(casa),
            excel.TextCellValue(fuori),
            excel.TextCellValue(tipo),
            excel.IntCellValue(golCasa),
            excel.IntCellValue(golFuori),
          ]);
        }
      }

      // Salva il file Excel
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/partiteCC2025.xlsx");
      await file.writeAsBytes(excelFile.encode()!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('File Excel creato e condiviso con successo!')),
      );

      Navigator.of(context).pop();

      // Condividi il file Excel
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ecco il file Excel delle partite per il Champions Club 2025!',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Errore durante la creazione del file Excel: $e')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Champions Club"),
        automaticallyImplyLeading: false,
        leading: widget.ccRole == 'staff'
            ? Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              )
            : null,
        actions: [
          widget.ccRole == 'tutor'
              ? IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CcIscriviSquadre(
                            club: widget.club ?? '',
                            ccRole: widget.ccRole ?? '')));
                  })
              : Container(),
          widget.ccRole != 'staff'
              ? IconButton(
                  icon: const Icon(Icons.logout_outlined),
                  onPressed: () async {
                    await _showConfirmDialog(widget.user);
                  })
              : Container(),
          if (_selectedIndex == 2 && widget.ccRole == 'staff')
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: () async {
                bool? confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Crea Excel'),
                    content:
                        const Text('Vuoi creare un file Excel per le partite?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Si'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _createExcelPartite();
                }
              },
            ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF00296B),
          ),
        ),
      ),
      drawer: widget.ccRole == 'staff'
          ? Drawer(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.zero, topRight: Radius.zero),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Color(0xFF00296B),
                    ),
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
                    child: Image.asset(
                      'images/logo_champions_bianco.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  widget.ccRole == 'staff'
                      ? ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text('Gestione squadre'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => CcAggiungiSquadre()));
                          },
                        )
                      : Container(),
                  widget.ccRole == 'staff'
                      ? ListTile(
                          leading: const Icon(Icons.table_chart_outlined),
                          title: const Text('Gestione gironi'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ccCreazioneGironi()));
                          },
                        )
                      : Container(),
                  widget.ccRole == 'staff'
                      ? ListTile(
                          leading: const Icon(Icons.home),
                          title: const Text('Gestione case'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => CcCreazioneCase()));
                          },
                        )
                      : Container(),
                  widget.ccRole == 'staff' || widget.ccRole == 'tutor'
                      ? ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Iscrivi giocatori'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => CcIscriviSquadre(
                                    club: widget.club ?? '',
                                    ccRole: widget.ccRole ?? '')));
                          },
                        )
                      : Container(),
                  ListTile(
                    leading: const Icon(Icons.logout_outlined),
                    title: Text(widget.user == true ? 'Torna al Club' : 'Esci'),
                    onTap: () async {
                      await _showConfirmDialog(widget.user);
                    },
                  )
                ],
              ),
            )
          : null,
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
        selectedItemColor: const Color(0xFF00296B),
        unselectedItemColor: Colors.black54,
        selectedIconTheme: const IconThemeData(
          color: Color(0xFF00296B),
        ),
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
