import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

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
  final String codice;

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
    required this.codice,
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
          .doc(widget.codice)
          .get();
    } else if (widget.tipo == 'quarti') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteQuarti')
          .doc(widget.codice)
          .get();
    } else if (widget.tipo == 'semifinali') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteSemifinali')
          .doc(widget.codice)
          .get();
    } else {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteFinali')
          .doc(widget.codice)
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

  Stream<DocumentSnapshot> _getPartitaStream() {
    if (widget.tipo == 'girone') {
      return FirebaseFirestore.instance
          .collection('ccPartiteGironi')
          .doc('${widget.casa} VS ${widget.fuori}')
          .snapshots();
    } else if (widget.tipo == 'ottavi') {
      return FirebaseFirestore.instance
          .collection('ccPartiteOttavi')
          .doc(widget.codice)
          .snapshots();
    } else if (widget.tipo == 'quarti') {
      return FirebaseFirestore.instance
          .collection('ccPartiteQuarti')
          .doc(widget.codice)
          .snapshots();
    } else if (widget.tipo == 'semifinali') {
      return FirebaseFirestore.instance
          .collection('ccPartiteSemifinali')
          .doc(widget.codice)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('ccPartiteFinali')
          .doc(widget.codice)
          .snapshots();
    }
  }

  void aggiungiMarcatore(String squadra, String giocatore, String cosa) async {
    DocumentSnapshot docSnapshot;
    if (widget.tipo == 'girone') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteGironi')
          .doc('${widget.casa} VS ${widget.fuori}')
          .get();
    } else if (widget.tipo == 'ottavi') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteOttavi')
          .doc(widget.codice)
          .get();
    } else if (widget.tipo == 'quarti') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteQuarti')
          .doc(widget.codice)
          .get();
    } else if (widget.tipo == 'semifinali') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteSemifinali')
          .doc(widget.codice)
          .get();
    } else {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteFinali')
          .doc(widget.codice)
          .get();
    }

    List<dynamic> marcatoriFirestore = docSnapshot['marcatori'] ?? [];

    setState(() {
      if (squadra == widget.casa && cosa == 'gol') {
        marcatori.insert(0, {'nome': giocatore, 'dove': 'casa', 'cosa': 'gol'});
        golCasa++;
      } else if (squadra == widget.fuori && cosa == 'gol') {
        marcatori
            .insert(0, {'nome': giocatore, 'dove': 'fuori', 'cosa': 'gol'});
        golFuori++;
      } else if (squadra == widget.casa && cosa == 'amm') {
        marcatori.insert(0, {'nome': giocatore, 'dove': 'casa', 'cosa': 'amm'});
      } else if (squadra == widget.fuori && cosa == 'amm') {
        marcatori
            .insert(0, {'nome': giocatore, 'dove': 'fuori', 'cosa': 'amm'});
      } else if (squadra == widget.casa && cosa == 'esp') {
        marcatori.insert(0, {'nome': giocatore, 'dove': 'casa', 'cosa': 'esp'});
      } else if (squadra == widget.fuori && cosa == 'esp') {
        marcatori
            .insert(0, {'nome': giocatore, 'dove': 'fuori', 'cosa': 'esp'});
      }
    });

    marcatoriFirestore.add({
      'nome': giocatore,
      'dove': squadra == widget.casa ? 'casa' : 'fuori',
      'cosa': cosa
    });

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
          .doc(widget.codice)
          .update({
        'marcatori': marcatoriFirestore,
      });
    } else if (widget.tipo == 'quarti') {
      await FirebaseFirestore.instance
          .collection('ccPartiteQuarti')
          .doc(widget.codice)
          .update({
        'marcatori': marcatoriFirestore,
      });
    } else if (widget.tipo == 'semifinali') {
      await FirebaseFirestore.instance
          .collection('ccPartiteSemifinali')
          .doc(widget.codice)
          .update({
        'marcatori': marcatoriFirestore,
      });
    } else {
      await FirebaseFirestore.instance
          .collection('ccPartiteFinali')
          .doc(widget.codice)
          .update({
        'marcatori': marcatoriFirestore,
      });
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
          .doc(widget.codice)
          .get();
    } else if (widget.tipo == 'quarti') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteQuarti')
          .doc(widget.codice)
          .get();
    } else if (widget.tipo == 'semifinali') {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteSemifinali')
          .doc(widget.codice)
          .get();
    } else {
      docSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteFinali')
          .doc(widget.codice)
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
            .doc(widget.codice)
            .update({
          'marcatori': marcatoriFirestore,
        });
      } else if (widget.tipo == 'quarti') {
        await FirebaseFirestore.instance
            .collection('ccPartiteQuarti')
            .doc(widget.codice)
            .update({
          'marcatori': marcatoriFirestore,
        });
      } else if (widget.tipo == 'semifinali') {
        await FirebaseFirestore.instance
            .collection('ccPartiteSemifinali')
            .doc(widget.codice)
            .update({
          'marcatori': marcatoriFirestore,
        });
      } else {
        await FirebaseFirestore.instance
            .collection('ccPartiteFinali')
            .doc(widget.codice)
            .update({
          'marcatori': marcatoriFirestore,
        });
      }
    }
  }

  Future<void> removePartite(String tipo, String codice) async {
    await FirebaseFirestore.instance
        .collection('ccPartite$tipo')
        .doc(codice)
        .update({
      'iniziata': true,
      'finita': false,
    });

    DocumentSnapshot docSnapshotVincente = await FirebaseFirestore.instance
        .collection('ccPartite$tipo')
        .doc(codice)
        .get();
    Map<String, dynamic> data =
        docSnapshotVincente.data() as Map<String, dynamic>;

    String casa = data['casa'];
    String fuori = data['fuori'];

    String newCodiceVincente = '';
    String newCodicePerdente = '';

    if (tipo == 'Ottavi') {
      tipo = 'Quarti';
      if (codice == 'o0' || codice == 'o1') {
        newCodiceVincente = 'q0';
        newCodicePerdente = 'q4';
      } else if (codice == 'o2' || codice == 'o3') {
        newCodiceVincente = 'q1';
        newCodicePerdente = 'q5';
      } else if (codice == 'o4' || codice == 'o5') {
        newCodiceVincente = 'q2';
        newCodicePerdente = 'q6';
      } else if (codice == 'o6' || codice == 'o7') {
        newCodiceVincente = 'q3';
        newCodicePerdente = 'q7';
      }
    } else if (tipo == 'Quarti') {
      tipo = 'Semifinali';
      if (codice == 'q0' || codice == 'q1') {
        newCodiceVincente = 's0';
        newCodicePerdente = 's2';
      } else if (codice == 'q2' || codice == 'q3') {
        newCodiceVincente = 's1';
        newCodicePerdente = 's3';
      } else if (codice == 'q4' || codice == 'q5') {
        newCodiceVincente = 's4';
        newCodicePerdente = 's6';
      } else if (codice == 'q6' || codice == 'q7') {
        newCodiceVincente = 's5';
        newCodicePerdente = 's7';
      }
    } else if (tipo == 'Semifinali') {
      tipo = 'Finali';
      if (codice == 's0' || codice == 's1') {
        newCodiceVincente = 'f0';
        newCodicePerdente = 'f1';
      } else if (codice == 's2' || codice == 's3') {
        newCodiceVincente = 'f2';
        newCodicePerdente = 'f3';
      } else if (codice == 's4' || codice == 's5') {
        newCodiceVincente = 'f4';
        newCodicePerdente = 'f5';
      } else if (codice == 's6' || codice == 's7') {
        newCodiceVincente = 'f6';
        newCodicePerdente = 'f7';
      }
    } else {
      tipo = '';
      newCodiceVincente = '';
      newCodicePerdente = '';
    }

    //  vincitore
    DocumentSnapshot docSnapshotVincitore = await FirebaseFirestore.instance
        .collection('ccPartite$tipo')
        .doc(newCodiceVincente)
        .get();
    Map<String, dynamic> dataVincitore =
        docSnapshotVincitore.data() as Map<String, dynamic>;
    String? casaV = dataVincitore['casa'];
    if (casa == casaV || fuori == casaV) {
      await FirebaseFirestore.instance
          .collection('ccPartite$tipo')
          .doc(newCodiceVincente)
          .update({
        'casa': '',
      });
    } else {
      await FirebaseFirestore.instance
          .collection('ccPartite$tipo')
          .doc(newCodiceVincente)
          .update({
        'fuori': '',
      });
    }

    //  perdente
    DocumentSnapshot docSnapshotPerdente = await FirebaseFirestore.instance
        .collection('ccPartite$tipo')
        .doc(newCodicePerdente)
        .get();
    Map<String, dynamic> dataPerdente =
        docSnapshotPerdente.data() as Map<String, dynamic>;
    String? casaP = dataPerdente['casa'];
    if (casa == casaP || fuori == casaP) {
      await FirebaseFirestore.instance
          .collection('ccPartite$tipo')
          .doc(newCodicePerdente)
          .update({
        'casa': '',
      });
    } else {
      await FirebaseFirestore.instance
          .collection('ccPartite$tipo')
          .doc(newCodicePerdente)
          .update({
        'fuori': '',
      });
    }
  }

  Future<void> updatePartite(
      String tipo, String codice, List<Map<String, dynamic>> marcatori) async {
    await FirebaseFirestore.instance
        .collection('ccPartite$tipo')
        .doc(codice)
        .update({
      'iniziata': false,
      'finita': true,
    });

    int golCasa = 0;
    int golFuori = 0;
    String vincitore = '';
    String perdente = '';

    for (var marcatore in marcatori) {
      if (marcatore['dove'] == 'casa') {
        golCasa++;
      } else if (marcatore['dove'] == 'fuori') {
        golFuori++;
      }
    }

    if (golCasa > golFuori) {
      vincitore = widget.casa;
      perdente = widget.fuori;
    } else if (golCasa < golFuori) {
      vincitore = widget.fuori;
      perdente = widget.casa;
    }

    if (golCasa != golFuori) {
      String newCodiceVincente = '';
      String newCodicePerdente = '';

      if (tipo == 'Ottavi') {
        tipo = 'Quarti';
        if (codice == 'o0' || codice == 'o1') {
          newCodiceVincente = 'q0';
          newCodicePerdente = 'q4';
        } else if (codice == 'o2' || codice == 'o3') {
          newCodiceVincente = 'q1';
          newCodicePerdente = 'q5';
        } else if (codice == 'o4' || codice == 'o5') {
          newCodiceVincente = 'q2';
          newCodicePerdente = 'q6';
        } else if (codice == 'o6' || codice == 'o7') {
          newCodiceVincente = 'q3';
          newCodicePerdente = 'q7';
        }
      } else if (tipo == 'Quarti') {
        tipo = 'Semifinali';
        if (codice == 'q0' || codice == 'q1') {
          newCodiceVincente = 's0';
          newCodicePerdente = 's2';
        } else if (codice == 'q2' || codice == 'q3') {
          newCodiceVincente = 's1';
          newCodicePerdente = 's3';
        } else if (codice == 'q4' || codice == 'q5') {
          newCodiceVincente = 's4';
          newCodicePerdente = 's6';
        } else if (codice == 'q6' || codice == 'q7') {
          newCodiceVincente = 's5';
          newCodicePerdente = 's7';
        }
      } else if (tipo == 'Semifinali') {
        tipo = 'Finali';
        if (codice == 's0' || codice == 's1') {
          newCodiceVincente = 'f0';
          newCodicePerdente = 'f1';
        } else if (codice == 's2' || codice == 's3') {
          newCodiceVincente = 'f2';
          newCodicePerdente = 'f3';
        } else if (codice == 's4' || codice == 's5') {
          newCodiceVincente = 'f4';
          newCodicePerdente = 'f5';
        } else if (codice == 's6' || codice == 's7') {
          newCodiceVincente = 'f6';
          newCodicePerdente = 'f7';
        }
      } else {
        tipo = '';
        newCodiceVincente = '';
        newCodicePerdente = '';
      }

      //  vincitore
      DocumentSnapshot docSnapshotVincente = await FirebaseFirestore.instance
          .collection('ccPartite$tipo')
          .doc(newCodiceVincente)
          .get();
      Map<String, dynamic> dataVincente =
          docSnapshotVincente.data() as Map<String, dynamic>;
      if (dataVincente['casa'] == '') {
        await FirebaseFirestore.instance
            .collection('ccPartite$tipo')
            .doc(newCodiceVincente)
            .update({
          'casa': vincitore,
        });
      } else {
        await FirebaseFirestore.instance
            .collection('ccPartite$tipo')
            .doc(newCodiceVincente)
            .update({
          'fuori': vincitore,
        });
      }

      //  perdente
      DocumentSnapshot docSnapshotPerdente = await FirebaseFirestore.instance
          .collection('ccPartite$tipo')
          .doc(newCodicePerdente)
          .get();
      Map<String, dynamic> dataPerdente =
          docSnapshotPerdente.data() as Map<String, dynamic>;
      if (dataPerdente['casa'] == '') {
        await FirebaseFirestore.instance
            .collection('ccPartite$tipo')
            .doc(newCodicePerdente)
            .update({
          'casa': perdente,
        });
      } else {
        await FirebaseFirestore.instance
            .collection('ccPartite$tipo')
            .doc(newCodicePerdente)
            .update({
          'fuori': perdente,
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La partita non può finire in parità'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.girone != ''
            ? Text('Girone ${widget.girone}')
            : Text(
                '${widget.tipo[0].toUpperCase()}${widget.tipo.substring(1)}'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: StreamBuilder<DocumentSnapshot>(
          stream: _getPartitaStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var data = snapshot.data!.data() as Map<String, dynamic>;
            var marcatoriFirestore = data['marcatori'] ?? [];

            int golCasa = 0;
            int golFuori = 0;
            List<Map<String, String>> marcatori = [];
            for (var marcatore in marcatoriFirestore) {
              if (marcatore['dove'] == 'casa' && marcatore['cosa'] == 'gol') {
                golCasa++;
              } else if (marcatore['dove'] == 'fuori' &&
                  marcatore['cosa'] == 'gol') {
                golFuori++;
              }
              marcatori.insert(0, {
                'nome': marcatore['nome'],
                'dove': marcatore['dove'],
                'cosa': marcatore['cosa']
              });
            }

            Widget yellowCardIcon() {
              return Container(
                width: 24,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.black, width: 1),
                ),
              );
            }

            Widget redCardIcon() {
              return Container(
                width: 24,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.black, width: 1),
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Image.network(widget.logocasa, width: 90, height: 90),
                          const SizedBox(height: 8),
                          Text(widget.casa,
                              style: const TextStyle(fontSize: 22)),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$golCasa',
                        style: const TextStyle(fontSize: 34),
                      ),
                      const Text(':',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 22)),
                      Text('$golFuori', style: const TextStyle(fontSize: 34)),
                      const SizedBox(width: 4),
                      Column(
                        children: [
                          Image.network(widget.logofuori,
                              width: 90, height: 90),
                          const SizedBox(height: 8),
                          Text(widget.fuori,
                              style: const TextStyle(fontSize: 22)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      widget.casa != '' && widget.fuori != ''
                          ? Expanded(
                              child: ElevatedButton(
                                onPressed: !iniziata
                                    ? () {
                                        setState(() {
                                          iniziata = true;
                                          if (finita &&
                                              widget.tipo == 'girone') {
                                            _updateGironiReverse();
                                          }
                                          finita = false;
                                          widget.tipo == 'girone'
                                              ? FirebaseFirestore.instance
                                                  .collection('ccPartiteGironi')
                                                  .doc(
                                                      '${widget.casa} VS ${widget.fuori}')
                                                  .update({
                                                  'iniziata': true,
                                                  'finita': false,
                                                })
                                              : widget.tipo == 'ottavi'
                                                  ? removePartite(
                                                      'Ottavi', widget.codice)
                                                  : widget.tipo == 'quarti'
                                                      ? removePartite('Quarti',
                                                          widget.codice)
                                                      : widget.tipo ==
                                                              'semifinali'
                                                          ? removePartite(
                                                              'Semifinali',
                                                              widget.codice)
                                                          : removePartite(
                                                              'Finali',
                                                              widget.codice);
                                        });
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: iniziata
                                      ? Colors.grey
                                      : const Color.fromARGB(255, 16, 108, 47),
                                ),
                                child: const Text("Inizio partita"),
                              ),
                            )
                          : Container(),
                      const SizedBox(width: 24),
                      widget.casa != '' && widget.fuori != ''
                          ? Expanded(
                              child: ElevatedButton(
                                onPressed: iniziata
                                    ? () {
                                        setState(() {
                                          iniziata = false;
                                          finita = true;
                                          widget.tipo == 'girone'
                                              ? FirebaseFirestore.instance
                                                  .collection('ccPartiteGironi')
                                                  .doc(
                                                      '${widget.casa} VS ${widget.fuori}')
                                                  .update({
                                                  'iniziata': false,
                                                  'finita': true,
                                                })
                                              : widget.tipo == 'ottavi'
                                                  ? updatePartite('Ottavi',
                                                      widget.codice, marcatori)
                                                  : widget.tipo == 'quarti'
                                                      ? updatePartite(
                                                          'Quarti',
                                                          widget.codice,
                                                          marcatori)
                                                      : widget.tipo ==
                                                              'semifinali'
                                                          ? updatePartite(
                                                              'Semifinali',
                                                              widget.codice,
                                                              marcatori)
                                                          : updatePartite(
                                                              'Finali',
                                                              widget.codice,
                                                              marcatori);
                                        });
                                        widget.tipo == 'girone'
                                            ? _updateGironi()
                                            : null;
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !iniziata
                                      ? Colors.grey
                                      : const Color.fromARGB(255, 150, 9, 9),
                                ),
                                child: const Text("Fine partita"),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
                iniziata
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                FutureBuilder<List<String>>(
                                  future: getGiocatori(widget.casa),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return Container();
                                    return DropdownButton<String>(
                                      hint: const Text('Marcatore'),
                                      items: snapshot.data!
                                          .map((giocatore) =>
                                              DropdownMenuItem<String>(
                                                value: giocatore,
                                                child: Text(giocatore),
                                              ))
                                          .toList(),
                                      onChanged: (giocatore) {
                                        if (giocatore != null) {
                                          aggiungiMarcatore(
                                              widget.casa, giocatore, 'gol');
                                        }
                                      },
                                    );
                                  },
                                ),
                                FutureBuilder<List<String>>(
                                  future: getGiocatori(widget.casa),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return Container();
                                    return DropdownButton<String>(
                                      hint: const Text('Ammonizione'),
                                      items: snapshot.data!
                                          .map((giocatore) =>
                                              DropdownMenuItem<String>(
                                                value: giocatore,
                                                child: Text(giocatore),
                                              ))
                                          .toList(),
                                      onChanged: (giocatore) {
                                        if (giocatore != null) {
                                          aggiungiMarcatore(
                                              widget.casa, giocatore, 'amm');
                                        }
                                      },
                                    );
                                  },
                                ),
                                FutureBuilder<List<String>>(
                                  future: getGiocatori(widget.casa),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return Container();
                                    return DropdownButton<String>(
                                      hint: const Text('Espulsione'),
                                      items: snapshot.data!
                                          .map((giocatore) =>
                                              DropdownMenuItem<String>(
                                                value: giocatore,
                                                child: Text(giocatore),
                                              ))
                                          .toList(),
                                      onChanged: (giocatore) {
                                        if (giocatore != null) {
                                          aggiungiMarcatore(
                                              widget.casa, giocatore, 'esp');
                                        }
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                FutureBuilder<List<String>>(
                                  future: getGiocatori(widget.fuori),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return Container();
                                    return DropdownButton<String>(
                                      hint: const Text('Marcatore'),
                                      items: snapshot.data!
                                          .map((giocatore) =>
                                              DropdownMenuItem<String>(
                                                value: giocatore,
                                                child: Text(giocatore),
                                              ))
                                          .toList(),
                                      onChanged: (giocatore) {
                                        if (giocatore != null) {
                                          aggiungiMarcatore(
                                              widget.fuori, giocatore, 'gol');
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
                                      hint: const Text('Ammonizione'),
                                      items: snapshot.data!
                                          .map((giocatore) =>
                                              DropdownMenuItem<String>(
                                                value: giocatore,
                                                child: Text(giocatore),
                                              ))
                                          .toList(),
                                      onChanged: (giocatore) {
                                        if (giocatore != null) {
                                          aggiungiMarcatore(
                                              widget.fuori, giocatore, 'amm');
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
                                      hint: const Text('Espulsione'),
                                      items: snapshot.data!
                                          .map((giocatore) =>
                                              DropdownMenuItem<String>(
                                                value: giocatore,
                                                child: Text(giocatore),
                                              ))
                                          .toList(),
                                      onChanged: (giocatore) {
                                        if (giocatore != null) {
                                          aggiungiMarcatore(
                                              widget.fuori, giocatore, 'esp');
                                        }
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : Container(),
                const SizedBox(height: 16),
                !iniziata && !finita
                    ? Container()
                    : Center(
                        child: marcatori.isNotEmpty
                            ? const Text("Cronaca",
                                style: TextStyle(
                                    fontSize: 24, fontStyle: FontStyle.italic))
                            : const Center(
                                child: Text('Partita terminata',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontStyle: FontStyle.italic)))),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.builder(
                    itemCount: marcatori.length,
                    itemBuilder: (context, index) {
                      final marcatore = marcatori[index];
                      return Padding(
                        padding: iniziata
                            ? const EdgeInsets.fromLTRB(2, 16, 2, 4)
                            : const EdgeInsets.fromLTRB(12, 20, 12, 4),
                        child: Row(
                          children: [
                            if (marcatore['dove'] == 'casa') ...[
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    iniziata
                                        ? IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              rimuoviMarcatore(widget.casa,
                                                  marcatore['nome']!);
                                            },
                                          )
                                        : const SizedBox(width: 1),
                                    Expanded(
                                      child: Text(
                                        marcatore['nome']!,
                                        style: const TextStyle(fontSize: 18),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              marcatore['cosa'] == 'amm'
                                  ? Container(
                                      width: 20,
                                      height: 25,
                                      decoration: BoxDecoration(
                                        color: Colors.yellow,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    )
                                  : marcatore['cosa'] == 'esp'
                                      ? Container(
                                          width: 20,
                                          height: 25,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        )
                                      : const Icon(Icons.sports_soccer),
                              const Expanded(child: Text('')),
                            ] else ...[
                              const Expanded(child: Text('')),
                              marcatore['cosa'] == 'amm'
                                  ? Container(
                                      width: 20,
                                      height: 25,
                                      decoration: BoxDecoration(
                                        color: Colors.yellow,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    )
                                  : marcatore['cosa'] == 'esp'
                                      ? Container(
                                          width: 20,
                                          height: 25,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        )
                                      : const Icon(Icons.sports_soccer),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '  ${marcatore['nome']!}',
                                        style: const TextStyle(fontSize: 18),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    iniziata
                                        ? IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              rimuoviMarcatore(widget.fuori,
                                                  marcatore['nome']!);
                                            },
                                          )
                                        : const SizedBox(width: 1),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
