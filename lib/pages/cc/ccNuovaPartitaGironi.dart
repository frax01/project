import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CCnuovaPartitaGironi extends StatefulWidget {
  const CCnuovaPartitaGironi({
    super.key,
  });

  @override
  State<CCnuovaPartitaGironi> createState() => _CCnuovaPartitaGironiState();
}

class _CCnuovaPartitaGironiState extends State<CCnuovaPartitaGironi> {
  List<String> squadre = [];
  List<String> gironi = [];
  late String _selectedSegment;
  late Future<void> _futureGironi;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _casa1turno1;
  String? _fuori1turno1;
  String? _orario1turno1;
  String? _campo1turno;
  String? _arbitro1turno1;

  Future<void> _getSquadre() async {
    final DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('ccGironi')
        .doc(_selectedSegment)
        .get();
    setState(() {
      squadre = [''];
      if (docSnapshot.exists) {
        List<dynamic> squadreList = docSnapshot['squadre'];
        squadre.addAll(squadreList.cast<String>());
      }
    });
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

  Future<void> _saveSquadra(String squadra) async {
    await FirebaseFirestore.instance
        .collection('ccPartiteGironi')
        .doc('$_casa1turno1 VS $_fuori1turno1')
        .set({
      'girone': _selectedSegment,
      'casa': _casa1turno1,
      'fuori': _fuori1turno1,
      'orario': _orario1turno1,
      'campo': _campo1turno,
      'arbitro': _arbitro1turno1,
      'turno': '1',
      'data': '24/04/2025'
    });
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
        body: FutureBuilder(
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
                                  onSelectionChanged:
                                      (Set<String> newSelection) {
                                    setState(() {
                                      _selectedSegment = newSelection.first;
                                      _getSquadre();
                                    });
                                  },
                                ),
                                const SizedBox(height: 30),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Turno 1",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 10),
                                      Column(children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: DropdownButtonFormField<
                                                  String>(
                                                value: _casa1turno1,
                                                items:
                                                    squadre.map((String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return 'Obbligatorio';
                                                  }
                                                  return null;
                                                },
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    _casa1turno1 = newValue;
                                                  });
                                                },
                                                decoration: getInputDecoration("Casa")
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: DropdownButtonFormField<
                                                  String>(
                                                value:
                                                    _fuori1turno1,
                                                items:
                                                    squadre.map((String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return 'Obbligatorio';
                                                  }
                                                  return null;
                                                },
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    _fuori1turno1 = newValue;
                                                  });
                                                },
                                                decoration: getInputDecoration("Fuori")
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  textCapitalization:
                                                      TextCapitalization
                                                          .sentences,
                                                  controller:
                                                      null, //giocatoriControllers[squadra]![i],
                                                  onChanged: (value) {
                                                    //giocatori[squadra]![i] = value;
                                                    setState(() {
                                                      //hasChanges[squadra] = true;
                                                    });
                                                  },
                                                  decoration: getInputDecoration("Orario")
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: TextFormField(
                                                  textCapitalization:
                                                      TextCapitalization
                                                          .sentences,
                                                  controller:
                                                      null, //giocatoriControllers[squadra]![i],
                                                  onChanged: (value) {
                                                    //giocatori[squadra]![i] = value;
                                                    setState(() {
                                                      //hasChanges[squadra] = true;
                                                    });
                                                  },
                                                  decoration: getInputDecoration("Campo")
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: TextFormField(
                                                  textCapitalization:
                                                      TextCapitalization
                                                          .sentences,
                                                  controller:
                                                      null, //giocatoriControllers[squadra]![i],
                                                  onChanged: (value) {
                                                    //giocatori[squadra]![i] = value;
                                                    setState(() {
                                                      //hasChanges[squadra] = true;
                                                    });
                                                  },
                                                  decoration: getInputDecoration("Arbitro")
                                                ),
                                              ),
                                            ])
                                      ]),
                                      //
                                      //
                                      //
                                      //
                                      //
                                      const SizedBox(height: 30),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value: null, //_selectedMaglia,
                                              items:
                                                  squadre.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  //_selectedMaglia = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Casa',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 25, 84, 132)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value:
                                                  null, //_selectedAppartamento,
                                              items:
                                                  squadre.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  //_selectedAppartamento = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Fuori',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 25, 84, 132)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ]),
                                const SizedBox(height: 30),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Turno 2",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value: null, //_selectedMaglia,
                                              items:
                                                  squadre.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  //_selectedMaglia = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Casa',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 25, 84, 132)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value:
                                                  null, //_selectedAppartamento,
                                              items:
                                                  squadre.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  //_selectedAppartamento = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Fuori',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 25, 84, 132)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value: null, //_selectedMaglia,
                                              items:
                                                  squadre.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  //_selectedMaglia = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Casa',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 25, 84, 132)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value:
                                                  null, //_selectedAppartamento,
                                              items:
                                                  squadre.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  //_selectedAppartamento = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Fuori',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 25, 84, 132)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ]),
                                const SizedBox(height: 30),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Turno 3",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value: null, //_selectedMaglia,
                                              items:
                                                  squadre.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  //_selectedMaglia = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Casa',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 25, 84, 132)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value:
                                                  null, //_selectedAppartamento,
                                              items:
                                                  squadre.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  //_selectedAppartamento = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Fuori',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 25, 84, 132)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value: null, //_selectedMaglia,
                                              items:
                                                  squadre.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  //_selectedMaglia = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Casa',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 25, 84, 132)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value:
                                                  null, //_selectedAppartamento,
                                              items:
                                                  squadre.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  //_selectedAppartamento = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Fuori',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.black54),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 25, 84, 132)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ]),
                                const SizedBox(height: 30),
                                Center(
                                    child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      _saveSquadra('squadra');
                                    }
                                  },
                                  child: const Text('Salva'),
                                ))
                              ],
                            ))));
              }
            }));
  }
}