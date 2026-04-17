import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:io';

class CcIscriviSquadre extends StatefulWidget {
  final String club;
  final String ccRole;

  const CcIscriviSquadre({super.key, required this.club, required this.ccRole});

  @override
  _CcIscriviSquadreState createState() => _CcIscriviSquadreState();
}

class _CcIscriviSquadreState extends State<CcIscriviSquadre> {
  List<String> squadre = [];
  Map<String, List<dynamic>> giocatori = {};
  Map<String, bool> hasChanges = {};
  late Future<void> _loadSquadreFuture;
  final Map<String, GlobalKey<FormState>> _formKeys = {};
  Map<String, List<TextEditingController>> giocatoriControllers = {};

  List<String> ccCaseList = [];
  Map<String, List<String>> ccCaseMap = {};
  Map<String, String> clubs = {};
  Map<String, List<dynamic>> ragazzi = {};

  @override
  void initState() {
    super.initState();
    _loadRagazzi();
    _loadSquadreFuture = _loadSquadre();
  }

  Future<void> _loadRagazzi() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('ccIscrizioneRagazzi')
        .get();

    for (var doc in snapshot.docs) {
      String club = doc.id;
      List<String> loadedRagazzi = List<String>.from(doc['ragazzi']);

      if (ragazzi.containsKey(club)) {
        ragazzi[club]!.addAll(loadedRagazzi);
      } else {
        ragazzi[club] = [''];
        ragazzi[club]!.addAll(loadedRagazzi);
      }
    }

