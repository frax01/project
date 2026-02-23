import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ccNuovaPartitaGironi.dart';
import 'ccNuovaPartitaFaseFinale.dart';
import 'ccModificaPartita.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CCCalendario extends StatefulWidget {
  const CCCalendario({
    super.key,
    required this.ccRole,
    required this.nome,
  });

  final String ccRole;
  final String nome;

  @override
  State<CCCalendario> createState() => _CCCalendarioState();
}

class _CCCalendarioState extends State<CCCalendario> {
  String _selectedSegment = 'Gironi';
  String _selectedGirone = 'A';
  late Stream<List<Map<String, dynamic>>> _streamPartite;

  @override
  void initState() {
    super.initState();
    _streamPartite = _getPartite();
    _loadSquadre();
    _getGironi();
  }

  Map<String, String> _squadreLoghi = {};
  List<String> _gironi = [];

  Future<void> _getGironi() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('ccGironi').get();

    List<String> gironiList = [];
    for (var doc in snapshot.docs) {
      gironiList.add(doc['nome']);
    }

    setState(() {
      _gironi = gironiList;
    });
  }

  Future<void> _loadSquadre() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print("nome: ${prefs.getString('nome')}");

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('ccSquadre').get();

    Map<String, String> squadreLoghi = {};
    for (var doc in snapshot.docs) {
      List<Map<String, dynamic>> squadre =
          List<Map<String, dynamic>>.from(doc['squadre']);
      for (var squadra in squadre) {
        squadreLoghi[squadra['squadra']] = squadra['logo'];
      }
    }

    setState(() {
      _squadreLoghi = squadreLoghi;
    });
  }

  Stream<List<Map<String, dynamic>>> _getPartite() {
    if (_selectedSegment == 'Gironi') {
      return FirebaseFirestore.instance
          .collection('ccPartiteGironi')
          .where('girone', isEqualTo: _selectedGirone)
          .snapshots()
          .map((querySnapshot) {
        List<Map<String, dynamic>> partite = querySnapshot.docs
            .map((doc) => doc.data())
            .toList();

        partite.sort((a, b) {
          int gironeComparison = a['girone'].compareTo(b['girone']);
          if (gironeComparison != 0) return gironeComparison;

          int turnoComparison = a['turno'].compareTo(b['turno']);
          if (turnoComparison != 0) return turnoComparison;

          if (a['orario'] == '' && b['orario'] == '') return 0;
          if (a['orario'] == '') return 1;
          if (b['orario'] == '') return -1;

          return a['orario'].compareTo(b['orario']);
        });

        return partite;
      });
    } else if (_selectedSegment == 'Ottavi') {
      return FirebaseFirestore.instance
          .collection('ccPartiteOttavi')
          .snapshots()
          .map((querySnapshot) {
        List<Map<String, dynamic>> partite = querySnapshot.docs
            .map((doc) => doc.data())
            .toList();

        partite.sort((a, b) {
          int turnoComparison = a['codice'].compareTo(b['codice']);
          if (turnoComparison != 0) return turnoComparison;

          if (a['orario'] == '' && b['orario'] == '') return 0;
          if (a['orario'] == '') return 1;
          if (b['orario'] == '') return -1;

          return a['orario'].compareTo(b['orario']);
        });

        return partite;
      });
    } else if (_selectedSegment == 'Quarti') {
      return FirebaseFirestore.instance
          .collection('ccPartiteQuarti')
          .snapshots()
          .map((querySnapshot) {
        List<Map<String, dynamic>> partite = querySnapshot.docs
            .map((doc) => doc.data())
            .toList();

        partite.sort((a, b) {
          int codiceComparison = a['codice'].compareTo(b['codice']);
          if (codiceComparison != 0) return codiceComparison;

          if (a['orario'] == '' && b['orario'] == '') return 0;
          if (a['orario'] == '') return 1;
          if (b['orario'] == '') return -1;

          return a['orario'].compareTo(b['orario']);
        });

        return partite;
      });
    } else if (_selectedSegment == 'Semifinali') {
      return FirebaseFirestore.instance
          .collection('ccPartiteSemifinali')
          .snapshots()
          .map((querySnapshot) {
        List<Map<String, dynamic>> partite = querySnapshot.docs
            .map((doc) => doc.data())
            .toList();

        partite.sort((a, b) {
          int codiceComparison = a['codice'].compareTo(b['codice']);
          if (codiceComparison != 0) return codiceComparison;

          if (a['orario'] == '' && b['orario'] == '') return 0;
          if (a['orario'] == '') return 1;
          if (b['orario'] == '') return -1;

          return a['orario'].compareTo(b['orario']);
        });

        return partite;
      });
    } else {
      return FirebaseFirestore.instance
          .collection('ccPartiteFinali')
          .snapshots()
          .map((querySnapshot) {
        List<Map<String, dynamic>> partite = querySnapshot.docs
            .map((doc) => doc.data())
            .toList();

        partite.sort((a, b) {
          int codiceComparison = a['codice'].compareTo(b['codice']);
          if (codiceComparison != 0) return codiceComparison;

          if (a['orario'] == '' && b['orario'] == '') return 0;
          if (a['orario'] == '') return 1;
          if (b['orario'] == '') return -1;

          return a['orario'].compareTo(b['orario']);
        });

        return partite;
      });
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> _pulisci(String sezione) async {
    final bool confermato = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma'),
          content: Text(
              'Sei sicuro di voler pulire la sezione $sezione? Questa azione non può essere annullata'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Conferma'),
            ),
          ],
        );
      },
    );
    
    if (confermato != true) return;
    
    _showLoadingDialog();
    
    final QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('ccPartite$sezione').get();

    for (var doc in querySnapshot.docs) {
      await FirebaseFirestore.instance
          .collection('ccPartite$sezione')
          .doc(doc.id)
          .update({
        'casa': '',
        'fuori': '',
        'orario': '',
        'campo': '',
        'arbitro': '',
        'data': sezione == 'Finali' ? '27/04/2025' : '26/04/2025',
        'iniziata': false,
        'finita': false,
        'marcatori': [],
        'tipo': '${sezione[0].toLowerCase()}${sezione.substring(1)}',
        'codice': doc.id,
      });
    }
    
    Navigator.of(context).pop();
  }

  Widget _widgetText(String codiceP, String arbitro, String refertista,
      bool iniziata, bool finita) {
    if (_selectedSegment == 'Gironi') {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
          child: Row(children: [
            Text(
              'Girone $_selectedGirone',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Ottavi') {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '1° - 16° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Quarti' &&
        (codiceP == 'q0' ||
            codiceP == 'q1' ||
            codiceP == 'q2' ||
            codiceP == 'q3')) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '1° - 8° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Quarti' &&
        (codiceP == 'q4' ||
            codiceP == 'q5' ||
            codiceP == 'q6' ||
            codiceP == 'q7')) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '9° - 16° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Semifinali' &&
        (codiceP == 's0' || codiceP == 's1')) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '1° - 4° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Semifinali' &&
        (codiceP == 's2' || codiceP == 's3')) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '5° - 8° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Semifinali' &&
        (codiceP == 's4' || codiceP == 's5')) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '9° - 12° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Semifinali' &&
        (codiceP == 's6' || codiceP == 's7')) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '13° - 16° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Finali' && codiceP == 'f0') {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '1° - 2° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Finali' && codiceP == 'f1') {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '3° - 4° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Finali' && codiceP == 'f2') {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '5° - 6° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Finali' && codiceP == 'f3') {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '7° - 8° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Finali' && codiceP == 'f4') {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '9° - 10° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Finali' && codiceP == 'f5') {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '11° - 12° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Finali' && codiceP == 'f6') {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '13° - 14° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    if (_selectedSegment == 'Finali' && codiceP == 'f7') {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(children: [
            const Text(
              '15° - 16° posto',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            iniziata && !finita
                ? const Row(children: [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 178, 28, 28),
                      radius: 7,
                    ),
                    SizedBox(width: 4),
                    Text("Live")
                  ])
                : Container(),
            const SizedBox(width: 16),
            widget.ccRole == 'staff' &&
                    (widget.nome == arbitro || widget.nome == refertista)
                ? Expanded(
                    child: Divider(
                      color:
                          (widget.nome == arbitro && widget.nome == refertista)
                              ? const Color.fromARGB(255, 58, 57, 57)
                              : widget.nome == arbitro
                                  ? const Color.fromARGB(255, 178, 28, 28)
                                  : const Color.fromARGB(255, 37, 201, 43),
                      thickness: 5,
                    ),
                  )
                : Container()
          ]));
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: [
            const SizedBox(height: 10),
            Wrap(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SegmentedButton<String>(
                    selectedIcon: const Icon(Icons.check),
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'Gironi',
                        label: Text('Gir', style: TextStyle(fontSize: 10)),
                      ),
                      ButtonSegment<String>(
                        value: 'Ottavi',
                        label: Text('Ott', style: TextStyle(fontSize: 10)),
                      ),
                      ButtonSegment<String>(
                        value: 'Quarti',
                        label: Text('Qua', style: TextStyle(fontSize: 10)),
                      ),
                      ButtonSegment<String>(
                        value: 'Semifinali',
                        label: Text('Sem', style: TextStyle(fontSize: 10)),
                      ),
                      ButtonSegment<String>(
                        value: 'Finali',
                        label: Text('Fin', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                    selected: <String>{_selectedSegment},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedSegment = newSelection.first;
                        _streamPartite = _getPartite();
                      });
                    },
                  ),
                ]),
                widget.ccRole == 'staff'
                    ? const Column(
                        children: [
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        Color.fromARGB(255, 178, 28, 28),
                                    radius: 7,
                                  ),
                                  SizedBox(
                                    width: 6,
                                  ),
                                  Text('Arbitro',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic)),
                                ]),
                                SizedBox(
                                  width: 16,
                                ),
                                Row(children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        Color.fromARGB(255, 37, 201, 43),
                                    radius: 7,
                                  ),
                                  SizedBox(
                                    width: 6,
                                  ),
                                  Text('Refertista',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic)),
                                ]),
                                SizedBox(
                                  width: 16,
                                ),
                                Row(children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        Color.fromARGB(255, 58, 57, 57),
                                    radius: 7,
                                  ),
                                  SizedBox(
                                    width: 6,
                                  ),
                                  Text('Entrambi',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic)),
                                ]),
                              ]),
                        ],
                      )
                    : Container(),
              ],
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _streamPartite,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Errore: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Nessuna partita trovata', style: TextStyle(fontSize: 19, color: Colors.black54)));
                  }

                  final partite = snapshot.data!;
                  final groupedPartite = <String, List<Map<String, dynamic>>>{};

                  for (var partita in partite) {
                    final girone = partita['girone'] ?? partita['codice'];
                    if (!groupedPartite.containsKey(girone)) {
                      groupedPartite[girone] = [];
                    }
                    groupedPartite[girone]!.add(partita);
                  }

                  return SingleChildScrollView(child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 15),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...groupedPartite.entries.map((entry) {
                              final codiceP = entry.key;
                              final partiteGirone = entry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...partiteGirone.map((partita) {
                                    final logoCasa =
                                        _squadreLoghi[partita['casa']] ?? '';
                                    final logoFuori =
                                        _squadreLoghi[partita['fuori']] ?? '';

                                    int golCasa = 0;
                                    int golFuori = 0;
                                    List<Map<String, dynamic>> marcatori =
                                        List<Map<String, dynamic>>.from(
                                            partita['marcatori'] ?? []);
                                    for (var marcatore in marcatori) {
                                      if (marcatore['dove'] == 'casa' &&
                                          marcatore['cosa'] == 'gol') {
                                        golCasa++;
                                      } else if (marcatore['dove'] == 'fuori' &&
                                          marcatore['cosa'] == 'gol') {
                                        golFuori++;
                                      }
                                    }

                                    int golRigoriCasa = 0;
                                    int golRigoriFuori = 0;
                                    if (partita['tipo'] != 'girone' &&
                                        partita['boolRigori'] == true) {
                                      List<String> rigoriCasa =
                                          List<String>.from(
                                              partita['rigoriCasa'] ?? []);
                                      List<String> rigoriFuori =
                                          List<String>.from(
                                              partita['rigoriFuori'] ?? []);
                                      for (var rigore in rigoriCasa) {
                                        if (rigore == 'segnato') {
                                          golRigoriCasa++;
                                        }
                                      }
                                      for (var rigore in rigoriFuori) {
                                        if (rigore == 'segnato') {
                                          golRigoriFuori++;
                                        }
                                      }
                                    }

                                    return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                              onTap: partita['casa'] != '' &&
                                                      partita['fuori'] != ''
                                                  ? () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              CCModificaPartita(
                                                            casa:
                                                                partita['casa'],
                                                            fuori: partita[
                                                                'fuori'],
                                                            logocasa: logoCasa,
                                                            logofuori:
                                                                logoFuori,
                                                            data: '25/04/2025',
                                                            orario: partita[
                                                                'orario'],
                                                            campo: partita[
                                                                'campo'],
                                                            arbitro: partita[
                                                                'arbitro'],
                                                            refertista: partita['refertista'],
                                                            nome: widget.nome,
                                                            girone: partita[
                                                                    'girone'] ??
                                                                '',
                                                            iniziata: partita[
                                                                'iniziata'],
                                                            finita: partita[
                                                                'finita'],
                                                            tipo:
                                                                partita['tipo'],
                                                            codice: partita[
                                                                    'codice'] ??
                                                                '',
                                                            ccRole:
                                                                widget.ccRole,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  : null,
                                              child: Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15.0),
                                                  ),
                                                  elevation: 5,
                                                  child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16.0),
                                                      child: Column(
                                                        children: [
                                                          Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      logoCasa
                                                                              .isNotEmpty
                                                                          ? Image
                                                                              .network(
                                                                              logoCasa,
                                                                              width: 35,
                                                                              height: 35,
                                                                            )
                                                                          : IconButton(
                                                                              icon: const FaIcon(FontAwesomeIcons.shieldHalved),
                                                                              onPressed: () {}),
                                                                      const SizedBox(
                                                                          width:
                                                                              6),
                                                                      partita['casa'] !=
                                                                              ''
                                                                          ? Text(
                                                                              partita['casa'],
                                                                              style: const TextStyle(fontSize: 17))
                                                                          : const Text('Da definire', style: TextStyle(fontSize: 17)),
                                                                    ],
                                                                  ),
                                                                  partita['iniziata'] ||
                                                                          partita[
                                                                              'finita']
                                                                      ? Row(
                                                                          children: [
                                                                            Text('$golCasa',
                                                                                style: const TextStyle(fontSize: 21)),
                                                                            partita['tipo'] != 'girone' && partita['boolRigori']
                                                                                ? Text(' ($golRigoriCasa)', style: const TextStyle(fontSize: 15))
                                                                                : Container()
                                                                          ],
                                                                        )
                                                                      : Row(
                                                                          children: [
                                                                            partita['orario'] == ''
                                                                                ? const Icon(Icons.access_time, size: 22)
                                                                                : Container(),
                                                                            Text(partita['orario'] != '' ? '${partita['orario']}' : '',
                                                                                style: const TextStyle(fontSize: 18)),
                                                                          ],
                                                                        ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  height: 8),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Row(
                                                                      children: [
                                                                        logoFuori.isNotEmpty
                                                                            ? Image.network(
                                                                                logoFuori,
                                                                                width: 35,
                                                                                height: 35,
                                                                              )
                                                                            : IconButton(
                                                                                icon: const FaIcon(FontAwesomeIcons.shieldHalved),
                                                                                onPressed: () {},
                                                                              ),
                                                                        const SizedBox(
                                                                            width:
                                                                                6),
                                                                        partita['fuori'] !=
                                                                                ''
                                                                            ? Text(partita['fuori'],
                                                                                style: const TextStyle(fontSize: 17))
                                                                            : const Text('Da definire', style: TextStyle(fontSize: 17)),
                                                                      ]),
                                                                  partita['iniziata'] ||
                                                                          partita[
                                                                              'finita']
                                                                      ? Row(
                                                                          children: [
                                                                              Text('$golFuori', style: const TextStyle(fontSize: 21)),
                                                                              partita['tipo'] != 'girone' && partita['boolRigori'] ? Text(' ($golRigoriFuori)', style: const TextStyle(fontSize: 15)) : Container()
                                                                            ])
                                                                      : Row(
                                                                          children: [
                                                                            partita['campo'] == ''
                                                                                ? const Icon(Icons.location_on_outlined, size: 22)
                                                                                : Container(),
                                                                            Text(partita['campo'].length > 1 ? '${partita['campo']}' : '',
                                                                                style: const TextStyle(fontSize: 18)),
                                                                          ],
                                                                        ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  height: 8),
                                                              _widgetText(
                                                                  codiceP,
                                                                  partita[
                                                                      'arbitro'],
                                                                  partita[
                                                                      'refertista'],
                                                                  partita[
                                                                      'iniziata'],
                                                                  partita[
                                                                      'finita'])
                                                            ],
                                                          ),
                                                        ],
                                                      ))))
                                        ]);
                                  }),
                                ],
                              );
                            }),
                            _selectedSegment == 'Ottavi' &&
                                    widget.ccRole == 'staff' && (widget.nome=='Francesco Martignoni' || widget.nome=='Cristian Ciardelli' || widget.nome=='Luca Bricchi' || widget.nome=='Michele Agostini')
                                ? Column(children: [
                                    const SizedBox(height: 10),
                                    Center(
                                        child: ElevatedButton(
                                      onPressed: () {
                                        _pulisci('Ottavi');
                                      },
                                      child: const Text('Pulisci Ottavi'),
                                    ))
                                  ])
                                : _selectedSegment == 'Quarti' &&
                                        widget.ccRole == 'staff' && (widget.nome=='Francesco Martignoni' || widget.nome=='Cristian Ciardelli' || widget.nome=='Luca Bricchi' || widget.nome=='Michele Agostini')
                                    ? Column(children: [
                                        const SizedBox(height: 10),
                                        Center(
                                            child: ElevatedButton(
                                          onPressed: () {
                                            _pulisci('Quarti');
                                          },
                                          child: const Text('Pulisci Quarti'),
                                        ))
                                      ])
                                    : _selectedSegment == 'Semifinali' &&
                                            widget.ccRole == 'staff' && (widget.nome=='Francesco Martignoni' || widget.nome=='Cristian Ciardelli' || widget.nome=='Luca Bricchi' || widget.nome=='Michele Agostini')
                                        ? Column(children: [
                                            const SizedBox(height: 10),
                                            Center(
                                                child: ElevatedButton(
                                              onPressed: () {
                                                _pulisci('Semifinali');
                                              },
                                              child: const Text(
                                                  'Pulisci Semifinali'),
                                            ))
                                          ])
                                        : _selectedSegment == 'Finali' &&
                                                widget.ccRole == 'staff' && (widget.nome=='Francesco Martignoni' || widget.nome=='Cristian Ciardelli' || widget.nome=='Luca Bricchi' || widget.nome=='Michele Agostini')
                                            ? Column(children: [
                                                const SizedBox(height: 10),
                                                Center(
                                                    child: ElevatedButton(
                                                  onPressed: () {
                                                    _pulisci('Finali');
                                                  },
                                                  child: const Text(
                                                      'Pulisci Finali'),
                                                ))
                                              ])
                                            : Container()
                          ])));
                },
            ))
          ],
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_selectedSegment == 'Gironi') ...[
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedGirone == 'A'
                        ? Colors.black
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: FloatingActionButton(
                  heroTag: 'gironeA',
                  onPressed: () {
                    setState(() {
                      _selectedGirone = 'A';
                      _streamPartite = _getPartite();
                    });
                  },
                  shape: const CircleBorder(),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Text('A', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedGirone == 'B'
                        ? Colors.black
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: FloatingActionButton(
                  heroTag: 'gironeB',
                  onPressed: () {
                    setState(() {
                      _selectedGirone = 'B';
                      _streamPartite = _getPartite();
                    });
                  },
                  shape: const CircleBorder(),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Text('B', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedGirone == 'C'
                        ? Colors.black
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: FloatingActionButton(
                  heroTag: 'gironeC',
                  onPressed: () {
                    setState(() {
                      _selectedGirone = 'C';
                      _streamPartite = _getPartite();
                    });
                  },
                  shape: const CircleBorder(),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Text('C', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedGirone == 'D'
                        ? Colors.black
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: FloatingActionButton(
                  heroTag: 'gironeD',
                  onPressed: () {
                    setState(() {
                      _selectedGirone = 'D';
                      _streamPartite = _getPartite();
                    });
                  },
                  shape: const CircleBorder(),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Text('D', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (widget.ccRole == 'staff')
              FloatingActionButton(
                heroTag: 'addButton',
                onPressed: () {
                  _selectedSegment == 'Gironi'
                      ? Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const CCnuovaPartitaGironi()),
                        )
                      : Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  CCnuovaPartitaOttavi(tipo: _selectedSegment)),
                        );
                },
                shape: const CircleBorder(),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                child: const Icon(Icons.add),
              ),
          ],
        ));
  }
}
