import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:io';

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

    setState(() {
      print("ragazzi: $ragazzi");
    });
  }

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
      setState(() {});
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

  void _removeGiocatore(String squadra, int index) async { //eliminare anche qui i giocatori iscritti
    String nuovoAppartamento = appartamentoControllers[squadra]![index].text;
    if (nuovoAppartamento != '') {
      DocumentSnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('ccCase').doc(nuovoAppartamento).get();

      if (querySnapshot.exists) {
        List<dynamic> personeRem = querySnapshot['persone'];
        // Rimuovi la persona dall'appartamento precedente
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
    
    String nome = giocatoriControllers[squadra]![index].text;
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance.collection('ccIscrizioniSquadre').doc(squadra).get();
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
    
    setState(() {
      if (index < giocatori[squadra]!.length) {
        giocatori[squadra]!.removeAt(index);
      }
      if (index < giocatoriControllers[squadra]!.length) {
        giocatoriControllers[squadra]!.removeAt(index);
      }
      if (index < magliaControllers[squadra]!.length) {
        magliaControllers[squadra]!.removeAt(index);
      }
      if (index < appartamentoControllers[squadra]!.length) {
        appartamentoControllers[squadra]!.removeAt(index);
      }
    });
  }

  void _saveSquadra(String squadra) async {
    _showLoadingDialog();

    List<Map<String, String>> giocatoriData = [];
    print("giocatori: ${giocatori[squadra]}");
    for (int i = 0; i < giocatori[squadra]!.length; i++) {
      //giocatoriData.add({
      //  'nome': giocatori[squadra]![i],
      //  'maglia': magliaControllers[squadra]![i].text,
      //  'appartamento': appartamentoControllers[squadra]![i].text,
      //});

      List<dynamic> persone = [];
      int posti = 0;

      String nuovoAppartamento = appartamentoControllers[squadra]![i].text;

      // Controlla se la persona è già presente in un altro appartamento
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('ccCase').get(); //farlo in un altra funzione

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        List<dynamic> personeRem = data['persone'];

        // Rimuovi la persona dall'appartamento precedente
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
          // Aggiorna il documento dell'appartamento precedente
          await doc.reference.update({'persone': personeRem});
        }
      }
      if (nuovoAppartamento != '') {
        //conteggio posti e persone
        DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
            .collection('ccCase')
            .doc(nuovoAppartamento)
            .get();
        if (docSnapshot.exists) {
          persone = docSnapshot['persone'];
          posti = docSnapshot['posti'];
        }
        // Aggiungi la persona al nuovo appartamento
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Numero massimo di $posti posti raggiunto')),
          );
        }
      } else {
        giocatoriData.add({
          'nome': giocatori[squadra]![i],
          'maglia': magliaControllers[squadra]![i].text,
          'appartamento': '',
        });
      }

      //DocumentSnapshot docSnapshot = await docRef.get();

      //    persone = [];
      //    posti = 0;
      //    String clubValue = '';
      //    if (docSnapshot.exists) {
      //      //for (var elem in giocatori[squadra] ?? []) {
      //      persone.add({
      //        'squadra': squadra,
      //        'nome': giocatori[squadra]![i],
      //      });
      //      //}
      //      //persone = giocatori[squadra] ?? []; //docSnapshot['persone'];
      //      posti = docSnapshot['posti'];
      //      clubValue = docSnapshot['club'];
      //    }
//
      //    // Controlla se la persona è già presente nella lista
      //    bool found = false;
      //    for (var persona in persone) {
      //      if (persona == giocatori[squadra]![i]) {
      //        found = true;
      //        break;
      //      }
      //      //if (persona['nome'] == giocatori[squadra]![i]) {
      //      //  persona['squadra'] = squadra;
      //      //  found = true;
      //      //  break;
      //      //}
      //    }
//
      //    if (!found) {
      //      persone.add({
      //        'squadra': squadra,
      //        'nome': giocatori[squadra]![i],
      //      });
      //    }
