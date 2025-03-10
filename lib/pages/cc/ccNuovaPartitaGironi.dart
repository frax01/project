import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CCnuovaPartitaGironi extends StatefulWidget {
  const CCnuovaPartitaGironi({
    super.key,
  });

  @override
  State<CCnuovaPartitaGironi> createState() => _CCnuovaPartitaGironiState();
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

  Partita(
      {this.casa,
      this.fuori,
      this.orario,
      this.campo,
      this.arbitro,
      this.oldDocId,
      this.marcatori,
      this.refertista});

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
    );
  }
}

class _CCnuovaPartitaGironiState extends State<CCnuovaPartitaGironi> {
  List<String> squadre = [];
  List<String> staff = [];
  List<String> gironi = [];
  late String _selectedSegment;
  late Future<void> _futureGironi;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<List<Partita>> turni =
      List.generate(3, (_) => List.generate(2, (_) => Partita()));
  List<List<TextEditingController>> _timeControllers =
      List.generate(3, (_) => List.generate(2, (_) => TextEditingController()));
  List<List<TextEditingController>> _campiControllers =
      List.generate(3, (_) => List.generate(2, (_) => TextEditingController()));
  List<String> campi = ['', 'C1', 'C2', 'C3'];

  Future<void> _getSquadre() async {
    squadre = [''];
    staff = [''];
    turni = List.generate(3, (_) => List.generate(2, (_) => Partita()));
    _timeControllers = List.generate(
        3, (_) => List.generate(2, (_) => TextEditingController()));
    _campiControllers = List.generate(
        3, (_) => List.generate(2, (_) => TextEditingController()));
    final DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('ccGironi')
        .doc(_selectedSegment)
        .get();

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('ccStaff').get();

    setState(() {
      squadre = [''];
      if (docSnapshot.exists) {
        List<dynamic> squadreList = docSnapshot['squadre'];
        squadre.addAll(squadreList.cast<String>());
      }

      if(snapshot.docs.isNotEmpty){
        for (var doc in snapshot.docs) {
          staff.add(doc['nome']);
        }
      }
    });

    for (int turno = 0; turno < turni.length; turno++) {
      final QuerySnapshot partitaSnapshot = await FirebaseFirestore.instance
          .collection('ccPartiteGironi')
          .where('girone', isEqualTo: _selectedSegment)
          .where('turno', isEqualTo: (turno + 1).toString())
          .get();
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
        await FirebaseFirestore.instance.collection('ccGironi').get();
    setState(() {
      gironi = querySnapshot.docs.map((doc) => doc.id).toList();
    });
    _selectedSegment = gironi.first;
    await _getSquadre();
  }

  Future<void> _saveMatch() async {
    for (int turno = 0; turno < turni.length; turno++) {
      for (int partita = 0; partita < turni[turno].length; partita++) {
        final Partita p = turni[turno][partita];
        final String newDocId = '${p.casa} VS ${p.fuori}';

        if (p.oldDocId != null && p.oldDocId != newDocId) {
          await FirebaseFirestore.instance
              .collection('ccPartiteGironi')
              .doc(p.oldDocId)
              .delete();
        }

        await FirebaseFirestore.instance
            .collection('ccPartiteGironi')
            .doc('${p.casa} VS ${p.fuori}')
            .set({
          'girone': _selectedSegment,
          'casa': p.casa,
          'fuori': p.fuori,
          'orario': p.orario ?? '',
          'campo': p.campo ?? '',
          'arbitro': p.arbitro ?? '',
          'refertista': p.refertista ?? '',
          'turno': (turno + 1).toString(),
          'data': '24/04/2025',
          'iniziata': false,
          'finita': false,
          'marcatori': p.marcatori ?? [],
          'tipo': 'girone',
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
        title: const Text('Partite girone'),
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
                      SegmentedButton<String>(
                        selectedIcon: const Icon(Icons.check),
                        segments: gironi.map((girone) {
                          return ButtonSegment<String>(
                            value: girone,
                            label: Text(girone,
                                style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        selected: <String>{_selectedSegment},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedSegment = newSelection.first;
                            _getSquadre();
                          });
                        },
                      ),
                      const SizedBox(height: 30),
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
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: turni[turno][partita].arbitro,
                                    items: staff.map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        turni[turno][partita].arbitro =
                                            newValue;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Obbligatorio';
                                      }
                                      return null;
                                    },
                                    decoration: getInputDecoration('Arbitro'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: turni[turno][partita].refertista,
                                    items: staff.map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        turni[turno][partita].refertista =
                                            newValue;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Obbligatorio';
                                      }
                                      return null;
                                    },
                                    decoration: getInputDecoration('Refertista'),
                                  ),
                                ),
                              ]),
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
