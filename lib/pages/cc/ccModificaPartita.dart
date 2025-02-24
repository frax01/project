import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CCModificaPartita extends StatefulWidget {
  final String casa;
  final String fuori;
  final String logocasa;
  final String logofuori;
  final String data;
  final String orario;
  final String campo;
  final String arbitro;
  final String girone;
  final bool iniziata;
  final bool finita;
  final String tipo;

  CCModificaPartita({
    required this.casa,
    required this.fuori,
    required this.logocasa,
    required this.logofuori,
    required this.data,
    required this.orario,
    required this.campo,
    required this.arbitro,
    required this.girone,
    required this.iniziata,
    required this.finita,
    required this.tipo,
  });

  @override
  _CCModificaPartitaState createState() => _CCModificaPartitaState();
}

class _CCModificaPartitaState extends State<CCModificaPartita> {
  int golCasa = 0;
  int golFuori = 0;
  List<Map<String, String>> marcatori = [];
  bool iniziata = false;
  bool finita = false;

  Future<void> _updateGironi() async {
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('ccGironi')
        .doc(widget.girone)
        .get();

    Map<String, dynamic> gironeData =
        docSnapshot.data() as Map<String, dynamic>;

    // Aggiorna partite giocate
    gironeData['partiteG'][widget.casa] =
        (gironeData['partiteG'][widget.casa] ?? 0) + 1;
    gironeData['partiteG'][widget.fuori] =
        (gironeData['partiteG'][widget.fuori] ?? 0) + 1;

    // Aggiorna goal fatti e subiti
    gironeData['goalFatti'][widget.casa] =
        (gironeData['goalFatti'][widget.casa] ?? 0) + golCasa;
    gironeData['goalFatti'][widget.fuori] =
        (gironeData['goalFatti'][widget.fuori] ?? 0) + golFuori;
    gironeData['goalSubiti'][widget.casa] =
        (gironeData['goalSubiti'][widget.casa] ?? 0) + golFuori;
    gironeData['goalSubiti'][widget.fuori] =
        (gironeData['goalSubiti'][widget.fuori] ?? 0) + golCasa;

    // Aggiorna differenza reti
    gironeData['diffReti'][widget.casa] =
        (gironeData['diffReti'][widget.casa] ?? 0) + (golCasa - golFuori);
    gironeData['diffReti'][widget.fuori] =
        (gironeData['diffReti'][widget.fuori] ?? 0) + (golFuori - golCasa);

    // Aggiorna punti
    if (golCasa > golFuori) {
      gironeData['punti'][widget.casa] =
          (gironeData['punti'][widget.casa] ?? 0) + 3;
    } else if (golCasa < golFuori) {
      gironeData['punti'][widget.fuori] =
          (gironeData['punti'][widget.fuori] ?? 0) + 3;
    } else {
      gironeData['punti'][widget.casa] =
          (gironeData['punti'][widget.casa] ?? 0) + 1;
      gironeData['punti'][widget.fuori] =
          (gironeData['punti'][widget.fuori] ?? 0) + 1;
    }

    await FirebaseFirestore.instance
        .collection('ccGironi')
        .doc(widget.girone)
        .update(gironeData);
  }

  Future<void> _updateGironiReverse() async {
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('ccGironi')
        .doc(widget.girone)
        .get();

    Map<String, dynamic> gironeData =
        docSnapshot.data() as Map<String, dynamic>;

    // Aggiorna partite giocate
    gironeData['partiteG'][widget.casa] =
        (gironeData['partiteG'][widget.casa] ?? 0) - 1;
    gironeData['partiteG'][widget.fuori] =
        (gironeData['partiteG'][widget.fuori] ?? 0) - 1;

    // Aggiorna goal fatti e subiti
    gironeData['goalFatti'][widget.casa] =
        (gironeData['goalFatti'][widget.casa] ?? 0) - golCasa;
    gironeData['goalFatti'][widget.fuori] =
        (gironeData['goalFatti'][widget.fuori] ?? 0) - golFuori;
    gironeData['goalSubiti'][widget.casa] =
        (gironeData['goalSubiti'][widget.casa] ?? 0) - golFuori;
    gironeData['goalSubiti'][widget.fuori] =
        (gironeData['goalSubiti'][widget.fuori] ?? 0) - golCasa;

    // Aggiorna differenza reti
    gironeData['diffReti'][widget.casa] =
        (gironeData['diffReti'][widget.casa] ?? 0) - (golCasa - golFuori);
    gironeData['diffReti'][widget.fuori] =
        (gironeData['diffReti'][widget.fuori] ?? 0) - (golFuori - golCasa);

    // Aggiorna punti
    if (golCasa > golFuori) {
      gironeData['punti'][widget.casa] =
          (gironeData['punti'][widget.casa] ?? 0) - 3;
    } else if (golCasa < golFuori) {
      gironeData['punti'][widget.fuori] =
          (gironeData['punti'][widget.fuori] ?? 0) - 3;
    } else {
      gironeData['punti'][widget.casa] =
          (gironeData['punti'][widget.casa] ?? 0) - 1;
      gironeData['punti'][widget.fuori] =
          (gironeData['punti'][widget.fuori] ?? 0) - 1;
    }

    await FirebaseFirestore.instance
        .collection('ccGironi')
        .doc(widget.girone)
        .update(gironeData);
  }

