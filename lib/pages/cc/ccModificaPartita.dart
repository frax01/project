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
  });

  @override
  _CCModificaPartitaState createState() => _CCModificaPartitaState();
}

class _CCModificaPartitaState extends State<CCModificaPartita> {
  int golCasa = 0;
  int golFuori = 0;
  List<String> marcatoriCasa = [];
  List<String> marcatoriFuori = [];

  Future<List<String>> getGiocatori(String squadra) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('ccIscrizioniSquadre')
        .doc(squadra)
        .get();
    List<dynamic> giocatori = snapshot['giocatori'];
    return giocatori.map((giocatore) => giocatore['nome'].toString()).toList();
  }

  void aggiungiMarcatore(String squadra, String giocatore) {
    setState(() {
      if (squadra == widget.casa) {
        marcatoriCasa.add(giocatore);
        golCasa++;
      } else {
        marcatoriFuori.add(giocatore);
        golFuori++;
      }
      FirebaseFirestore.instance
          .collection('ccPartiteGironi')
          .doc('${widget.casa} VS ${widget.fuori}')
          .update({
        'marcatori': FieldValue.arrayUnion([giocatore])
      });
    });
  }

  void rimuoviMarcatore(String squadra, String giocatore) {
    setState(() {
      if (squadra == widget.casa) {
        marcatoriCasa.remove(giocatore);
        golCasa--;
      } else {
        marcatoriFuori.remove(giocatore);
        golFuori--;
      }
      FirebaseFirestore.instance
          .collection('ccPartiteGironi')
          .doc('${widget.casa} VS ${widget.fuori}')
          .update({
        'marcatori': FieldValue.arrayRemove([giocatore])
      });
    });
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
                Text('$golCasa', style: const TextStyle(fontSize: 34),),
                const Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
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
            Row(
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
            ),
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
                      itemCount: marcatoriCasa.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(marcatoriCasa[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              rimuoviMarcatore(widget.casa, marcatoriCasa[index]);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: marcatoriFuori.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(marcatoriFuori[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              rimuoviMarcatore(widget.fuori, marcatoriFuori[index]);
                            },
                          ),
                        );
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