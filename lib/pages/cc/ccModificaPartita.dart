import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CCModificaPartita extends StatefulWidget {
  final String casa;
  final String fuori;
  final String logocasa;
  final String logofuori;
  final String data;
  final String orario;
  final String campo;
  final String arbitro;
  final String refertista;
  final String nome;
  final String girone;
  final bool iniziata;
  final bool finita;
  final String tipo;
  final String codice;
  final String ccRole;

  CCModificaPartita({
    required this.casa,
    required this.fuori,
    required this.logocasa,
    required this.logofuori,
    required this.data,
    required this.orario,
    required this.campo,
    required this.arbitro,
    required this.refertista,
    required this.nome,
    required this.girone,
    required this.iniziata,
    required this.finita,
    required this.tipo,
    required this.codice,
    required this.ccRole,
  });

  @override
  _CCModificaPartitaState createState() => _CCModificaPartitaState();
}

class _CCModificaPartitaState extends State<CCModificaPartita> {
  int golCasa = 0;
  int golFuori = 0;
  int gialliCasa = 0;
  int gialliFuori = 0;
  List<Map<String, String>> marcatori = [];
  int golRigoreCasa = 0;
  int golRigoreFuori = 0;
  List<String> rigoriCasa = [];
  List<String> rigoriFuori = [];
  bool iniziata = false;
  bool finita = false;
  bool boolRigori = false;

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

    // Aggiorna cartellini gialli
    gironeData['cartGialli'][widget.casa] =
        (gironeData['cartGialli'][widget.casa] ?? 0) + gialliCasa;
    gironeData['cartGialli'][widget.fuori] =
        (gironeData['cartGialli'][widget.fuori] ?? 0) + gialliFuori;

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

    FirebaseFirestore.instance
        .collection('ccPartiteGironi')
        .doc('${widget.casa} VS ${widget.fuori}')
        .update({
      'iniziata': false,
      'finita': true,
    });

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

