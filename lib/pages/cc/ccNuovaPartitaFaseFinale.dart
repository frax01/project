import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CCnuovaPartitaOttavi extends StatefulWidget {
  final String tipo;

  const CCnuovaPartitaOttavi({
    super.key,
    required this.tipo,
  });

  @override
  State<CCnuovaPartitaOttavi> createState() => _CCnuovaPartitaOttaviState();
}

class Partita {
  String? casa;
  String? fuori;
  String? orario;
  String? campo;
  String? arbitro;
  String? refertista;
  String? oldDocId;
  List<Map<String, dynamic>>? marcatori;
  List<dynamic>? rigoriCasa;
  List<dynamic>? rigoriFuori;
  bool? finita;
  bool? iniziata;
  bool? boolRigori;
  String? tipo;
  String? codice;

  Partita(
      {this.casa,
      this.fuori,
      this.orario,
      this.campo,
      this.arbitro,
      this.refertista,
      this.oldDocId,
      this.marcatori,
      this.rigoriCasa,
      this.rigoriFuori,
      this.finita,
      this.iniziata,
      this.boolRigori,
      this.codice});

  factory Partita.fromMap(Map<String, dynamic> data) {
    return Partita(
      casa: data['casa'],
      fuori: data['fuori'],
      orario: data['orario'],
      campo: data['campo'],
      arbitro: data['arbitro'],
      refertista: data['refertista'],
      oldDocId: '${data['casa']} VS ${data['fuori']}',
      marcatori: data['marcatori'] != null
          ? List<Map<String, dynamic>>.from(data['marcatori'])
          : null,
      rigoriCasa: data['rigoriCasa'] != null
          ? List<dynamic>.from(data['rigoriCasa'])
          : null,
      rigoriFuori: data['rigoriFuori'] != null
          ? List<dynamic>.from(data['rigoriFuori'])
          : null,
      finita: data['finita'],
      iniziata: data['iniziata'],
      boolRigori: data['boolRigori'],
      codice: data['codice'],
    );
  }
}

class _CCnuovaPartitaOttaviState extends State<CCnuovaPartitaOttavi> {
  List<String> squadre = [];
  List<String> staff = [];
  List<String> gironi = [];
  late Future<void> _futureGironi;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<Partita> turni = List.generate(8, (_) => Partita());
  List<TextEditingController> _timeControllers =
      List.generate(8, (_) => TextEditingController());
  List<TextEditingController> _campiControllers =
      List.generate(8, (_) => TextEditingController());
  List<String> campi = ['', 'C1', 'C2', 'C3'];

