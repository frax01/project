import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:share_plus/share_plus.dart';

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

  InputDecoration getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black54),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black54),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 25, 84, 132)),
      ),
    );
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
          title: Text(isEditing ? 'Modifica casa' : 'Crea casa'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _numeroController,
                  keyboardType: TextInputType.number,
                  decoration: getInputDecoration('Numero casa'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Obbligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _postiController,
                  keyboardType: TextInputType.number,
                  decoration: getInputDecoration('Numero posti'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Obbligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedClub,
                  hint: const Text('Seleziona Club'),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Obbligatorio';
                    }
                    return null;
                  },
                  decoration: getInputDecoration('Club'),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _showLoadingDialog();

                  final newNumero = _numeroController.text;
                  int posti = int.parse(_postiController.text);
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
                }
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createExcel() async {
    _showLoadingDialog();

    try {
      // Crea un nuovo file Excel
      var excelFile = excel.Excel.createExcel();

      // Ottieni i dati da Firestore
      final QuerySnapshot result =
          await FirebaseFirestore.instance.collection('ccCase').get();
      final List<DocumentSnapshot> documents = result.docs;

      // Raggruppa i dati per club
      Map<String, List<Map<String, dynamic>>> clubData = {};
      for (var doc in documents) {
        final numero = doc['numero'];
        final club = doc['club'];
        final persone = List<Map<String, dynamic>>.from(doc['persone']);

        for (var persona in persone) {
          final nomeCompleto = persona['nome'];

          if (!clubData.containsKey(club)) {
            clubData[club] = [];
          }

          clubData[club]!.add({
            'Cognome': nomeCompleto.split(' ').last,
            'Nome': nomeCompleto.split(' ').first,
            'Club': club,
            'Appartamento': numero,
          });
        }
      }

      clubData.forEach((club, persone) {
    var sheet = excelFile[club.isNotEmpty ? club : 'Senza Club'];


    // Aggiungi l'intestazione manualmente
    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =  excel.TextCellValue('Cognome');
    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value =  excel.TextCellValue('Nome');
    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value =  excel.TextCellValue('Club');
    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value =  excel.TextCellValue('Appartamento');

    // Aggiungi i dati delle persone
    for (int i = 0; i < persone.length; i++) {
      var persona = persone[i];
      sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = excel.TextCellValue(persona['Cognome']);
      sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = excel.TextCellValue(persona['Nome']);
      sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = excel.TextCellValue(persona['Club']);
      sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = excel.TextCellValue(persona['Appartamento']);
      }
    });

      // Salva il file Excel
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/stanzeCC2025.xlsx");
      await file.writeAsBytes(excelFile.encode()!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File Excel creato e condiviso con successo!')),
      );

      Navigator.of(context).pop();

      // Condividi il file Excel
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ecco il file Excel delle stanze per il Champions Club 2025!',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante la creazione del file Excel: $e')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteDialog(String numero) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina casa'),
        content: const Text('Sei sicuro di voler eliminare la casa?'),
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
      _showLoadingDialog();
      await FirebaseFirestore.instance
          .collection('ccCase')
          .doc(numero)
          .delete();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione case'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              bool? confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Crea Excel'),
                  content: const Text('Vuoi creare un file Excel?'),
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
                await _createExcel();
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
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('Nessuna casa', style: TextStyle(fontSize: 19, color: Colors.black54),),
              );
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
                            Expanded(
                              child: Column(
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
                                            ? Expanded(
                                                child: AutoSizeText(
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
                                  ]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showDialog(
                                numero: numero,
                                posti: posti,
                                club: club,
                                isEditing: true,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteDialog(numero),
                            ),
                          ]),
                      children: [
                        if (persone.isNotEmpty)
                          ...persone.map((persona) {
                            return Column(children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
                                child: Divider(
                                    height: 4,
                                    thickness: 0.75,
                                    color: Colors.black54),
                              ),
                              ListTile(
                                title: Text('${persona['nome']}',
                                    style: const TextStyle(fontSize: 16)),
                                subtitle: Text('${persona['squadra']}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic)),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