    setState(() {});
  }

  Map<dynamic, dynamic> caseM = {};

  bool open = true;

  Future<void> _loadSquadre() async {
    // 1. Scarica tutto in parallelo (3 query invece di ~24 sequenziali)
    final results = await Future.wait([
      FirebaseFirestore.instance.collection('ccIscrizioni').doc('iscrizioni').get(),
      FirebaseFirestore.instance.collection('ccCase').get(),
      widget.ccRole == 'staff'
          ? FirebaseFirestore.instance.collection('ccSquadre').get()
          : FirebaseFirestore.instance.collection('ccSquadre').where('club', isEqualTo: widget.club).get(),
      FirebaseFirestore.instance.collection('ccIscrizioniSquadre').get(),
    ]);

    final DocumentSnapshot iscrizioniDoc = results[0] as DocumentSnapshot;
    final QuerySnapshot caseSnapshot = results[1] as QuerySnapshot;
    final QuerySnapshot squadreSnapshot = results[2] as QuerySnapshot;
    final QuerySnapshot iscrizioniSquadreSnapshot = results[3] as QuerySnapshot;

    // 2. Iscrizioni aperte/chiuse
    if (iscrizioniDoc.exists) {
      open = iscrizioniDoc['open'];
    }

    // 3. Case - costruisci mappa una volta sola
    for (var doc in caseSnapshot.docs) {
      caseM[doc['numero']] = doc['posti'];
    }

    if (widget.ccRole == 'staff') {
      ccCaseMap = {};
      for (var doc in caseSnapshot.docs) {
        String club = doc['club'];
        String numero = doc['numero'];
        if (ccCaseMap.containsKey(club)) {
          ccCaseMap[club]!.add(numero);
        } else {
          ccCaseMap[club] = ['', numero];
        }
      }
    } else {
      ccCaseList = [''];
      for (var doc in caseSnapshot.docs) {
        if (doc['club'] == widget.club) {
          ccCaseList.add(doc['numero']);
        }
      }
    }

    // 4. Mappa tutti i giocatori iscritti (già scaricati, nessuna query extra)
    Map<String, List<Map<String, dynamic>>> playersMap = {};
    Map<String, String> clubsMap = {};
    for (var doc in iscrizioniSquadreSnapshot.docs) {
      String nomeSquadra = doc['nomeSquadra'];
      playersMap[nomeSquadra] = List<Map<String, dynamic>>.from(doc['giocatori']);
      clubsMap[nomeSquadra] = doc['club'];
    }

    // 5. Costruisci i dati locali
    List<Map<String, dynamic>> loadedSquadre = squadreSnapshot.docs
        .expand((doc) => List<Map<String, dynamic>>.from(doc['squadre']))
        .toList();
    Map<String, List<dynamic>> loadedGiocatori = {};
    Map<String, bool> loadedHasChanges = {};

    for (var squadra in loadedSquadre) {
      String nome = squadra['squadra'];
      List<Map<String, dynamic>> players = playersMap[nome] ?? [];
      loadedGiocatori[nome] = players.map((p) => p['nome']!).toList();
      giocatoriControllers[nome] = players
          .map((p) => TextEditingController(text: p['nome']))
          .toList();
      magliaControllers[nome] = players
          .map((p) => TextEditingController(text: p['maglia']))
          .toList();
      appartamentoControllers[nome] = players
          .map((p) => TextEditingController(text: p['appartamento']))
          .toList();
      loadedHasChanges[nome] = false;
      _formKeys[nome] = GlobalKey<FormState>();
    }

    squadre = loadedSquadre.map((s) => s['squadra'] as String).toList();
    clubs = clubsMap;

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

  void _removeGiocatore(String squadra, int index) async {
    String nome = giocatoriControllers[squadra]![index].text;
    if (nome.isNotEmpty) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Conferma eliminazione'),
          content: Text('Vuoi eliminare $nome?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Elimina'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }

    _showLoadingDialog();
    try {
      String nuovoAppartamento = appartamentoControllers[squadra]![index].text;
      if (nuovoAppartamento != '') {
        DocumentSnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('ccCase')
            .doc(nuovoAppartamento)
            .get();

        if (querySnapshot.exists) {
          List<dynamic> personeRem = querySnapshot['persone'];

          bool found = false;
          for (var persona in personeRem) {
            if (persona['nome'] == giocatori[squadra]![index] &&
                persona['squadra'] == squadra) {
              personeRem.remove(persona);
              found = true;
              break;
            }
          }

          if (found) {
            await querySnapshot.reference.update({'persone': personeRem});
          }
        }
      }

      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('ccIscrizioniSquadre')
          .doc(squadra)
          .get();
      if (documentSnapshot.exists) {
        List<dynamic> giocatoriRem = documentSnapshot['giocatori'];
        bool found = false;
        for (var giocatore in giocatoriRem) {
          if (giocatore['nome'] == nome) {
            giocatoriRem.remove(giocatore);
            found = true;
            break;
          }
        }

        if (found) {
          await documentSnapshot.reference.update({'giocatori': giocatoriRem});
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // chiude dialog loading
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CcIscriviSquadre(club: widget.club, ccRole: widget.ccRole),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // chiude dialog loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  void _saveSquadra(String squadra) async {
    _showLoadingDialog();
    try {
      // Cache singola query per tutte le case
      QuerySnapshot caseSnapshot =
          await FirebaseFirestore.instance.collection('ccCase').get();

      List<Map<String, String>> giocatoriData = [];
      for (int i = 0; i < giocatori[squadra]!.length; i++) {
        List<dynamic> persone = [];
        int posti = 0;

        String nuovoAppartamento = appartamentoControllers[squadra]![i].text;

        for (var doc in caseSnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          List<dynamic> personeRem = data['persone'];

          bool found = false;
          for (var persona in personeRem) {
            if (persona['nome'] == giocatori[squadra]![i] &&
                persona['squadra'] == squadra) {
              personeRem.remove(persona);
              found = true;
              break;
            }
          }

          if (found) {
            await doc.reference.update({'persone': personeRem});
          }
        }
        if (nuovoAppartamento != '') {
          DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
              .collection('ccCase')
              .doc(nuovoAppartamento)
              .get();
          if (docSnapshot.exists) {
            persone = docSnapshot['persone'];
            posti = docSnapshot['posti'];
          }
          if (persone.length < posti) {
            await FirebaseFirestore.instance
                .collection('ccCase')
                .doc(nuovoAppartamento)
                .update({
              'persone': FieldValue.arrayUnion([
                {
                  'squadra': squadra,
                  'nome': giocatori[squadra]![i],
                }
              ]),
            });
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
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Appartamento non salvato: numero massimo di $posti posti raggiunto')),
              );
            }
          }
        } else {
          giocatoriData.add({
            'nome': giocatori[squadra]![i],
            'maglia': magliaControllers[squadra]![i].text,
            'appartamento': '',
          });
        }
      }

      DocumentSnapshot docClub = await FirebaseFirestore.instance
          .collection('ccIscrizioniSquadre')
          .doc(squadra)
          .get();

      if (docClub.exists) {
        String clubValue = docClub['club'];
        await FirebaseFirestore.instance
            .collection('ccIscrizioniSquadre')
            .doc(squadra)
            .update({
          'nomeSquadra': squadra,
          'giocatori': giocatoriData,
          'club': widget.ccRole != 'staff' ? widget.club : clubValue,
        });
      } else {
        await FirebaseFirestore.instance
            .collection('ccIscrizioniSquadre')
            .doc(squadra)
            .set({
          'nomeSquadra': squadra,
          'giocatori': giocatoriData,
          'club': widget.ccRole != 'staff' ? widget.club : squadra.split(" ")[0],
        });
      }

      if (!mounted) return;
      Navigator.pop(context); // chiude dialog

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CcIscriviSquadre(club: widget.club, ccRole: widget.ccRole),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // chiude dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  Future<void> _importExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        _showLoadingDialog();
        File file = File(result.files.single.path!);

        var bytes = file.readAsBytesSync();
        var excelF = excel.Excel.decodeBytes(bytes);

        Map<String, List<String>> clubData = {};

        for (var table in excelF.tables.keys) {
          var sheet = excelF.tables[table];
          if (sheet != null) {
            for (int i = 1; i < sheet.rows.length; i++) {
              var row = sheet.rows[i];
              String nome = row[0]?.value?.toString() ?? '';
              String cognome = row[1]?.value?.toString() ?? '';
              String club = row[2]?.value?.toString() ?? '';

              if (nome.isNotEmpty && cognome.isNotEmpty && club.isNotEmpty) {
                if (!clubData.containsKey(club)) {
                  clubData[club] = [];
                }
                clubData[club]!.add('$nome $cognome');
              }
            }
          }
        }

        for (var club in clubData.keys) {
          var docRef = FirebaseFirestore.instance
              .collection('ccIscrizioneRagazzi')
              .doc(club);
          await docRef.delete().catchError((_) {});

          await docRef.set({
            'ragazzi': clubData[club],
          });
        }

        if (!mounted) return;
        Navigator.pop(context); // chiude dialog loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File Excel importato con successo!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // chiude dialog loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'importazione: $e')),
      );
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

  Map<String, List<TextEditingController>> magliaControllers = {};
  Map<String, List<TextEditingController>> appartamentoControllers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Iscrivi giocatori'),
        actions: [
          widget.ccRole == 'staff'
              ? IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: _importExcelFile,
                )
              : Container()
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
                  child: widget.ccRole == 'staff'
                      ? const Text(
                          'Nessuna squadra iscritta',
                          style: TextStyle(fontSize: 19, color: Colors.black54),
                          textAlign: TextAlign.center,
                        )
                      : Text(
                          'Nessuna squadra iscritta per ${widget.club}',
                          style: const TextStyle(
                              fontSize: 19, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ));
            } else {
              if (!open) {
                return Center(
                    child: Text(
                  'Le iscrizioni sono chiuse',
                  style: const TextStyle(fontSize: 19, color: Colors.black54),
                ));
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
                              Text(squadra,
                                  style: const TextStyle(fontSize: 25)),
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
                              key: _formKeys[squadra],
                              child: Column(
                                children: [
                                  for (int i = 0;
                                      i < giocatori[squadra]!.length;
                                      i++)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10.0, horizontal: 4),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Center(
                                            child: Text(
                                              '${i + 1}',
                                              style:
                                                  const TextStyle(fontSize: 22),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          DropdownButtonFormField<
                                                              String>(
                                                        initialValue: giocatoriControllers[
                                                                    squadra]![i]
                                                                .text
                                                                .isNotEmpty
                                                            ? giocatoriControllers[
                                                                    squadra]![i]
                                                                .text
                                                            : null,
                                                        items: ragazzi[squadra
                                                                .split(' ')[0]]
                                                            ?.map((dynamic
                                                                ragazziItem) {
                                                          return DropdownMenuItem<
                                                              String>(
                                                            value: ragazziItem,
                                                            child: Text(
                                                              ragazziItem,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            giocatori[squadra]![
                                                                i] = value!;
                                                            giocatoriControllers[
                                                                    squadra]![i]
                                                                .text = value;
                                                            hasChanges[
                                                                squadra] = true;
                                                          });
                                                        },
                                                        decoration:
                                                            const InputDecoration(
                                                          labelText:
                                                              'Nome e cognome',
                                                          filled: true,
                                                          fillColor:
                                                              Colors.white,
                                                          border:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Colors
                                                                    .black54),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Colors
                                                                    .black54),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Color
                                                                    .fromARGB(
                                                                        255,
                                                                        25,
                                                                        84,
                                                                        132)),
                                                          ),
                                                        ),
                                                        isExpanded: true,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextFormField(
                                                        controller:
                                                            magliaControllers[
                                                                squadra]![i],
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            hasChanges[
                                                                squadra] = true;
                                                          });
                                                        },
                                                        validator: (value) {
                                                          if (value != null &&
                                                              value
                                                                  .isNotEmpty) {
                                                            final int? number =
                                                                int.tryParse(
                                                                    value);
                                                            if (number ==
                                                                    null ||
                                                                number < 0 ||
                                                                number > 99) {
                                                              return 'Numero non valido';
                                                            }
                                                          }
                                                          return null;
                                                        },
                                                        decoration:
                                                            const InputDecoration(
                                                          labelText:
                                                              'N° maglia',
                                                          filled: true,
                                                          fillColor:
                                                              Colors.white,
                                                          border:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Colors
                                                                    .black54),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Colors
                                                                    .black54),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Color
                                                                    .fromARGB(
                                                                        255,
                                                                        25,
                                                                        84,
                                                                        132)),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: widget.ccRole ==
                                                              'tutor'
                                                          ? DropdownButtonFormField<
                                                              String>(
                                                              initialValue: appartamentoControllers[
                                                                              squadra]![
                                                                          i]
                                                                      .text
                                                                      .isNotEmpty
                                                                  ? appartamentoControllers[
                                                                          squadra]![i]
                                                                      .text
                                                                  : null,
                                                              items: ccCaseList
                                                                  .map((String
                                                                      caseItem) {
                                                                return DropdownMenuItem<
                                                                    String>(
                                                                  value:
                                                                      caseItem,
                                                                  child: Text(
                                                                    caseM[caseItem] !=
                                                                            null
                                                                        ? '$caseItem (${caseM[caseItem]} posti)'
                                                                        : caseItem,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                );
                                                              }).toList(),
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  appartamentoControllers[
                                                                          squadra]![i]
                                                                      .text = value!;
                                                                  hasChanges[
                                                                          squadra] =
                                                                      true;
                                                                });
                                                              },
                                                              decoration:
                                                                  const InputDecoration(
                                                                labelText:
                                                                    'N° appartamento',
                                                                filled: true,
                                                                fillColor:
                                                                    Colors
                                                                        .white,
                                                                border:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Colors.black54),
                                                                ),
                                                                enabledBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Colors.black54),
                                                                ),
                                                                focusedBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                      color: Color.fromARGB(
                                                                          255,
                                                                          25,
                                                                          84,
                                                                          132)),
                                                                ),
                                                              ),
                                                              isExpanded: true,
                                                            )
                                                          : DropdownButtonFormField<
                                                              String>(
                                                              initialValue: appartamentoControllers[
                                                                              squadra]![
                                                                          i]
                                                                      .text
                                                                      .isNotEmpty
                                                                  ? appartamentoControllers[
                                                                          squadra]![i]
                                                                      .text
                                                                  : null,
                                                              items: ccCaseMap[
                                                                          squadraMap] !=
                                                                      null
                                                                  ? ccCaseMap[
                                                                          squadraMap]!
                                                                      .map((String
                                                                          caseItem) {
                                                                      return DropdownMenuItem<
                                                                          String>(
                                                                        value:
                                                                            caseItem,
                                                                        child:
                                                                            Text(
                                                                          caseM[caseItem] != null
                                                                              ? '$caseItem (${caseM[caseItem]} posti)'
                                                                              : caseItem,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      );
                                                                    }).toList()
                                                                  : [],
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  appartamentoControllers[
                                                                          squadra]![i]
                                                                      .text = value!;
                                                                  hasChanges[
                                                                          squadra] =
                                                                      true;
                                                                });
                                                              },
                                                              decoration:
                                                                  const InputDecoration(
                                                                labelText:
                                                                    'N° appartamento',
                                                                filled: true,
                                                                fillColor:
                                                                    Colors
                                                                        .white,
                                                                border:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Colors.black54),
                                                                ),
                                                                enabledBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Colors.black54),
                                                                ),
                                                                focusedBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                      color: Color.fromARGB(
                                                                          255,
                                                                          25,
                                                                          84,
                                                                          132)),
                                                                ),
                                                              ),
                                                              isExpanded: true,
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
                                              onPressed: () =>
                                                  _removeGiocatore(squadra, i),
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
                                          if (_formKeys[squadra]!.currentState!
                                              .validate()) {
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
            }
          }),
    );
  }
}