  Future<void> _getSquadre() async {
    squadre = [''];
    staff = [''];
    turni = List.generate(8, (_) => Partita());
    _timeControllers = List.generate(8, (_) => TextEditingController());
    _campiControllers = List.generate(8, (_) => TextEditingController());

    final QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('ccSquadre').get();

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('ccStaff').get();

    setState(() {
      squadre = [''];
      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          List<dynamic> squadreList = doc['squadre'];
          for (var squadra in squadreList) {
            squadre.add(squadra['squadra']);
          }
        }
      }

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          staff.add(doc['nome']);
        }
      }
    });

    final QuerySnapshot partitaSnapshot = await FirebaseFirestore.instance
        .collection('ccPartite${widget.tipo}')
        .get();
    for (int turno = 0; turno < turni.length; turno++) {
      if (turno >= partitaSnapshot.docs.length) {
        break;
      }
      final doc = partitaSnapshot.docs[turno];
      setState(() {
        turni[turno] = Partita.fromMap(doc.data() as Map<String, dynamic>);
        _timeControllers[turno].text = turni[turno].orario ?? '';
        _campiControllers[turno].text = turni[turno].campo ?? '';
      });
    }
  }

  Future<void> _getGironi() async {
    //final QuerySnapshot querySnapshot =
    //    await FirebaseFirestore.instance.collection('ccOttavi').get();
    //setState(() {
    //  gironi = querySnapshot.docs.map((doc) => doc.id).toList();
    //});
    await _getSquadre();
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

  Future<void> _saveMatch() async {
    _showLoadingDialog();
    for (int turno = 0; turno < turni.length; turno++) {
      final Partita p = turni[turno];
      final String newDocId = '${p.codice![0]}$turno';

      if (p.casa == null || p.fuori == null) {
        print('Errore: Casa o Fuori è null');
        continue;
      }

      if (p.oldDocId != null && p.oldDocId != newDocId) {
        await FirebaseFirestore.instance
            .collection('ccPartite${widget.tipo}')
            .doc(p.oldDocId)
            .delete();
      }

      await FirebaseFirestore.instance
          .collection('ccPartite${widget.tipo}')
          .doc(newDocId)
          .set({
        'casa': p.casa,
        'fuori': p.fuori,
        'orario': p.orario ?? '',
        'campo': p.campo ?? '',
        'arbitro': p.arbitro ?? '',
        'refertista': p.refertista ?? '',
        'data': '26/04/2025',
        'iniziata': p.iniziata ?? false,
        'finita': p.finita ?? false,
        'marcatori': p.marcatori ?? [],
        'tipo': '${widget.tipo[0].toLowerCase()}${widget.tipo.substring(1)}',
        'codice': '${p.codice![0]}$turno',
        'rigoriCasa': p.rigoriCasa ?? [],
        'rigoriFuori': p.rigoriFuori ?? [],
        'boolRigori': p.boolRigori ?? false,
      });
      p.oldDocId = newDocId;
    }
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  Future<String?> _selectTime(Partita partita) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      return DateFormat('HH:mm').format(selectedDateTime);
    }
    return null;
  }

  InputDecoration getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(overflow: TextOverflow.ellipsis),
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
  void initState() {
    super.initState();
    _futureGironi = _getGironi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Partite ${widget.tipo[0].toLowerCase()}${widget.tipo.substring(1)}'
        ),
      ),
      body: FutureBuilder<void>(
        future: _futureGironi,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          } else if (squadre.isEmpty) {
            return const Center(
              child: Text(
                'Nessuna squadra',
                style: TextStyle(fontSize: 19, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int turno = 0; turno < turni.length; turno++) ...[
                        Text("${widget.tipo} ${turno + 1}",
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: turni[turno].casa?.isNotEmpty == true
                                    ? turni[turno].casa
                                    : null,
                                items: squadre.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    turni[turno].casa = newValue;
                                  });
                                },
                                decoration: getInputDecoration('Casa'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: turni[turno].fuori?.isNotEmpty == true
                                    ? turni[turno].fuori
                                    : null,
                                items: squadre.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    turni[turno].fuori = newValue;
                                  });
                                },
                                decoration: getInputDecoration('Fuori'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final String? orario =
                                      await _selectTime(turni[turno]);
                                  if (orario != null) {
                                    setState(() {
                                      _timeControllers[turno].text = orario;
                                      turni[turno].orario = orario;
                                    });
                                  }
                                },
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: _timeControllers[turno],
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    onChanged: (value) {
                                      setState(() {
                                        turni[turno].orario = value;
                                      });
                                    },
                                    decoration: getInputDecoration('Orario'),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: turni[turno].campo?.isNotEmpty == true
                                    ? turni[turno].campo
                                    : null,
                                items: campi.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    turni[turno].campo = newValue;
                                  });
                                },
                                decoration: getInputDecoration('Campo'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value:
                                      turni[turno].arbitro?.isNotEmpty == true
                                          ? turni[turno].arbitro
                                          : null,
                                  items: staff.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      turni[turno].arbitro = newValue;
                                    });
                                  },
                                  decoration: getInputDecoration('Arbitro'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: turni[turno].refertista?.isNotEmpty ==
                                          true
                                      ? turni[turno].refertista
                                      : null,
                                  items: staff.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      turni[turno].refertista = newValue;
                                    });
                                  },
                                  decoration: getInputDecoration('Refertista'),
                                ),
                              ),
                            ]),
                        const SizedBox(height: 30),
                      ],
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _saveMatch();
                            }
                          },
                          child: const Text('Salva'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}