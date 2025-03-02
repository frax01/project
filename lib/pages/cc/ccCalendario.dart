import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ccNuovaPartitaGironi.dart';
import 'ccNuovaPartitaOttavi.dart';
import 'ccModificaPartita.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CCCalendario extends StatefulWidget {
  const CCCalendario({
    super.key,
  });

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
  }

  Map<String, String> _squadreLoghi = {};

  Future<void> _loadSquadre() async {
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
            .map((doc) => doc.data() as Map<String, dynamic>)
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
            .map((doc) => doc.data() as Map<String, dynamic>)
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
            .map((doc) => doc.data() as Map<String, dynamic>)
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
            .map((doc) => doc.data() as Map<String, dynamic>)
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
            .map((doc) => doc.data() as Map<String, dynamic>)
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

  Future<void> _pulisci(String sezione) async {
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
        'data': sezione=='Finali' ? '27/04/2025' : '26/04/2025',
        'iniziata': false,
        'finita': false,
        'marcatori': [],
        'tipo': '${sezione[0].toLowerCase()}${sezione.substring(1)}',
        'codice': doc.id,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<String>(
                        selectedIcon: const Icon(Icons.check),
                        segments: const <ButtonSegment<String>>[
                          ButtonSegment<String>(
                            value: 'Gironi',
                            label: Text('Gir', style: TextStyle(fontSize: 12)),
                          ),
                          ButtonSegment<String>(
                            value: 'Ottavi',
                            label: Text('Ott', style: TextStyle(fontSize: 12)),
                          ),
                          ButtonSegment<String>(
                            value: 'Quarti',
                            label: Text('Qua', style: TextStyle(fontSize: 12)),
                          ),
                          ButtonSegment<String>(
                            value: 'Semifinali',
                            label: Text('Sem', style: TextStyle(fontSize: 12)),
                          ),
                          ButtonSegment<String>(
                            value: 'Finali',
                            label: Text('Fin', style: TextStyle(fontSize: 12)),
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
                      if (_selectedSegment == 'Gironi')
                        SegmentedButton<String>(
                          selectedIcon: const Icon(Icons.check),
                          segments: const <ButtonSegment<String>>[
                            ButtonSegment<String>(
                              value: 'A',
                              label: Text('A', style: TextStyle(fontSize: 12)),
                            ),
                            ButtonSegment<String>(
                              value: 'B',
                              label: Text('B', style: TextStyle(fontSize: 12)),
                            ),
                            ButtonSegment<String>(
                              value: 'C',
                              label: Text('C', style: TextStyle(fontSize: 12)),
                            ),
                            ButtonSegment<String>(
                              value: 'D',
                              label: Text('D', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                          selected: <String>{_selectedGirone},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _selectedGirone = newSelection.first;
                              _streamPartite = _getPartite();
                            });
                          },
                        ),
                    ])),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _streamPartite,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Errore: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nessuna partita trovata'));
                }

                final partite = snapshot.data!;
                final groupedPartite = <String, List<Map<String, dynamic>>>{};

                String? lastTurno;
                bool divider = false;

                for (var partita in partite) {
                  final girone = partita['girone'] ?? partita['codice'];
                  if (!groupedPartite.containsKey(girone)) {
                    groupedPartite[girone] = [];
                  }
                  groupedPartite[girone]!.add(partita);
                }

                int counter=-1;

                return Padding(
                    padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...groupedPartite.entries.map((entry) {
                            counter++;
                            final codiceP = entry.key;
                            final partiteGirone = entry.value;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_selectedSegment == 'Ottavi' &&
                                    codiceP == 'o0')
                                  const Text(
                                    '1° - 16° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Quarti' &&
                                    codiceP == 'q0')
                                  const Text(
                                    '1° - 8° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Quarti' &&
                                    codiceP == 'q4')
                                  const Text(
                                    '9° - 16° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Semifinali' &&
                                    codiceP == 's0')
                                  const Text(
                                    '1° - 4° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Semifinali' &&
                                    codiceP == 's2')
                                  const Text(
                                    '5° - 8° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Semifinali' &&
                                    codiceP == 's4')
                                  const Text(
                                    '9° - 12° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Semifinali' &&
                                    codiceP == 's6')
                                  const Text(
                                    '13° - 16° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Finali' &&
                                    codiceP == 'f0')
                                  const Text(
                                    '1° - 2° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Finali' &&
                                    codiceP == 'f1')
                                  const Text(
                                    '3° - 4° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Finali' &&
                                    codiceP == 'f2')
                                  const Text(
                                    '5° - 6° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Finali' &&
                                    codiceP == 'f3')
                                  const Text(
                                    '7° - 8° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Finali' &&
                                    codiceP == 'f4')
                                  const Text(
                                    '9° - 10° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Finali' &&
                                    codiceP == 'f5')
                                  const Text(
                                    '11° - 12° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Finali' &&
                                    codiceP == 'f6')
                                  const Text(
                                    '13° - 14° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_selectedSegment == 'Finali' &&
                                    codiceP == 'f7')
                                  const Text(
                                    '15° - 16° posto',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const SizedBox(height: 8),
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
                                    if (marcatore['dove'] == 'casa' && marcatore['cosa'] == 'gol') {
                                      golCasa++;
                                    } else if (marcatore['dove'] == 'fuori' && marcatore['cosa'] == 'gol') {
                                      golFuori++;
                                    }
                                  }

                                  String turno = '';
                                  Widget turnoWidget = Container();
                                  divider = false;
                                  if (_selectedSegment == 'Gironi') {
                                    turno = partita['turno'];
                                    turnoWidget = Container();
                                    if (lastTurno != turno) {
                                      divider = true;
                                      lastTurno = turno;
                                      //turnoWidget = Padding(
                                      //  padding: const EdgeInsets.fromLTRB(
                                      //      0, 0, 0, 16),
                                      //  child: Text(
                                      //    'Turno $turno',
                                      //    style: const TextStyle(
                                      //      fontSize: 22,
                                      //      fontWeight: FontWeight.bold,
                                      //    ),
                                      //  ),
                                      //);
                                    }
                                  }

                                  return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        turnoWidget,
                                        InkWell(
                                            onTap: partita['casa']!='' || partita['fuori']!='' ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CCModificaPartita(
                                                    casa: partita['casa'],
                                                    fuori: partita['fuori'],
                                                    logocasa: logoCasa,
                                                    logofuori: logoCasa,
                                                    data: '25/04/2025',
                                                    orario: partita['orario'],
                                                    campo: partita['campo'],
                                                    arbitro: partita['arbitro'],
                                                    girone:
                                                        partita['girone'] ?? '',
                                                    iniziata:
                                                        partita['iniziata'],
                                                    finita: partita['finita'],
                                                    tipo: partita['tipo'],
                                                    codice:
                                                        partita['codice'] ?? '',
                                                  ),
                                                ),
                                              );
                                            } : null,
                                            child: Column(
                                              children: [
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            logoCasa.isNotEmpty
                                                            ? Image.network(
                                                                logoCasa,
                                                                width: 40,
                                                                height: 40,
                                                              )
                                                            : IconButton(
                                                              icon: const FaIcon(FontAwesomeIcons.shieldHalved),
                                                              onPressed: () {
                                                              },
                                                            ),
                                                            const SizedBox(width: 6),
                                                            partita['casa']!='' ? Text(partita['casa'], style: const TextStyle(fontSize: 20)) : const Text('Da definire', style: TextStyle(fontSize: 22)),
                                                          ],
                                                        ),
                                                        partita['iniziata'] || partita['finita']
                                                        ? Text('$golCasa', style: const TextStyle(fontSize: 24))
                                                        : Row(
                                                            children: [
                                                              const Icon(Icons.access_time, size: 30),
                                                              Text(partita['orario'] !='' ? '${partita['orario']}' : '', style: const TextStyle(fontSize:22)),
                                                            ],
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            logoFuori.isNotEmpty
                                                            ? Image.network(
                                                                logoFuori,
                                                                width: 40,
                                                                height: 40,
                                                              )
                                                            : IconButton(
                                                              icon: const FaIcon(FontAwesomeIcons.shieldHalved),
                                                              onPressed: () {
                                                              },
                                                            ),
                                                            const SizedBox(width: 6),
                                                            partita['fuori']!='' ? Text(partita['fuori'], style: const TextStyle(fontSize: 20)) : const Text('Da definire', style: TextStyle(fontSize: 22)),
                                                          ]
                                                        ),
                                                        partita['iniziata'] || partita['finita']
                                                        ? Text('$golFuori', style: const TextStyle(fontSize: 24))
                                                        : Row(
                                                            children: [
                                                              const Icon(Icons.location_on_outlined, size: 30),
                                                              Text(partita['campo'].length > 1 ? '${partita['campo']}' : '', style: const TextStyle(fontSize: 22)),
                                                            ],
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                //_selectedSegment == 'Gironi' &&
                                                //        !divider
                                                //    ? const SizedBox(height: 30)
                                                //    : 
                                                    //counter!=8 ? 
                                                    const Divider(
                                                        height: 30,
                                                        thickness: 1) 
                                                    //: Container()
                                              ],
                                            ))
                                      ]);
                                }).toList(),
                              ],
                            );
                          }).toList(),
                          _selectedSegment == 'Ottavi'
                          ? Center(child:ElevatedButton(
                              onPressed: () {
                                _pulisci('Ottavi');
                              },
                              child: const Text('Pulisci Ottavi'),
                            ))
                          : _selectedSegment == 'Quarti'
                            ? Center(child:ElevatedButton(
                                onPressed: () {
                                  _pulisci('Quarti');
                                },
                                child: const Text('Pulisci Quarti'),
                              ))
                            : _selectedSegment == 'Semifinali'
                                ? Center(child:ElevatedButton(
                                    onPressed: () {
                                      _pulisci('Semifinali');
                                    },
                                    child: const Text('Pulisci Semifinali'),
                                  ))
                            : Center(child:ElevatedButton(
                                onPressed: () {
                                  _pulisci('Finali');
                                },
                                child: const Text('Pulisci Finali'),
                              )
                            )
                          ]
                        )
                      );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedSegment == 'Gironi' || _selectedSegment == 'Ottavi' ? 
      FloatingActionButton(
        onPressed: () {
          _selectedSegment == 'Gironi'
              ? Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CCnuovaPartitaGironi()),
                )
              : Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CCnuovaPartitaOttavi()),
                );
        },
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ) : null
    );
  }
}
