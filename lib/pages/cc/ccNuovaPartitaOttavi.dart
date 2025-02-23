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

  List<List<Partita>> turni =
      List.generate(8, (_) => List.generate(2, (_) => Partita()));
  List<List<TextEditingController>> _timeControllers =
      List.generate(8, (_) => List.generate(2, (_) => TextEditingController()));
  List<List<TextEditingController>> _campiControllers =
      List.generate(8, (_) => List.generate(2, (_) => TextEditingController()));
  List<String> campi = ['', 'C1', 'C2', 'C3'];

  Future<void> _getSquadre() async {
    squadre = [''];
    turni = List.generate(8, (_) => List.generate(2, (_) => Partita()));
    _timeControllers = List.generate(
        8, (_) => List.generate(2, (_) => TextEditingController()));
    _campiControllers = List.generate(
        8, (_) => List.generate(2, (_) => TextEditingController()));
    final QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('ccOttavi').get();
    setState(() {
      squadre = [''];
      for (var doc in querySnapshot.docs) {
        String squadra = doc['squadra'];
        squadre.add(squadra);
      }
    });

    for (int turno = 0; turno < turni.length; turno++) {
      final QuerySnapshot partitaSnapshot =
          await FirebaseFirestore.instance.collection('ccPartiteOttavi').get();
      for (int partita = 0; partita < partitaSnapshot.docs.length; partita++) {
        final doc = partitaSnapshot.docs[partita];
        setState(() {
          turni[turno][partita] =
              Partita.fromMap(doc.data() as Map<String, dynamic>);
          _timeControllers[turno][partita].text =
              turni[turno][partita].orario ?? '';
          _campiControllers[turno][partita].text =
              turni[turno][partita].campo ?? '';
        });
      }
    }
  }

  Future<void> _getGironi() async {
    final QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('ccOttavi').get();
    setState(() {
      gironi = querySnapshot.docs.map((doc) => doc.id).toList();
    });
    print("giorni: $gironi");
    await _getSquadre();
  }

  Future<void> _saveMatch() async {
    for (int turno = 0; turno < turni.length; turno++) {
      for (int partita = 0; partita < turni[turno].length; partita++) {
        final Partita p = turni[turno][partita];
        print(p.casa);
        print(p.fuori);
        final String newDocId = '${p.casa} VS ${p.fuori}';

        if (p.oldDocId != null && p.oldDocId != newDocId) {
          await FirebaseFirestore.instance
              .collection('ccPartiteOttavi')
              .doc(p.oldDocId)
              .delete();
        }

        await FirebaseFirestore.instance
            .collection('ccPartiteOttavi')
            .doc('${p.casa} VS ${p.fuori}')
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
          'codice': 'o$turno$partita'
        });
        p.oldDocId = newDocId;
      }
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
                'Nessun girone',
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
                        Text("Turno ${turno + 1}",
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        for (int partita = 0;
                            partita < turni[turno].length;
                            partita++) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: turni[turno][partita].casa,
                                  items: squadre.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      turni[turno][partita].casa = newValue;
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
                                  value: turni[turno][partita].fuori,
                                  items: squadre.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      turni[turno][partita].fuori = newValue;
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
                                        turni[turno][partita]);
                                    if (orario != null) {
                                      setState(() {
                                        _timeControllers[turno][partita].text =
                                            orario;
                                        turni[turno][partita].orario = orario;
                                      });
                                    }
                                  },
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      controller: _timeControllers[turno]
                                          [partita],
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      onChanged: (value) {
                                        setState(() {
                                          turni[turno][partita].orario = value;
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
                                  value: turni[turno][partita].campo,
                                  items: campi.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      turni[turno][partita].campo = newValue;
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
                                  initialValue: turni[turno][partita].arbitro,
                                  onChanged: (value) {
                                    setState(() {
                                      turni[turno][partita].arbitro = value;
                                    });
                                  },
                                  decoration: getInputDecoration('Arbitro'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
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
