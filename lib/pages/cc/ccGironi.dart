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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _firestore.collection('ccGironi').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nessun girone presente'));
          }
          return SingleChildScrollView(
            child: Column(
              children: snapshot.data!.docs.map((doc) {
                final squadreData = _buildSquadreData(doc.data() as Map<String, dynamic>);
                return Card(
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 15),
                  shadowColor: Colors.black54,
                  elevation: 25,
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  rows: _buildDataRowsSquadre(squadreData),
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
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SelectableText(
                                        'GOL',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SelectableText(
                                        'DR',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SelectableText(
                                        'PT',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
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
      ),
    );
  }

  List<Map<String, dynamic>> _buildSquadreData(Map<String, dynamic> doc) {
    final Map<String, int> partite = Map<String, int>.from(doc['partiteG']);
    final Map<String, int> goalFatti = Map<String, int>.from(doc['goalFatti']);
    final Map<String, int> goalSubiti = Map<String, int>.from(doc['goalSubiti']);
    final Map<String, int> diffReti = Map<String, int>.from(doc['diffReti']);
    final Map<String, int> punti = Map<String, int>.from(doc['punti']);

    // Crea una lista di squadre con i loro dati
    List<Map<String, dynamic>> squadreData = partite.keys.map((squadra) {
      return {
        'squadra': squadra,
        'partite': partite[squadra],
        'goalFatti': goalFatti[squadra],
        'goalSubiti': goalSubiti[squadra],
        'diffReti': diffReti[squadra],
        'punti': punti[squadra],
      };
    }).toList();

    // Ordina le squadre in base ai criteri specificati
    squadreData.sort((a, b) {
      int puntiComparison = b['punti'].compareTo(a['punti']);
      if (puntiComparison != 0) return puntiComparison;

      int diffRetiComparison = b['diffReti'].compareTo(a['diffReti']);
      if (diffRetiComparison != 0) return diffRetiComparison;

      int goalFattiComparison = b['goalFatti'].compareTo(a['goalFatti']);
      if (goalFattiComparison != 0) return goalFattiComparison;

      return a['goalSubiti'].compareTo(b['goalSubiti']);
    });

    return squadreData;
  }

  List<DataRow> _buildDataRowsSquadre(List<Map<String, dynamic>> squadreData) {
    return List<DataRow>.generate(squadreData.length, (index) {
      return DataRow(
        cells: [
          DataCell(
            Row(
              children: [
                index == 0
                    ? const FaIcon(
                        FontAwesomeIcons.medal,
                        color: Colors.amber,
                        size: 22,
                      )
                    : index == 1
                        ? const FaIcon(
                            FontAwesomeIcons.medal,
                            color: Colors.grey,
                            size: 22,
                          )
                        : index == 2
                            ? const FaIcon(
                                FontAwesomeIcons.medal,
                                color: Colors.brown,
                                size: 22,
                              )
                            : const FaIcon(
                                FontAwesomeIcons.medal,
                                color: Colors.black,
                                size: 22,
                              ),
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

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questo girone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              _firestore.collection('ccGironi').doc(docId).delete();
              Navigator.of(context).pop();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
