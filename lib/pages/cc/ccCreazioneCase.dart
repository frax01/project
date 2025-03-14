import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';
//import 'package:pdf/pdf.dart';
//import 'package:pdf/widgets.dart' as pw;
//import 'package:printing/printing.dart

class CcCreazioneCase extends StatefulWidget {
  @override
  _CcCreazioneCaseState createState() => _CcCreazioneCaseState();
}

class _CcCreazioneCaseState extends State<CcCreazioneCase> {
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _postiController = TextEditingController();
  String? _selectedClub;
  List<String> _clubs = [];

  @override
  void initState() {
    super.initState();
    _fetchClubs();
  }

  Future<void> _fetchClubs() async {
    final QuerySnapshot result =
        await FirebaseFirestore.instance.collection('ccSquadre').get();
    final List<DocumentSnapshot> documents = result.docs;
    setState(() {
      _clubs = documents.map((doc) => doc['club'] as String).toList();
    });
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

  Future<void> _showDialog(
      {String? numero,
      String? posti,
      String? club,
      bool isEditing = false}) async {
    if (isEditing) {
      _numeroController.text = numero!;
      _postiController.text = posti!;
      _selectedClub = club;
    } else {
      _numeroController.clear();
      _postiController.clear();
      _selectedClub = null;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Modifica Casa' : 'Crea Casa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _numeroController,
                decoration: InputDecoration(labelText: 'Numero casa'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _postiController,
                decoration: InputDecoration(labelText: 'Numero di posti'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedClub,
                hint: Text('Seleziona Club'),
                items: _clubs.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedClub = newValue;
                  });
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                _showLoadingDialog();
                if (_numeroController.text.isEmpty ||
                    _postiController.text.isEmpty) {
                  print("1");
                  //Navigator.of(context).pop();
                  return;
                }

                final newNumero = _numeroController.text;
                final posti = int.parse(_postiController.text);
                final club = _selectedClub ?? '';

                final docRef = FirebaseFirestore.instance
                    .collection('ccCase')
                    .doc(newNumero);

                if (isEditing) {
                  final doc = await docRef.get();
                  if (doc.exists) {
                    final List<dynamic> persone = doc['persone'];
                    for (var persona in persone) {
                      final squadra = persona['squadra'];
                      final nome = persona['nome'];
                      final squadraDoc = FirebaseFirestore.instance
                          .collection('ccIscrizioniSquadre')
                          .doc(squadra);
                      final squadraData = await squadraDoc.get();
                      final giocatori = List<Map<String, dynamic>>.from(
                          squadraData['giocatori']);
                      final giocatore =
                          giocatori.firstWhere((g) => g['nome'] == nome);
                      giocatore['appartamento'] = '';
                      await squadraDoc.update({'giocatori': giocatori});
                    }
                    await docRef.update({
                      'posti': posti,
                      'club': club,
                      'persone': [],
                    });
                  } else {
                    await FirebaseFirestore.instance
                        .collection('ccCase')
                        .doc(numero)
                        .delete();
                    await FirebaseFirestore.instance
                        .collection('ccCase')
                        .doc(newNumero)
                        .set({
                      'numero': newNumero,
                      'posti': posti,
                      'persone': [],
                      'club': club,
                    });
                  }
                } else {
                  final doc = await docRef.get();
                  if (doc.exists) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('La casa esiste già'),
                      ),
                    );
                    return;
                  }
                  await docRef.set({
                    'numero': newNumero,
                    'posti': posti,
                    'persone': [],
                    'club': club,
                  });
                }

                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  //Future<void> _createPdf() async {
//  final pdf = pw.Document();
//
//  final QuerySnapshot result = await FirebaseFirestore.instance.collection('ccCase').get();
//  final List<DocumentSnapshot> documents = result.docs;
//
//  pdf.addPage(
//    pw.MultiPage(
//      build: (context) => [
//        pw.Header(level: 0, child: pw.Text('Stanze CC 2025')),
//        ...documents.map((doc) {
//          final numero = doc['numero'];
//          final persone = List<Map<String, dynamic>>.from(doc['persone']);
//          return pw.Column(
//            crossAxisAlignment: pw.CrossAxisAlignment.start,
//            children: [
//              pw.Text('Stanza $numero', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
//              ...persone.map((persona) {
//                return pw.Text('${persona['nome']} (${persona['squadra']})');
//              }).toList(),
//              pw.SizedBox(height: 10),
//            ],
//          );
//        }).toList(),
//      ],
//    ),
//  );
//
//  final output = await getTemporaryDirectory();
//  final file = File("${output.path}/stanzeCC2025.pdf");
//  await file.writeAsBytes(await pdf.save());
//
//  await Printing.sharePdf(bytes: await pdf.save(), filename: 'stanzeCC2025.pdf');
//}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestione case'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () async {
              bool? confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Crea PDF'),
                  content: Text('Vuoi creare un file PDF?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Sì'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                //await _createPdf();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12.0, 12, 12, 12),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('ccCase').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final cases = snapshot.data!.docs;

            return ListView.builder(
              itemCount: cases.length,
              itemBuilder: (context, index) {
                final caseData = cases[index];
                final numero = caseData['numero'];
                final posti = caseData['posti'];
                final persone =
                    List<Map<String, dynamic>>.from(caseData['persone']);
                final club = caseData['club'];

                return Column(children: [
                  Card(
                    elevation: 4,
                    child: ExpansionTile(
                      shape: Border.all(color: Colors.transparent),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Casa $numero',
                                style: const TextStyle(fontSize: 19)),
                            Row(
                              children: [
                                Text(
                                  '${persone.length}/$posti posti',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic),
                                ),
                                club != ""
                                    ? Expanded(child: AutoSizeText(
                                        ', $club',
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                        minFontSize: 16,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ))
                                    : Container()
                              ],
                            )
                          ]),),
                          IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showDialog(
                            numero: numero,
                            posti: posti.toString(),
                            club: club,
                            isEditing: true,
                          ),
                        ),
                      ]
                      ),
                      children: [
                        if (persone.isNotEmpty)
                          ...persone.map((persona) {
                            return Column(children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
                                child: Divider(height: 4, thickness: 0.75, color: Colors.black54),
                              ),
                              ListTile(
                                title: Text('${persona['nome']}',
                                    style: const TextStyle(fontSize: 16)),
                                subtitle: Text('${persona['squadra']}',
                                    style: const TextStyle(
                                        fontSize: 14, fontStyle: FontStyle.italic)),
                              ),
                            ]);
                          }).toList()
                        else
                          const ListTile(
                            title: Text('Nessuna persona'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ]);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: Icon(Icons.add),
      ),
    );
  }
}
