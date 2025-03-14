import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:pdf/pdf.dart';
//import 'package:pdf/widgets.dart' as pw;
//import 'package:printing/printing.dart';

class CcIscriviSquadre extends StatefulWidget {
  final String club;
  final String ccRole;

  CcIscriviSquadre({required this.club, required this.ccRole});

  @override
  _CcIscriviSquadreState createState() => _CcIscriviSquadreState();
}

class _CcIscriviSquadreState extends State<CcIscriviSquadre> {
  List<String> squadre = [];
  Map<String, List<dynamic>> giocatori = {};
  Map<String, bool> hasChanges = {};
  late Future<void> _loadSquadreFuture;
  final _formKey = GlobalKey<FormState>();
  Map<String, List<TextEditingController>> giocatoriControllers = {};

  List<String> ccCaseList = [];
  Map<String, List<String>> ccCaseMap = {};
  Map<String, String> clubs = {};

  @override
  void initState() {
    super.initState();
    _loadSquadreFuture = _loadSquadre();
  }

//  Future<void> _createPdf() async {
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

  Future<List<Map<String, dynamic>>> retrievePlayers(String squadra) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('ccIscrizioniSquadre')
        .where('nomeSquadra', isEqualTo: squadra)
        .get();

    List<Map<String, dynamic>> players = snapshot.docs
        .expand((doc) => List<Map<String, dynamic>>.from(doc['giocatori']))
        .toList();
    return players;
  }

  Future<void> _loadSquadre() async {
    QuerySnapshot snapshot;
    QuerySnapshot ccCase;
    if (widget.ccRole == 'staff') {
      snapshot = await FirebaseFirestore.instance.collection('ccSquadre').get();
      ccCase = await FirebaseFirestore.instance.collection('ccCase').get();
      ccCaseMap = {};
      if (ccCase.docs.isNotEmpty) {
        for (var squadra in ccCase.docs) {
          String club = squadra['club'];
          String numero = squadra['numero'];
          if (ccCaseMap.containsKey(club)) {
            ccCaseMap[club]!.add(numero);
          } else {
            ccCaseMap[club] = ['', numero];
          }
        }
      }
      setState(() {
        print("ccCaseMap: $ccCaseMap");
      });
    } else {
      snapshot = await FirebaseFirestore.instance
          .collection('ccSquadre')
          .where('club', isEqualTo: widget.club)
          .get();
      ccCase = await FirebaseFirestore.instance
          .collection('ccCase')
          .where('club', isEqualTo: widget.club)
          .get();
      ccCaseList = [''];
      if (ccCase.docs.isNotEmpty) {
        for (var squadra in ccCase.docs) {
          ccCaseList.add(squadra['numero']);
        }
      }
      print("ccCaseList: $ccCaseList");
      setState(() {});
    }

    List<Map<String, dynamic>> loadedSquadre = snapshot.docs
        .expand((doc) => List<Map<String, dynamic>>.from(doc['squadre']))
        .toList();
    Map<String, List<dynamic>> loadedGiocatori = {};
    Map<String, bool> loadedHasChanges = {};

    for (var squadra in loadedSquadre) {
      List<Map<String, dynamic>> players =
          await retrievePlayers(squadra['squadra']);
      loadedGiocatori[squadra['squadra']] =
          players.map((player) => player['nome']!).toList();
      giocatoriControllers[squadra['squadra']] = players
          .map((player) => TextEditingController(text: player['nome']))
          .toList();
      magliaControllers[squadra['squadra']] = players
          .map((player) => TextEditingController(text: player['maglia']))
          .toList();
      appartamentoControllers[squadra['squadra']] = players
          .map((player) => TextEditingController(text: player['appartamento']))
          .toList();
      loadedHasChanges[squadra['squadra']] = false;
    }

    squadre =
        loadedSquadre.map((squadra) => squadra['squadra'] as String).toList();
    print("squadre: $squadre");
    for (var elem in squadre) {
      if (!clubs.containsKey(elem)) {
        QuerySnapshot value = await FirebaseFirestore.instance
            .collection('ccIscrizioniSquadre')
            .where('nomeSquadra', isEqualTo: elem)
            .get();
        String search = '';
        if (value.docs.isNotEmpty) {
          for (var doc in value.docs) {
            search = doc['club'];
          }
        }
        clubs[elem] = search;
      }
    }
    print("clubs: $clubs");

    setState(() {
      giocatori = loadedGiocatori;
      hasChanges = loadedHasChanges;
    });
  }

  void _addGiocatore(String squadra) {
    setState(() {
      giocatori[squadra]!.add('');
      giocatoriControllers[squadra]!.add(TextEditingController());
      magliaControllers[squadra]!.add(TextEditingController());
      appartamentoControllers[squadra]!.add(TextEditingController());
      hasChanges[squadra] = true;
    });
  }

  void _removeGiocatore(String squadra, int index) {
    setState(() {
      giocatori[squadra]!.removeAt(index);
      giocatoriControllers[squadra]!.removeAt(index);
      magliaControllers[squadra]!.removeAt(index);
      appartamentoControllers[squadra]!.removeAt(index);
      hasChanges[squadra] = true;
    });
  }

  void _saveSquadra(String squadra) async {
    _showLoadingDialog();

    List<Map<String, String>> giocatoriData = [];
    for (int i = 0; i < giocatori[squadra]!.length; i++) {
      //giocatoriData.add({
      //  'nome': giocatori[squadra]![i],
      //  'maglia': magliaControllers[squadra]![i].text,
      //  'appartamento': appartamentoControllers[squadra]![i].text,
      //});

      List<dynamic> persone = [];
      String posti = '';

      String nuovoAppartamento = appartamentoControllers[squadra]![i].text;

      // Controlla se la persona è già presente in un altro appartamento
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('ccCase').get();

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        List<dynamic> persone = data['persone'];

        // Rimuovi la persona dall'appartamento precedente
        bool found = false;
        for (var persona in persone) {
          if (persona['nome'] == giocatori[squadra]![i]) {
            persone.remove(persona);
            found = true;
            break;
          }
        }

        if (found) {
          // Aggiorna il documento dell'appartamento precedente
          await doc.reference.update({'persone': persone});
        }
      }
      if (nuovoAppartamento != '') {
        // Aggiungi la persona al nuovo appartamento
        DocumentReference docRef = FirebaseFirestore.instance
            .collection('ccCase')
            .doc(nuovoAppartamento);

        DocumentSnapshot docSnapshot = await docRef.get();

        persone = [];
        posti = '';
        if (docSnapshot.exists) {
          persone = docSnapshot['persone'];
          posti = docSnapshot['posti'].toString();
        }

        // Controlla se la persona è già presente nella lista
        bool found = false;
        for (var persona in persone) {
          if (persona['nome'] == giocatori[squadra]![i]) {
            persona['squadra'] = squadra;
            found = true;
            break;
          }
        }

        if (!found) {
          persone.add({
            'squadra': squadra,
            'nome': giocatori[squadra]![i],
          });
        }

        if (persone.length<=int.parse(posti)) {
          await docRef.set({
            'numero': nuovoAppartamento,
            'club': widget.club,
            'persone': persone,
            'posti': posti,
          });
        } else {
          List<dynamic> iscritti = [];
          for (int i=0; i<int.parse(posti); i++) {
            iscritti.add(persone[i]);
          }
          await docRef.set({
              'numero': nuovoAppartamento,
              'club': widget.club,
              'persone': iscritti,
              'posti': posti,
            });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Numero massimo di $posti posti raggiunto')),
          );
        }
      }

      if(persone.length<=int.parse(posti)) {
        giocatoriData.add({
          'nome': giocatori[squadra]![i],
          'maglia': magliaControllers[squadra]![i].text,
          'appartamento': appartamentoControllers[squadra]![i].text,
        });
      } else {
        giocatoriData.add({
          'nome': giocatori[squadra]![i],
          'maglia': magliaControllers[squadra]![i].text,
          'appartamento': '',
        });
      }
    }

    await FirebaseFirestore.instance
        .collection('ccIscrizioniSquadre')
        .doc(squadra)
        .set({
      'nomeSquadra': squadra,
      'giocatori': giocatoriData,
      'club': widget.club
    });

    setState(() {
      hasChanges[squadra] = false;
    });

    Navigator.of(context).pop();

    Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => CcIscriviSquadre(club: widget.club, ccRole: widget.ccRole),
    ),
  );
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

  Map<String, List<TextEditingController>> magliaControllers = {};
  Map<String, List<TextEditingController>> appartamentoControllers = {};
  Map<String, List<TextEditingController>> golControllers = {};
  Map<String, List<TextEditingController>> ammControllers = {};
  Map<String, List<TextEditingController>> espControllers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iscrivi giocatori'),
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
      body: FutureBuilder(
          future: _loadSquadreFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Errore: ${snapshot.error}'));
            } else if (squadre.isEmpty) {
              return Center(
                child: Text(
                  'Nessuna squadra iscritta per ${widget.club}',
                  style: const TextStyle(fontSize: 20.0, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              return ListView.builder(
                itemCount: squadre.length,
                itemBuilder: (context, index) {
                  String squadra = squadre[index];
                  String squadraMap = clubs[squadra]!;
                  return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
                      child: ExpansionTile(
                        title: Text(
                          'Squadra ${index + 1}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(squadra, style: const TextStyle(fontSize: 25)),
                            giocatori[squadra]!.length == 1
                                ? const Text('1 giocatore',
                                    style: TextStyle(fontSize: 17))
                                : Text(
                                    '${giocatori[squadra]!.length} giocatori',
                                    style: const TextStyle(fontSize: 17))
                          ],
                        ),
                        shape: Border.all(color: Colors.transparent),
                        children: [
  Form(
    key: _formKey,
    child: Column(
      children: [
        for (int i = 0; i < giocatori[squadra]!.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              textCapitalization: TextCapitalization.sentences,
                              controller: giocatoriControllers[squadra]![i],
                              onChanged: (value) {
                                giocatori[squadra]![i] = value;
                                setState(() {
                                  hasChanges[squadra] = true;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Inserisci il giocatore';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Nome e cognome',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black54),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black54),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 25, 84, 132)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: magliaControllers[squadra]![i],
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  hasChanges[squadra] = true;
                                });
                              },
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final int? number = int.tryParse(value);
                                  if (number == null || number < 0 || number > 99) {
                                    return 'Numero non valido';
                                  }
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'N° maglia',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black54),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black54),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 25, 84, 132)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: widget.ccRole == 'tutor'
                                ? DropdownButtonFormField<String>(
                                    value: appartamentoControllers[squadra]![i]
                                            .text
                                            .isNotEmpty
                                        ? appartamentoControllers[squadra]![i]
                                            .text
                                        : null,
                                    items: ccCaseList.map((String caseItem) {
                                      return DropdownMenuItem<String>(
                                        value: caseItem,
                                        child: Text(caseItem),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        appartamentoControllers[squadra]![i]
                                            .text = value!;
                                        hasChanges[squadra] = true;
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'N° appartamento',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black54),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black54),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color.fromARGB(
                                                255, 25, 84, 132)),
                                      ),
                                    ),
                                  )
                                : DropdownButtonFormField<String>(
                                    value: appartamentoControllers[squadra]![i]
                                            .text
                                            .isNotEmpty
                                        ? appartamentoControllers[squadra]![i]
                                            .text
                                        : null,
                                    items: ccCaseMap[squadraMap] != null
                                        ? ccCaseMap[squadraMap]!
                                            .map((String caseItem) {
                                            return DropdownMenuItem<String>(
                                              value: caseItem,
                                              child: Text(caseItem),
                                            );
                                          }).toList()
                                        : [],
                                    onChanged: (value) {
                                      setState(() {
                                        appartamentoControllers[squadra]![i]
                                            .text = value!;
                                        hasChanges[squadra] = true;
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'N° appartamento',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black54),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black54),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color.fromARGB(
                                                255, 25, 84, 132)),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Center(
                  child: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeGiocatore(squadra, i),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _addGiocatore(squadra),
                                highlightColor:
                                    const Color.fromARGB(255, 25, 84, 132),
                              ),
                              ElevatedButton(
                                onPressed: hasChanges[squadra]!
                                    ? () {
                                        if (_formKey.currentState!.validate()) {
                                          _saveSquadra(squadra);
                                        }
                                      }
                                    : null,
                                child: const Text('Salva'),
                              ),
                            ],
                          ),
                        ],
                      ));
                },
              );
            }
          }),
    );
  }
}