  Future<List<String>> getGiocatori(String squadra) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('ccIscrizioniSquadre')
        .doc(squadra)
        .get();
    List<dynamic> giocatori = snapshot['giocatori'];
    return giocatori.map((giocatore) => giocatore['nome'].toString()).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    DocumentSnapshot docSnapshot;
    if (widget.tipo == 'girone') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteGironi')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    } else if (widget.tipo == 'ottavi') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteOttavi')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    } else if (widget.tipo == 'quarti') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteQuarti')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    } else if (widget.tipo == 'semifinali') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteSemifinali')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    } else {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteFinali')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    }

    List<dynamic> marcatoriFirestore = docSnapshot['marcatori'] ?? [];

    setState(() {
      for (var marcatore in marcatoriFirestore) {
        if (marcatore['dove'] == 'casa') {
          golCasa++;
        } else if (marcatore['dove'] == 'fuori') {
          golFuori++;
        }
        marcatori.add({'nome': marcatore['nome'], 'dove': marcatore['dove']});
      }

      iniziata = docSnapshot['iniziata'];
      finita = docSnapshot['finita'];
    });
  }

  void aggiungiMarcatore(String squadra, String giocatore) async {
    DocumentSnapshot docSnapshot;
    if (widget.tipo == 'girone') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteGironi')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    } else if (widget.tipo == 'ottavi') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteOttavi')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    } else if (widget.tipo == 'quarti') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteQuarti')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    } else if (widget.tipo == 'semifinali') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteSemifinali')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    } else {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteFinali')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    }

    List<dynamic> marcatoriFirestore = docSnapshot['marcatori'] ?? [];

    setState(() {
      if (squadra == widget.casa) {
        marcatori.add({'nome': giocatore, 'dove': 'casa'});
        golCasa++;
      } else {
        marcatori.add({'nome': giocatore, 'dove': 'fuori'});
        golFuori++;
      }
    });

    marcatoriFirestore.add(
        {'nome': giocatore, 'dove': squadra == widget.casa ? 'casa' : 'fuori'});

    if (widget.tipo == 'girone') {
      await FirebaseFirestore.instance
          .collection('ccPartiteGironi')
          .doc('${widget.casa} VS ${widget.fuori}')
          .update({
        'marcatori': marcatoriFirestore,
      });
    } else if (widget.tipo == 'ottavi') {
      await FirebaseFirestore.instance
          .collection('ccPartiteOttavi')
          .doc('${widget.casa} VS ${widget.fuori}')
          .update({
        'marcatori': marcatoriFirestore,
      });
    } else if (widget.tipo == 'quarti') {
      await FirebaseFirestore.instance
          .collection('ccPartiteQuarti')
          .doc('${widget.casa} VS ${widget.fuori}')
          .update({
        'marcatori': marcatoriFirestore,
      });
    } else if (widget.tipo == 'semifinali') {
      await FirebaseFirestore.instance
          .collection('ccPartiteSemifinali')
          .doc('${widget.casa} VS ${widget.fuori}')
          .update({
        'marcatori': marcatoriFirestore,});
    } else {
      await FirebaseFirestore.instance
          .collection('ccPartiteFinali')
          .doc('${widget.casa} VS ${widget.fuori}')
          .update({
        'marcatori': marcatoriFirestore,});
    }
  }

  void rimuoviMarcatore(String squadra, String giocatore) async {
    DocumentSnapshot docSnapshot;
    if (widget.tipo == 'girone') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteGironi')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    } else if (widget.tipo == 'ottavi') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteOttavi')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    } else if (widget.tipo == 'quarti') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteQuarti')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    } else if (widget.tipo == 'semifinali') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteSemifinali')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    } else {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteFinali')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    }

    List<dynamic> marcatoriFirestore = docSnapshot['marcatori'] ?? [];

    setState(() {
      bool found = false;
      for (int i = 0; i < marcatori.length; i++) {
        if (marcatori[i]['nome'] == giocatore &&
            marcatori[i]['dove'] ==
                (squadra == widget.casa ? 'casa' : 'fuori')) {
          marcatori.removeAt(i);
          found = true;
          break;
        }
      }
      if (found) {
        if (squadra == widget.casa) {
          golCasa--;
        } else {
          golFuori--;
        }
      }
    });

    bool foundFirestore = false;
    for (int i = 0; i < marcatoriFirestore.length; i++) {
      if (marcatoriFirestore[i]['nome'] == giocatore &&
          marcatoriFirestore[i]['dove'] ==
              (squadra == widget.casa ? 'casa' : 'fuori')) {
        marcatoriFirestore.removeAt(i);
        foundFirestore = true;
        break;
      }
    }

    if (foundFirestore) {
      if (widget.tipo == 'girone') {
        await FirebaseFirestore.instance
            .collection('ccPartiteGironi')
            .doc('${widget.casa} VS ${widget.fuori}')
            .update({
          'marcatori': marcatoriFirestore,
        });
      } else if (widget.tipo == 'ottavi') {
        await FirebaseFirestore.instance
            .collection('ccPartiteOttavi')
            .doc('${widget.casa} VS ${widget.fuori}')
            .update({
          'marcatori': marcatoriFirestore,
        });
      } else if (widget.tipo == 'quarti') {
        await FirebaseFirestore.instance
            .collection('ccPartiteQuarti')
            .doc('${widget.casa} VS ${widget.fuori}')
            .update({
          'marcatori': marcatoriFirestore,
        });
      } else if (widget.tipo == 'semifinali') {
        await FirebaseFirestore.instance
            .collection('ccPartiteSemifinali')
            .doc('${widget.casa} VS ${widget.fuori}')
            .update({
          'marcatori': marcatoriFirestore,
        });
      } else {
        await FirebaseFirestore.instance
            .collection('ccPartiteFinali')
            .doc('${widget.casa} VS ${widget.fuori}')
            .update({
          'marcatori': marcatoriFirestore,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partita'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32.0, 8, 32, 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${widget.data} - '),
                Text(widget.orario),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Image.network(widget.logocasa, width: 90, height: 90),
                    const SizedBox(height: 8),
                    Text(widget.casa, style: const TextStyle(fontSize: 22)),
                  ],
                ),
                const SizedBox(width: 4),
                Text(
                  '$golCasa',
                  style: const TextStyle(fontSize: 34),
                ),
                const Text(':',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                Text('$golFuori', style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 4),
                Column(
                  children: [
                    Image.network(widget.logofuori, width: 90, height: 90),
                    const SizedBox(height: 8),
                    Text(widget.fuori, style: const TextStyle(fontSize: 22)),
                  ],
                ),
              ],
            ),
            ElevatedButton(
                onPressed: !iniziata
                    ? () {
                        setState(() {
                          iniziata = true;
                          if (finita && widget.tipo == 'girone') {
                            _updateGironiReverse();
                          }
                          finita = false;
                          widget.tipo == 'girone'
                              ? FirebaseFirestore.instance
                                  .collection('ccPartiteGironi')
                                  .doc('${widget.casa} VS ${widget.fuori}')
                                  .update({
                                  'iniziata': true,
                                  'finita': false,
                                })
                              : widget.tipo == 'ottavi'
                                  ? FirebaseFirestore.instance
                                      .collection('ccPartiteOttavi')
                                      .doc('${widget.casa} VS ${widget.fuori}')
                                      .update({
                                      'iniziata': true,
                                      'finita': false,
                                    })
                                  : widget.tipo == 'quarti'
                                  ? FirebaseFirestore.instance
                                      .collection('ccPartiteQuarti')
                                      .doc('${widget.casa} VS ${widget.fuori}')
                                      .update({
                                      'iniziata': true,
                                      'finita': false,
                                    })
                                  : widget.tipo == 'semifinali'
                                  ? FirebaseFirestore.instance
                                      .collection('ccPartiteSemifinali')
                                      .doc('${widget.casa} VS ${widget.fuori}')
                                      .update({
                                      'iniziata': true,
                                      'finita': false,
                                    })
                                  : FirebaseFirestore.instance
                                    .collection('ccPartiteFinali')
                                    .doc('${widget.casa} VS ${widget.fuori}')
                                    .update({
                                    'iniziata': true,
                                    'finita': false,
                                  });
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: iniziata
                      ? Colors.grey
                      : const Color.fromARGB(255, 25, 84, 132),
                ),
                child: const Text("Avvia partita")),
            const SizedBox(
              width: 16,
            ),
            ElevatedButton(
              onPressed: iniziata
                  ? () {
                      setState(() {
                        iniziata = false;
                        finita = true;
                        widget.tipo == 'girone'
                            ? FirebaseFirestore.instance
                                .collection('ccPartiteGironi')
                                .doc('${widget.casa} VS ${widget.fuori}')
                                .update({
                                'iniziata': false,
                                'finita': true,
                              })
                            : widget.tipo == 'ottavi' ? FirebaseFirestore.instance
                                .collection('ccPartiteOttavi')
                                .doc('${widget.casa} VS ${widget.fuori}')
                                .update({
                                'iniziata': false,
                                'finita': true,
                              })
                            : widget.tipo == 'quarti' ? FirebaseFirestore.instance
                                .collection('ccPartiteQuarti')
                                .doc('${widget.casa} VS ${widget.fuori}')
                                .update({
                                'iniziata': false,
                                'finita': true,
                              })
                            : widget.tipo == 'semifinali' ? FirebaseFirestore.instance
                              .collection('ccPartiteSemifinali')
                              .doc('${widget.casa} VS ${widget.fuori}')
                              .update({
                              'iniziata': false,
                              'finita': true,
                            })
                            : FirebaseFirestore.instance
                                .collection('ccPartiteFinali')
                                .doc('${widget.casa} VS ${widget.fuori}')
                                .update({
                                'iniziata': false,
                                'finita': true,
                              });
                      });
                      widget.tipo == 'girone' ? _updateGironi() : null;
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: !iniziata
                    ? Colors.grey
                    : const Color.fromARGB(255, 25, 84, 132),
              ),
              child: const Text("Termina partita"),
            ),
            iniziata
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder<List<String>>(
                        future: getGiocatori(widget.casa),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return Container();
                          return DropdownButton<String>(
                            hint: const Text('Marcatore'),
                            items: snapshot.data!
                                .map((giocatore) => DropdownMenuItem<String>(
                                      value: giocatore,
                                      child: Text(giocatore),
                                    ))
                                .toList(),
                            onChanged: (giocatore) {
                              if (giocatore != null) {
                                aggiungiMarcatore(widget.casa, giocatore);
                              }
                            },
                          );
                        },
                      ),
                      FutureBuilder<List<String>>(
                        future: getGiocatori(widget.fuori),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return Container();
                          return DropdownButton<String>(
                            hint: const Text('Marcatore'),
                            items: snapshot.data!
                                .map((giocatore) => DropdownMenuItem<String>(
                                      value: giocatore,
                                      child: Text(giocatore),
                                    ))
                                .toList(),
                            onChanged: (giocatore) {
                              if (giocatore != null) {
                                aggiungiMarcatore(widget.fuori, giocatore);
                              }
                            },
                          );
                        },
                      ),
                    ],
                  )
                : Container(),
            Column(
              children: [
                Text(widget.campo),
                Text(widget.arbitro),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: marcatori
                          .where((element) => element['dove'] == 'casa')
                          .length,
                      itemBuilder: (context, index) {
                        final marcatore = marcatori
                            .where((element) => element['dove'] == 'casa')
                            .elementAt(index);
                        return ListTile(
                          title: Text(marcatore['nome']!),
                          trailing: iniziata
                              ? IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    rimuoviMarcatore(
                                        widget.casa, marcatore['nome']!);
                                  },
                                )
                              : const SizedBox(
                                  width: 1,
                                ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: marcatori
                          .where((element) => element['dove'] == 'fuori')
                          .length,
                      itemBuilder: (context, index) {
                        final marcatore = marcatori
                            .where((element) => element['dove'] == 'fuori')
                            .elementAt(index);
                        return ListTile(
                            title: Text(marcatore['nome']!),
                            trailing: iniziata
                                ? IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      rimuoviMarcatore(
                                          widget.fuori, marcatore['nome']!);
                                    },
                                  )
                                : const SizedBox(
                                    width: 1,
                                  ));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