    // Aggiorna cartellini gialli
    gironeData['cartGialli'][widget.casa] =
        (gironeData['cartGialli'][widget.casa] ?? 0) - gialliCasa;
    gironeData['cartGialli'][widget.fuori] =
        (gironeData['cartGialli'][widget.fuori] ?? 0) - gialliFuori;

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
    return giocatori
        .map((giocatore) => '${giocatore['maglia']!='' ? giocatore['maglia'] : '?'} ${giocatore['nome']}')
        .toList();
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
        if (marcatore['dove'] == 'casa' && marcatore['cosa'] == 'gol') {
          golCasa++;
        } else if (marcatore['dove'] == 'fuori' && marcatore['cosa'] == 'gol') {
          golFuori++;
        } else if (marcatore['dove'] == 'casa' && marcatore['cosa'] == 'amm') {
          gialliCasa++;
        } else if (marcatore['dove'] == 'fuori' && marcatore['cosa'] == 'amm') {
          gialliFuori++;
        }
        marcatori.add({'nome': marcatore['nome'], 'dove': marcatore['dove'], 'cosa': marcatore['cosa']});
      }

      iniziata = docSnapshot['iniziata'];
      finita = docSnapshot['finita'];

      if (widget.tipo != 'girone') {
        boolRigori = docSnapshot['boolRigori'];
        rigoriCasa = List.from(docSnapshot['rigoriCasa'] ?? []);
        rigoriFuori = List.from(docSnapshot['rigoriFuori'] ?? []);
      }
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
        gialliCasa++;
      } else if (squadra == widget.fuori && cosa == 'amm') {
        marcatori.insert(0, {'nome': giocatore, 'dove': 'fuori', 'cosa': 'amm'});
        gialliFuori++;
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

  void rimuoviMarcatore(String squadra, String giocatore, String cosa) async {
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
      for (int i = 0; i < marcatori.length; i++) {
        if (marcatori[i]['nome'] == giocatore && marcatori[i]['dove'] == (squadra == widget.casa ? 'casa' : 'fuori') && marcatori[i]['cosa'] == cosa) {
          if (squadra == widget.casa && marcatori[i]['cosa'] == 'gol') {
            golCasa--;
          } else if(squadra == widget.fuori && marcatori[i]['cosa'] == 'gol') {
            golFuori--;
          } else if (squadra == widget.casa && marcatori[i]['cosa'] == 'amm') {
            gialliCasa--;
          } else if (squadra == widget.fuori && marcatori[i]['cosa'] == 'amm') {
            gialliFuori--;
          }
          marcatori.removeAt(i);
          break;
        }
      }
    });

    bool foundFirestore = false;
    for (int i = 0; i < marcatoriFirestore.length; i++) {
      if (marcatoriFirestore[i]['nome'] == giocatore &&
          marcatoriFirestore[i]['dove'] ==
              (squadra == widget.casa ? 'casa' : 'fuori') && marcatoriFirestore[i]['cosa'] == cosa) {
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
      String tipo,
      String codice,
      List<Map<String, dynamic>> marcatori,
      List<dynamic> rigoriCasa,
      List<dynamic> rigoriFuori) async {
    int golCasa = 0;
    int golFuori = 0;
    int golRigoreCasa = 0;
    int golRigoreFuori = 0;
    String vincitore = '';
    String perdente = '';

    for (var marcatore in marcatori) {
      if (marcatore['dove'] == 'casa') {
        golCasa++;
      } else if (marcatore['dove'] == 'fuori') {
        golFuori++;
      }
    }

    if (boolRigori) {
      for (var rigCasa in rigoriCasa) {
        if (rigCasa == 'segnato') {
          golRigoreCasa++;
        }
      }
      for (var rigFuori in rigoriFuori) {
        if (rigFuori == 'segnato') {
          golRigoreFuori++;
        }
      }
    }

    if (golCasa != golFuori || golRigoreFuori != golRigoreCasa) {
      iniziata = false;
      finita = true;
      await FirebaseFirestore.instance
          .collection('ccPartite$tipo')
          .doc(codice)
          .update({
        'iniziata': false,
        'finita': true,
      });

      if (golCasa > golFuori || golRigoreCasa > golRigoreFuori) {
        vincitore = widget.casa;
        perdente = widget.fuori;
      } else if (golCasa < golFuori || golRigoreCasa < golRigoreFuori) {
        vincitore = widget.fuori;
        perdente = widget.casa;
      }

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

  void _showRigoreDialog(
      BuildContext context, String squadra, int index, String tipo) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Segnato'),
              onTap: () async {
                if (squadra == 'casa') {
                  rigoriCasa[index] = 'segnato';
                } else {
                  rigoriFuori[index] = 'segnato';
                }
                await FirebaseFirestore.instance
                    .collection(
                        'ccPartite${tipo[0].toUpperCase()}${tipo.substring(1)}')
                    .doc(widget.codice)
                    .update({
                  'rigoriCasa': rigoriCasa,
                  'rigoriFuori': rigoriFuori,
                });
                setState(() {});
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Sbagliato'),
              onTap: () async {
                if (squadra == 'casa') {
                  rigoriCasa[index] = 'sbagliato';
                } else {
                  rigoriFuori[index] = 'sbagliato';
                }
                await FirebaseFirestore.instance
                    .collection(
                        'ccPartite${tipo[0].toUpperCase()}${tipo.substring(1)}')
                    .doc(widget.codice)
                    .update({
                  'rigoriCasa': rigoriCasa,
                  'rigoriFuori': rigoriFuori,
                });
                setState(() {});
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Non tirato'),
              onTap: () async {
                if (squadra == 'casa') {
                  rigoriCasa[index] = 'non tirato';
                } else {
                  rigoriFuori[index] = 'non tirato';
                }
                await FirebaseFirestore.instance
                    .collection(
                        'ccPartite${tipo[0].toUpperCase()}${tipo.substring(1)}')
                    .doc(widget.codice)
                    .update({
                  'rigoriCasa': rigoriCasa,
                  'rigoriFuori': rigoriFuori,
                });
                setState(() {});
                Navigator.pop(context);
              },
            ),
          ],
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
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: StreamBuilder<DocumentSnapshot>(
          stream: _getPartitaStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var data = snapshot.data!.data() as Map<String, dynamic>;
            var marcatoriFirestore = data['marcatori'] ?? [];
            var rigoriCasaFirestore = data['rigoriCasa'] ?? [];
            var rigoriFuoriFirestore = data['rigoriFuori'] ?? [];

            int golCasa = 0;
            int golFuori = 0;
            int golRigoreCasa = 0;
            int golRigoreFuori = 0;
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

            for (var rigCasa in rigoriCasaFirestore) {
              if (rigCasa == 'segnato') {
                golRigoreCasa++;
              }
            }
            for (var rigFuori in rigoriFuoriFirestore) {
              if (rigFuori == 'segnato') {
                golRigoreFuori++;
              }
            }

            return SingleChildScrollView(
                child: Column(
              children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                widget.logocasa.isNotEmpty
                                    ? Image.network(widget.logocasa,
                                        width: 90, height: 90)
                                    : IconButton(
                                        icon: const FaIcon(
                                            FontAwesomeIcons.shieldHalved),
                                        onPressed: () {},
                                      ),
                                const SizedBox(height: 8),
                                AutoSizeText(
                                  widget.casa,
                                  style: const TextStyle(
                                    fontSize: 20,
                                  ),
                                  minFontSize: 20,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Column(children: [
                            Row(children: [
                              Text(
                                '$golCasa',
                                style: const TextStyle(fontSize: 34),
                              ),
                              const Text(' : ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22)),
                              Text('$golFuori',
                                  style: const TextStyle(fontSize: 34)),
                            ]),
                            boolRigori
                                ? Row(
                                    children: [
                                      Text(
                                        '($golRigoreCasa)',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const Text(' dcr ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                      Text('($golRigoreFuori)',
                                          style: const TextStyle(fontSize: 18)),
                                    ],
                                  )
                                : Container()
                          ]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              children: [
                                widget.logofuori.isNotEmpty
                                    ? Image.network(widget.logofuori,
                                        width: 90, height: 90)
                                    : IconButton(
                                        icon: const FaIcon(
                                            FontAwesomeIcons.shieldHalved),
                                        onPressed: () {},
                                      ),
                                const SizedBox(height: 8),
                                AutoSizeText(
                                  widget.fuori,
                                  style: const TextStyle(
                                    fontSize: 20,
                                  ),
                                  minFontSize: 20,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          )
                        ])),
                const SizedBox(height: 16),
                widget.ccRole == 'staff' && widget.nome==widget.refertista
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
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
                                                        .collection(
                                                            'ccPartiteGironi')
                                                        .doc(
                                                            '${widget.casa} VS ${widget.fuori}')
                                                        .update({
                                                        'iniziata': true,
                                                        'finita': false,
                                                      })
                                                    : widget.tipo == 'ottavi'
                                                        ? removePartite(
                                                            'Ottavi',
                                                            widget.codice)
                                                        : widget.tipo ==
                                                                'quarti'
                                                            ? removePartite(
                                                                'Quarti',
                                                                widget.codice)
                                                            : widget.tipo ==
                                                                    'semifinali'
                                                                ? removePartite(
                                                                    'Semifinali',
                                                                    widget
                                                                        .codice)
                                                                : removePartite(
                                                                    'Finali',
                                                                    widget
                                                                        .codice);
                                              });
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: iniziata
                                            ? Colors.grey
                                            : const Color.fromARGB(
                                                255, 16, 108, 47),
                                      ),
                                      child: const AutoSizeText(
                                        'Inizio partita',
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                        minFontSize: 16,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  )
                                : Container(),
                            const SizedBox(width: 10),
                            widget.casa != '' && widget.fuori != ''
                                ? Expanded(
                                    child: ElevatedButton(
                                      onPressed: iniziata
                                          ? () {
                                              setState(() {
                                                golFuori != golCasa &&
                                                        widget.tipo != 'girone'
                                                    ? iniziata = false
                                                    : null;
                                                golFuori != golCasa &&
                                                        widget.tipo != 'girone'
                                                    ? finita = true
                                                    : null;
                                                golFuori != golCasa &&
                                                        widget.tipo != 'girone'
                                                    ? boolRigori = false
                                                    : null;
                                                widget.tipo == 'girone'
                                                    ? () {
                                                        _updateGironi();
                                                        finita = true;
                                                        iniziata = false;
                                                      }()
                                                    : widget.tipo == 'ottavi'
                                                        ? updatePartite(
                                                            'Ottavi',
                                                            widget.codice,
                                                            marcatori,
                                                            rigoriCasa,
                                                            rigoriFuori)
                                                        : widget.tipo ==
                                                                'quarti'
                                                            ? updatePartite(
                                                                'Quarti',
                                                                widget.codice,
                                                                marcatori,
                                                                rigoriCasa,
                                                                rigoriFuori)
                                                            : widget.tipo ==
                                                                    'semifinali'
                                                                ? updatePartite(
                                                                    'Semifinali',
                                                                    widget
                                                                        .codice,
                                                                    marcatori,
                                                                    rigoriCasa,
                                                                    rigoriFuori)
                                                                : updatePartite(
                                                                    'Finali',
                                                                    widget
                                                                        .codice,
                                                                    marcatori,
                                                                    rigoriCasa,
                                                                    rigoriFuori);
                                              });
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: !iniziata
                                            ? Colors.grey
                                            : const Color(0xFF00296B),
                                      ),
                                      child: const AutoSizeText(
                                        'Fine partita',
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                        minFontSize: 16,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                      )
                    : Container(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: Row(children: [
                      golFuori == golCasa &&
                              widget.tipo != 'girone' &&
                              iniziata &&
                              widget.ccRole == 'staff' && widget.nome==widget.refertista
                          ? Expanded(
                              child: ElevatedButton(
                              onPressed: !boolRigori
                                  ? () {
                                      setState(() {
                                        boolRigori = true;
                                        for (int i = 0; i < 5; i++) {
                                          rigoriCasa.add('non tirato');
                                        }
                                        for (int i = 0; i < 5; i++) {
                                          rigoriFuori.add('non tirato');
                                        }
                                        FirebaseFirestore.instance
                                            .collection(
                                                'ccPartite${widget.tipo[0].toUpperCase()}${widget.tipo.substring(1)}')
                                            .doc(widget.codice)
                                            .update({
                                          'boolRigori': true,
                                          'rigoriCasa': rigoriCasa,
                                          'rigoriFuori': rigoriFuori,
                                        });
                                      });
                                    }
                                  : () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Conferma'),
                                            content: const Text(
                                                'Sei sicuro di voler cancellare i rigori?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(); // Chiudi il dialog
                                                },
                                                child: const Text('Annulla'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(); // Chiudi il dialog
                                                  setState(() {
                                                    boolRigori = false;
                                                    rigoriCasa = [];
                                                    rigoriFuori = [];
                                                    FirebaseFirestore.instance
                                                        .collection(
                                                            'ccPartite${widget.tipo[0].toUpperCase()}${widget.tipo.substring(1)}')
                                                        .doc(widget.codice)
                                                        .update({
                                                      'boolRigori': false,
                                                      'rigoriCasa': [],
                                                      'rigoriFuori': [],
                                                    });
                                                  });
                                                },
                                                child: const Text('Conferma'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: boolRigori && iniziata
                                    ? const Color.fromARGB(255, 150, 9, 9)
                                    : const Color.fromARGB(255, 25, 84, 132),
                              ),
                              child: AutoSizeText(
                                boolRigori && iniziata
                                    ? "Cancella rigori"
                                    : "Crea rigori",
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                                minFontSize: 16,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ))
                          : Container(),
                    ]
                  )
                  ),
                iniziata && widget.ccRole == 'staff' && !boolRigori && widget.nome==widget.refertista
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  const SizedBox(height: 12),
                                  FutureBuilder<List<String>>(
                                    future: getGiocatori(widget.casa),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return Container();
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border:
                                              Border.all(color: Colors.grey),
                                        ),
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          underline: const SizedBox.shrink(),
                                          hint: const Text(
                                            'Marcatore',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          items: snapshot.data!
                                              .map((giocatore) =>
                                                  DropdownMenuItem<String>(
                                                    value: giocatore,
                                                    child: Text(giocatore, maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  ))
                                              .toList(),
                                          onChanged: (giocatore) {
                                            if (giocatore != null) {
                                              aggiungiMarcatore(widget.casa,
                                                  giocatore, 'gol');
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  FutureBuilder<List<String>>(
                                    future: getGiocatori(widget.casa),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return Container();
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border:
                                              Border.all(color: Colors.grey),
                                        ),
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          underline: const SizedBox.shrink(),
                                          hint: const Text(
                                            'Ammonizione',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          items: snapshot.data!
                                              .map((giocatore) =>
                                                  DropdownMenuItem<String>(
                                                    value: giocatore,
                                                    child: Text('· $giocatore'),
                                                  ))
                                              .toList(),
                                          onChanged: (giocatore) {
                                            if (giocatore != null) {
                                              aggiungiMarcatore(widget.casa,
                                                  giocatore, 'amm');
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  FutureBuilder<List<String>>(
                                    future: getGiocatori(widget.casa),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return Container();
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border:
                                              Border.all(color: Colors.grey),
                                        ),
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          underline: const SizedBox.shrink(),
                                          hint: const Text(
                                            'Espulsione',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          items: snapshot.data!
                                              .map((giocatore) =>
                                                  DropdownMenuItem<String>(
                                                    value: giocatore,
                                                    child: Text('· $giocatore'),
                                                  ))
                                              .toList(),
                                          onChanged: (giocatore) {
                                            if (giocatore != null) {
                                              aggiungiMarcatore(widget.casa,
                                                  giocatore, 'esp');
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                children: [
                                  const SizedBox(height: 12),
                                  FutureBuilder<List<String>>(
                                    future: getGiocatori(widget.fuori),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return Container();
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border:
                                              Border.all(color: Colors.grey),
                                        ),
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          underline: const SizedBox.shrink(),
                                          hint: const Text(
                                            'Marcatore',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          items: snapshot.data!
                                              .map((giocatore) =>
                                                  DropdownMenuItem<String>(
                                                    value: giocatore,
                                                    child: Text(giocatore, maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  ))
                                              .toList(),
                                          onChanged: (giocatore) {
                                            if (giocatore != null) {
                                              aggiungiMarcatore(widget.fuori,
                                                  giocatore, 'gol');
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  FutureBuilder<List<String>>(
                                    future: getGiocatori(widget.fuori),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return Container();
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border:
                                              Border.all(color: Colors.grey),
                                        ),
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          underline: const SizedBox.shrink(),
                                          hint: const Text(
                                            'Ammonizione',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          items: snapshot.data!
                                              .map((giocatore) =>
                                                  DropdownMenuItem<String>(
                                                    value: giocatore,
                                                    child: Text('· $giocatore'),
                                                  ))
                                              .toList(),
                                          onChanged: (giocatore) {
                                            if (giocatore != null) {
                                              aggiungiMarcatore(widget.fuori,
                                                  giocatore, 'amm');
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  FutureBuilder<List<String>>(
                                    future: getGiocatori(widget.fuori),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return Container();
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border:
                                              Border.all(color: Colors.grey),
                                        ),
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          underline: const SizedBox.shrink(),
                                          hint: const Text(
                                            'Espulsione',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          items: snapshot.data!
                                              .map((giocatore) =>
                                                  DropdownMenuItem<String>(
                                                    value: giocatore,
                                                    child: Text('· $giocatore'),
                                                  ))
                                              .toList(),
                                          onChanged: (giocatore) {
                                            if (giocatore != null) {
                                              aggiungiMarcatore(widget.fuori,
                                                  giocatore, 'esp');
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(),
                !iniziata && !finita
                    ? const Center(
                        child: Column(children: [
                        Text('Partita da giocare',
                            style: TextStyle(
                                fontSize: 21, color: Colors.black54)),
                      ]))
                    : Center(
                        child: Column(children: [
                          widget.ccRole == 'staff'
                              ? const SizedBox(height: 10)
                              : Container(),
                          !finita
                              ? const Text("Partita in corso",
                                  style: TextStyle(
                                      fontSize: 21, color: Colors.black54))
                              : const Center(
                                  child: Text('Partita terminata',
                                      style: TextStyle(
                                          fontSize: 21, color: Colors.black54)))
                        ]),
                      ),
                boolRigori
                    ? Row(children: [
                        Expanded(
                            child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                          margin: const EdgeInsets.fromLTRB(16, 12, 6, 6),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.black54, width: 1.0),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Center(
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 10.0,
                              runSpacing: 10.0,
                              children: [
                                for (int index = 0;
                                    index < rigoriCasa.length;
                                    index++)
                                  GestureDetector(
                                      onTap: () async {
                                        if (iniziata &&
                                            widget.ccRole == 'staff' && widget.nome==widget.refertista) {
                                          _showRigoreDialog(context, 'casa',
                                              index, widget.tipo);
                                        }
                                      },
                                      child: Column(children: [
                                        Text('${index + 1}'),
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundColor: rigoriCasa[index] ==
                                                  'segnato'
                                              ? Colors.green
                                              : rigoriCasa[index] == 'sbagliato'
                                                  ? Colors.red
                                                  : Colors.grey,
                                        ),
                                      ])),
                              ],
                            ),
                          ),
                        )),
                        Expanded(
                            child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 10, 16, 16),
                                margin: const EdgeInsets.fromLTRB(6, 12, 16, 6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black54, width: 1.0),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Center(
                                  child: Wrap(
                                    alignment: WrapAlignment.start,
                                    spacing: 10.0,
                                    runSpacing: 10.0,
                                    children: [
                                      for (int index = 0;
                                          index < rigoriFuori.length;
                                          index++)
                                        GestureDetector(
                                            onTap: () async {
                                              if (iniziata &&
                                                  widget.ccRole == 'staff' && widget.nome==widget.refertista) {
                                                _showRigoreDialog(
                                                    context,
                                                    'fuori',
                                                    index,
                                                    widget.tipo);
                                              }
                                            },
                                            child: Column(children: [
                                              Text('${index + 1}'),
                                              CircleAvatar(
                                                radius: 10,
                                                backgroundColor:
                                                    rigoriFuori[index] ==
                                                            'segnato'
                                                        ? Colors.green
                                                        : rigoriFuori[index] ==
                                                                'sbagliato'
                                                            ? Colors.red
                                                            : Colors.grey,
                                              ),
                                            ])),
                                    ],
                                  ),
                                )))
                      ])
                    : Container(),
                iniziata && widget.ccRole == 'staff' && boolRigori && widget.nome==widget.refertista
                    ? Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.remove),
                              label: const Text('Rimuovi rigore'),
                              style: TextButton.styleFrom(
                                elevation: 15,
                                side: const BorderSide(
                                    color: Colors.black54, width: 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              onPressed: rigoriCasa.length > 5
                                  ? () async {
                                      rigoriCasa.removeLast();
                                      rigoriFuori.removeLast();
                                      await FirebaseFirestore.instance
                                          .collection(
                                              'ccPartite${widget.tipo[0].toUpperCase()}${widget.tipo.substring(1)}')
                                          .doc(widget.codice)
                                          .update({
                                        'rigoriCasa': rigoriCasa,
                                        'rigoriFuori': rigoriFuori,
                                      });
                                      setState(() {});
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Aggiungi rigore'),
                              style: TextButton.styleFrom(
                                elevation: 15,
                                side: const BorderSide(
                                    color: Colors.black54, width: 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              onPressed: () async {
                                rigoriCasa.add('non tirato');
                                rigoriFuori.add('non tirato');
                                await FirebaseFirestore.instance
                                    .collection(
                                        'ccPartite${widget.tipo[0].toUpperCase()}${widget.tipo.substring(1)}')
                                    .doc(widget.codice)
                                    .update({
                                  'rigoriCasa': rigoriCasa,
                                  'rigoriFuori': rigoriFuori,
                                });
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      )
                    : Container(),
                const SizedBox(height: 8),
                Column(
                  children: [
                    for (var marcatore in marcatori)
                      Padding(
                        padding: iniziata
                            ? const EdgeInsets.fromLTRB(2, 0, 2, 0)
                            : const EdgeInsets.fromLTRB(6, 0, 6, 0),
                        child: Column(
                          children: [
                            marcatore['dove'] == 'casa'
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      iniziata && !boolRigori
                                          ? IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                rimuoviMarcatore(widget.casa,
                                                    marcatore['nome']!, marcatore['cosa']!);
                                              },
                                            )
                                          : const SizedBox(width: 20),
                                      marcatore['cosa'] == 'amm'
                                          ? Row(children: [
                                              Container(
                                                width: 18,
                                                height: 23,
                                                decoration: BoxDecoration(
                                                  color: Colors.yellow,
                                                  borderRadius: BorderRadius.circular(2),
                                                  border: Border.all(color: Colors.black54, width: 0.75),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                            ])
                                          : marcatore['cosa'] == 'esp'
                                              ? Row(children: [
                                                  Container(
                                                    width: 18,
                                                    height: 23,
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius: BorderRadius.circular(2),
                                                      border: Border.all(color: Colors.black54, width: 0.75),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                ])
                                              : const Icon(Icons.sports_soccer),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            AutoSizeText(
                                              marcatore['nome']!,
                                              style: const TextStyle(
                                                fontSize: 18,
                                              ),
                                              minFontSize: 18,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            Text(
                                              marcatore['cosa'] == 'gol'
                                                  ? 'Gol'
                                                  : marcatore['cosa'] == 'amm'
                                                      ? 'Ammonizione'
                                                      : 'Espulsione',
                                              style:
                                                  const TextStyle(fontSize: 14),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ]))
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              AutoSizeText(
                                                ' ${marcatore['nome']!}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                                minFontSize: 18,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              Text(
                                                marcatore['cosa'] == 'gol'
                                                    ? 'Gol'
                                                    : marcatore['cosa'] == 'amm'
                                                        ? 'Ammonizione'
                                                        : 'Espulsione',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ]),
                                      ),
                                      const SizedBox(width: 8),
                                      marcatore['cosa'] == 'amm'
                                          ? Row(children: [
                                              const SizedBox(width: 4),
                                              Container(
                                                width: 18,
                                                height: 23,
                                                decoration: BoxDecoration(
                                                  color: Colors.yellow,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                      border: Border.all(color: Colors.black54, width: 0.75),
                                                ),
                                              ),
                                            ])
                                          : marcatore['cosa'] == 'esp'
                                              ? Row(children: [
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    width: 18,
                                                    height: 23,
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              2),
                                                              border: Border.all(color: Colors.black54, width: 0.75),
                                                    ),
                                                  ),
                                                ])
                                              : const Icon(Icons.sports_soccer),
                                      iniziata && !boolRigori
                                          ? IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                rimuoviMarcatore(widget.fuori,
                                                    marcatore['nome']!, marcatore['cosa']!);
                                              },
                                            )
                                          : const SizedBox(width: 20),
                                    ],
                                  ),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(10, 7, 10, 7),
                              child: Divider(
                                  thickness: 0.75, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ));
          },
        ),
      ),
    );
  }
}
