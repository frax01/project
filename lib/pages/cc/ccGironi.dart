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
                                  rows: _buildDataRowsSquadre(doc['squadre']),
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
                                  rows: _buildDataRows(
                                      doc.data() as Map<String, dynamic>),
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

  List<DataRow> _buildDataRowsSquadre(List<dynamic> squadre) {
    return List<DataRow>.generate(squadre.length, (index) {
      return DataRow(
        cells: [
          DataCell(
            Row(
              children: [
                index==0? const FaIcon(
                  FontAwesomeIcons.medal,
                  color: Colors.amber,
                  size: 22,
                )
                : index==1? const FaIcon(
                  FontAwesomeIcons.medal,
                  color: Colors.grey,
                  size: 22,
                )
                : index==2? const FaIcon(
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
                  '  ${squadre[index]}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 17),
                  maxLines: 1,
                ),
            ],)
          ),
        ],
      );
    });
  }

  List<DataRow> _buildDataRows(Map<String, dynamic> doc) {
    final Map<String, int> partite = Map<String, int>.from(doc['partiteG']);
    final Map<String, int> goalFatti = Map<String, int>.from(doc['goalFatti']);
    final Map<String, int> goalSubiti = Map<String, int>.from(doc['goalSubiti']);
    final Map<String, int> diffReti = Map<String, int>.from(doc['diffReti']);
    final Map<String, int> punti = Map<String, int>.from(doc['punti']);

    return partite.keys.map((squadra) {
      return DataRow(
        cells: [
          DataCell(
            SelectableText(
              partite[squadra].toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          DataCell(
            SelectableText(
              ' ${goalFatti[squadra].toString()}:${goalSubiti[squadra].toString()}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          DataCell(
            SelectableText(
              ' ${diffReti[squadra].toString()}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          DataCell(
            SelectableText(
              ' ${punti[squadra].toString()}',
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