//
      //    if (persone.length <= posti) {
      //      await docRef.set({
      //        'numero': nuovoAppartamento,
      //        'club': widget.ccRole != 'staff' ? widget.club : clubValue,
      //        'persone': persone,
      //        'posti': posti,
      //      });
      //    } else {
      //      List<dynamic> iscritti = [];
      //      for (int i = 0; i < posti; i++) {
      //        iscritti.add(persone[i]);
      //      }
      //      await docRef.set({
      //        'numero': nuovoAppartamento,
      //        'club': widget.ccRole != 'staff' ? widget.club : clubValue,
      //        'persone': iscritti,
      //        'posti': posti,
      //      });
      //      ScaffoldMessenger.of(context).showSnackBar(
      //        SnackBar(content: Text('Numero massimo di $posti posti raggiunto')),
      //      );
      //    }
      //  }

      //print("posti: ${int.parse(posti)}");
      //  print("persone: $persone");
      //  print("posti: $posti");
      //  if (persone.length <= posti) {
      //    print("1");
      //    giocatoriData.add({
      //      'nome': giocatori[squadra]![i],
      //      'maglia': magliaControllers[squadra]![i].text,
      //      'appartamento': appartamentoControllers[squadra]![i].text,
      //    });
      //  } else {
      //    print("2");
      //    giocatoriData.add({
      //      'nome': giocatori[squadra]![i],
      //      'maglia': magliaControllers[squadra]![i].text,
      //      'appartamento': '',
      //    });
      //  }
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
    }

    //setState(() {
    //  hasChanges[squadra] = false;
    //});

    Navigator.pop(context);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CcIscriviSquadre(club: widget.club, ccRole: widget.ccRole),
      ),
    );
  }

  Future<void> _importExcelFile() async {
    try {
      // Seleziona il file Excel
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        _showLoadingDialog();
        File file = File(result.files.single.path!);

        // Leggi il file Excel
        var bytes = file.readAsBytesSync();
        var excelF = excel.Excel.decodeBytes(bytes);

        // Mappa per raggruppare i ragazzi per club
        Map<String, List<String>> clubData = {};

        // Itera sui fogli del file Excel
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

        // Aggiorna Firestore
        for (var club in clubData.keys) {
          // Elimina il documento esistente se presente
          var docRef = FirebaseFirestore.instance
              .collection('ccIscrizioneRagazzi')
              .doc(club);
          await docRef.delete().catchError((_) {});

          // Crea un nuovo documento
          await docRef.set({
            'ragazzi': clubData[club],
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File Excel importato con successo!')),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'importazione: $e')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iscrivi giocatori'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _importExcelFile,
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
                  //print("squadra: $squadra");
                  //print("squadre: $squadre");
                  //print("clubs: $clubs");
                  //print("squadraMap: $squadraMap");
                  //print("ragazzi: $ragazzi");
                  //print("squadraMap: $squadraMap");
                  //print("ragazzi: ${ragazzi[squadraMap]}");
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
                                                      value: giocatoriControllers[
                                                                  squadra]![i]
                                                              .text
                                                              .isNotEmpty
                                                          ? giocatoriControllers[
                                                                  squadra]![i]
                                                              .text
                                                          : null,
                                                      items: ragazzi[squadraMap]
                                                          ?.map((dynamic
                                                              ragazziItem) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: ragazziItem,
                                                          child:
                                                              Text(ragazziItem),
                                                        );
                                                      }).toList(),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          giocatori[squadra]![
                                                              i] = value!;
                                                          giocatoriControllers[
                                                                  squadra]![i]
                                                              .text = value;
                                                          print(
                                                              "giocatoriNow: ${giocatori[squadra]}");
                                                          hasChanges[squadra] =
                                                              true;
                                                        });
                                                      },
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText:
                                                            'Nome e cognome',
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                                  color: Colors
                                                                      .black54),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                                  color: Colors
                                                                      .black54),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
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
                                                          TextInputType.number,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          hasChanges[squadra] =
                                                              true;
                                                        });
                                                      },
                                                      validator: (value) {
                                                        if (value != null &&
                                                            value.isNotEmpty) {
                                                          final int? number =
                                                              int.tryParse(
                                                                  value);
                                                          if (number == null ||
                                                              number < 0 ||
                                                              number > 99) {
                                                            return 'Numero non valido';
                                                          }
                                                        }
                                                        return null;
                                                      },
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText: 'N° maglia',
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                                  color: Colors
                                                                      .black54),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                                  color: Colors
                                                                      .black54),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
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
                                                            value: appartamentoControllers[
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
                                                                value: caseItem,
                                                                child: Text(
                                                                    caseItem),
                                                              );
                                                            }).toList(),
                                                            onChanged: (value) {
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
                                                          )
                                                        : DropdownButtonFormField<
                                                            String>(
                                                            value: appartamentoControllers[
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
                                                                      child: Text(
                                                                          caseItem),
                                                                    );
                                                                  }).toList()
                                                                : [],
                                                            onChanged: (value) {
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
