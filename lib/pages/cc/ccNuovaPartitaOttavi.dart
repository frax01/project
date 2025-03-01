import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CCnuovaPartitaOttavi extends StatefulWidget {
  const CCnuovaPartitaOttavi({
    super.key,
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
  String? oldDocId;
  List<Map<String, dynamic>>? marcatori;

  Partita(
      {this.casa,
      this.fuori,
      this.orario,
      this.campo,
      this.arbitro,
      this.oldDocId,
      this.marcatori});

  factory Partita.fromMap(Map<String, dynamic> data) {
    return Partita(
      casa: data['casa'],
      fuori: data['fuori'],
      orario: data['orario'],
      campo: data['campo'],
      arbitro: data['arbitro'],
      oldDocId: '${data['casa']} VS ${data['fuori']}',
      marcatori: data['marcatori'] != null
          ? List<Map<String, dynamic>>.from(data['marcatori'])
          : null,
    );
  }
}

class _CCnuovaPartitaOttaviState extends State<CCnuovaPartitaOttavi> {
  List<String> squadre = [];
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
    turni = List.generate(8, (_) => Partita());
    _timeControllers = List.generate(8, (_) => TextEditingController());
    _campiControllers = List.generate(8, (_) => TextEditingController());
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('ccOttavi')
        .get();
    setState(() {
      squadre = [''];
      for (var doc in querySnapshot.docs) {
        String squadra = doc['squadra'];
        squadre.add(squadra);
      }
    });

    final QuerySnapshot partitaSnapshot = await FirebaseFirestore.instance
        .collection('ccPartiteOttavi')
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
    final QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('ccOttavi').get();
    setState(() {
      gironi = querySnapshot.docs.map((doc) => doc.id).toList();
    });
    await _getSquadre();
  }

  Future<void> _saveMatch() async {
    for (int turno = 0; turno < turni.length; turno++) {
      final Partita p = turni[turno];
      final String newDocId = 'o$turno';

      if (p.casa == null || p.fuori == null) {
        print('Errore: Casa o Fuori è null');
        continue;
      }

      if (p.oldDocId != null && p.oldDocId != newDocId) {
        await FirebaseFirestore.instance
            .collection('ccPartiteOttavi')
            .doc(p.oldDocId)
            .delete();
      }

      await FirebaseFirestore.instance
          .collection('ccPartiteOttavi')
          .doc(newDocId)
          .set({
        'casa': p.casa,
        'fuori': p.fuori,
        'orario': p.orario ?? '',
        'campo': p.campo ?? '',
        'arbitro': p.arbitro ?? '',
        'data': '26/04/2025',
        'iniziata': false,
        'finita': false,
        'marcatori': p.marcatori ?? [],
        'tipo': 'ottavi',
        'codice': 'o$turno'
      });
      p.oldDocId = newDocId;
    }
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
        title: const Text('Partite ottavi'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 25, 84, 132),
          ),
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
                style: TextStyle(fontSize: 20.0, color: Colors.black54),
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
                        Text("Ottavo ${turno + 1}",
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: turni[turno].casa,
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
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Obbligatorio';
                                  }
                                  return null;
                                },
                                decoration: getInputDecoration('Casa'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: turni[turno].fuori,
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
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Obbligatorio';
                                  }
                                  return null;
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
                                  final String? orario = await _selectTime(
                                      turni[turno]);
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
                                value: turni[turno].campo,
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
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                textCapitalization:
                                    TextCapitalization.sentences,
                                initialValue: turni[turno].arbitro,
                                onChanged: (value) {
                                  setState(() {
                                    turni[turno].arbitro = value;
                                  });
                                },
                                decoration: getInputDecoration('Arbitro'),
                              ),
                            ),
                          ],
                        ),
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