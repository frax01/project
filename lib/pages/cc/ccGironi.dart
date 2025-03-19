import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CCGironi extends StatefulWidget {
  const CCGironi({super.key});

  @override
  State<CCGironi> createState() => _CCGironiState();
}

class _CCGironiState extends State<CCGironi> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, Map<String, Map<String, int>>> scontriDirettiCache = {};
  late Future<void> _scontriDirettiFuture;
  Map<String, String> logo = {};

  @override
  void initState() {
    super.initState();
    _loadLogo();
    _scontriDirettiFuture = _loadScontriDiretti();
  }

  Future<void> _loadLogo() async {
    final querySnapshot = await _firestore.collection('ccSquadre').get();
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final squadre = List<Map<String, dynamic>>.from(data['squadre']);
      for (var squadra in squadre) {
        logo[squadra['squadra']] = squadra['logo'];
      }
    }
    setState(() {});
  }

  Future<void> _loadScontriDiretti() async {
    final querySnapshot = await _firestore.collection('ccPartiteGironi').get();
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final girone = data['girone'];
      final squadraCasa = data['casa'];
      final squadraFuori = data['fuori'];
      final marcatori = List<Map<String, dynamic>>.from(data['marcatori']);

      final golCasa = marcatori
          .where((m) => m['cosa'] == 'gol' && m['dove'] == 'casa')
          .length;
      final golFuori = marcatori
          .where((m) => m['cosa'] == 'gol' && m['dove'] == 'fuori')
          .length;

      if (!scontriDirettiCache.containsKey(girone)) {
        scontriDirettiCache[girone] = {};
      }
      if (!scontriDirettiCache[girone]!.containsKey(squadraCasa)) {
        scontriDirettiCache[girone]![squadraCasa] = {};
      }
      if (!scontriDirettiCache[girone]!.containsKey(squadraFuori)) {
        scontriDirettiCache[girone]![squadraFuori] = {};
      }

      if (golCasa > golFuori) {
        scontriDirettiCache[girone]![squadraCasa]![squadraFuori] =
            1; // Casa vince
        scontriDirettiCache[girone]![squadraFuori]![squadraCasa] =
            -1; // Fuori perde
      } else if (golFuori > golCasa) {
        scontriDirettiCache[girone]![squadraCasa]![squadraFuori] =
            -1; // Casa perde
        scontriDirettiCache[girone]![squadraFuori]![squadraCasa] =
            1; // Fuori vince
      } else {
        scontriDirettiCache[girone]![squadraCasa]![squadraFuori] =
            0; // Pareggio
        scontriDirettiCache[girone]![squadraFuori]![squadraCasa] =
            0; // Pareggio
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
            future: _scontriDirettiFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Errore: ${snapshot.error}'));
              } else {
                return StreamBuilder(
                  stream: _firestore.collection('ccGironi').snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('Nessun girone presente',
                              style: TextStyle(fontSize: 20)));
                    }
                    return SingleChildScrollView(
                      child: Column(
                        children: snapshot.data!.docs.map((doc) {
                          final squadreData = _buildSquadreData(
                              doc.data() as Map<String, dynamic>, doc.id);
                          return Card(
                            margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            shadowColor: Colors.black54,
                            elevation: 7,
                            child: Column(
                              children: [
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: DataTable(
                                            dividerThickness: 0,
                                            columns: [
                                              DataColumn(
                                                label: SelectableText(
                                                  'GIRONE ${doc['nome']}',
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                            rows: _buildDataRowsSquadre(
                                                squadreData),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 50),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: DataTable(
                                            dividerThickness: 0,
                                            columnSpacing: 0,
                                            horizontalMargin: 0,
                                            columns: const [
                                              DataColumn(
                                                label: SelectableText(
                                                  'G',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              DataColumn(
                                                label: SelectableText(
                                                  'GOL',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              DataColumn(
                                                label: SelectableText(
                                                  'DR',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              DataColumn(
                                                label: SelectableText(
                                                  'PT',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                            rows: _buildDataRows(squadreData),
                                          ),
                                        ),
                                      )
                                    ])
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              }
            }));
  }

  List<Map<String, dynamic>> _buildSquadreData(
      Map<String, dynamic> doc, String gironeId) {
    final Map<String, int> partite = Map<String, int>.from(doc['partiteG']);
    final Map<String, int> goalFatti = Map<String, int>.from(doc['goalFatti']);
    final Map<String, int> goalSubiti =
        Map<String, int>.from(doc['goalSubiti']);
    final Map<String, int> diffReti = Map<String, int>.from(doc['diffReti']);
    final Map<String, int> punti = Map<String, int>.from(doc['punti']);
    final Map<String, int> cartGialli =
        Map<String, int>.from(doc['cartGialli']);

    // Crea una lista di squadre con i loro dati
    List<Map<String, dynamic>> squadreData = partite.keys.map((squadra) {
      return {
        'squadra': squadra,
        'partite': partite[squadra],
        'goalFatti': goalFatti[squadra],
        'goalSubiti': goalSubiti[squadra],
        'diffReti': diffReti[squadra],
        'punti': punti[squadra],
        'cartGialli': cartGialli[squadra],
      };
    }).toList();

    final scontriDiretti = scontriDirettiCache[doc['nome']] ?? {};

    squadreData.sort((a, b) {
      int puntiComparison = b['punti'].compareTo(a['punti']);
      if (puntiComparison != 0) return puntiComparison;

      int scontroDirettoComparison =
          _compareScontriDiretti(a, b, scontriDiretti);
      if (scontroDirettoComparison != 0) return scontroDirettoComparison;

      int diffRetiComparison = b['diffReti'].compareTo(a['diffReti']);
      if (diffRetiComparison != 0) return diffRetiComparison;

      int goalComparison = b['goalFatti'].compareTo(a['goalFatti']);
      if (goalComparison != 0) return goalComparison;

      return a['cartGialli'].compareTo(b['cartGialli']);
    });

    return squadreData;
  }

  int _compareScontriDiretti(Map<String, dynamic> a, Map<String, dynamic> b,
      Map<String, Map<String, int>> scontriDiretti) {
    final squadraA = a['squadra'];
    final squadraB = b['squadra'];

    if (scontriDiretti.containsKey(squadraB) &&
        scontriDiretti[squadraB]!.containsKey(squadraA)) {
      return scontriDiretti[squadraB]![squadraA]!;
    }

    return 0;
  }

  List<DataRow> _buildDataRowsSquadre(List<Map<String, dynamic>> squadreData) {
    return List<DataRow>.generate(squadreData.length, (index) {
      return DataRow(
        cells: [
          DataCell(
            Row(
              children: [
                logo[squadreData[index]['squadra']] != ''
                    ? Image.network(
                        logo[squadreData[index]['squadra']]!,
                        width: 25,
                        height: 25,
                      )
                    : const FaIcon(FontAwesomeIcons.shieldHalved),
                Text(
                  '  ${squadreData[index]['squadra']}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 17),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  List<DataRow> _buildDataRows(List<Map<String, dynamic>> squadreData) {
    return squadreData.map((squadraData) {
      return DataRow(
        cells: [
          DataCell(
            SelectableText(
              squadraData['partite'].toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          DataCell(
            SelectableText(
              ' ${squadraData['goalFatti'].toString()}:${squadraData['goalSubiti'].toString()}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          DataCell(
            SelectableText(
              ' ${squadraData['diffReti'].toString()}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          DataCell(
            SelectableText(
              ' ${squadraData['punti'].toString()}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }).toList();
  }
}
