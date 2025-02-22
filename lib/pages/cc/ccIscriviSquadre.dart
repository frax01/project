import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CcIscriviSquadre extends StatefulWidget {
  final String club;

  CcIscriviSquadre({required this.club});

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

  @override
  void initState() {
    super.initState();
    _loadSquadreFuture = _loadSquadre();
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
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('ccSquadre')
        .where('club', isEqualTo: widget.club)
        .get();

    List<Map<String, dynamic>> loadedSquadre = snapshot.docs
        .expand((doc) => List<Map<String, dynamic>>.from(doc['squadre']))
        .toList();
    Map<String, List<dynamic>> loadedGiocatori = {};
    Map<String, bool> loadedHasChanges = {};

    for (var squadra in loadedSquadre) {
      List<Map<String, dynamic>> players = await retrievePlayers(squadra['squadra']);
      loadedGiocatori[squadra['squadra']] = players.map((player) => player['nome']!).toList();
      giocatoriControllers[squadra['squadra']] = players.map((player) => TextEditingController(text: player['nome'])).toList();
      magliaControllers[squadra['squadra']] = players.map((player) => TextEditingController(text: player['maglia'])).toList();
      appartamentoControllers[squadra['squadra']] = players.map((player) => TextEditingController(text: player['appartamento'])).toList();
      loadedHasChanges[squadra['squadra']] = false;
    }

    setState(() {
      squadre = loadedSquadre.map((squadra) => squadra['squadra'] as String).toList();
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

void _removeGiocatore(String squadra, int index) {
  setState(() {
    giocatori[squadra]!.removeAt(index);
    giocatoriControllers[squadra]!.removeAt(index);
    magliaControllers[squadra]!.removeAt(index);
    appartamentoControllers[squadra]!.removeAt(index);
    hasChanges[squadra] = true;
  });
}

  void _saveSquadra(String squadra) async {
  List<Map<String, String>> giocatoriData = [];
  for (int i = 0; i < giocatori[squadra]!.length; i++) {
    giocatoriData.add({
      'nome': giocatori[squadra]![i],
      'maglia': magliaControllers[squadra]![i].text,
      'appartamento': appartamentoControllers[squadra]![i].text,
    });
  }

  await FirebaseFirestore.instance
      .collection('ccIscrizioniSquadre')
      .doc(squadra)
      .set({
    'nomeSquadra': squadra,
    'giocatori': giocatoriData,
  });

  setState(() {
    hasChanges[squadra] = false;
  });
}

  Map<String, List<TextEditingController>> magliaControllers = {};
  Map<String, List<TextEditingController>> appartamentoControllers = {};
  Map<String, List<TextEditingController>> golControllers = {};
  Map<String, List<TextEditingController>> ammControllers = {};
  Map<String, List<TextEditingController>> espControllers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iscrivi Squadre'),
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
                  return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
                      child: ExpansionTile(
                        title: Text('Squadra ${index+1}', style: const TextStyle(fontStyle: FontStyle.italic),),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(squadra, style: const TextStyle(fontSize: 25)),
                            giocatori[squadra]!.length==1 ? const Text('1 giocatore', style: TextStyle(fontSize: 17))
                            : Text('${giocatori[squadra]!.length} giocatori', style: const TextStyle(fontSize: 17))
                          ],
                        ),
                        shape: Border.all(color: Colors.transparent),
                        children: [
                          Form(
                            key: _formKey,
                            child:
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: giocatori[squadra]!.length,
                              itemBuilder: (context, i) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextFormField(
                                                    textCapitalization: TextCapitalization.sentences,
                                                    controller: giocatoriControllers[squadra]![i],
                                                    onChanged: (value) {
                                                      giocatori[squadra]![i] = value;
                                                      setState(() {
                                                        hasChanges[squadra] = true;
                                                      });
                                                    },
                                                    validator: (value) {
                                                      if (value == null || value.isEmpty) {
                                                        return 'Inserisci il giocatore';
                                                      }
                                                      return null;
                                                    },
                                                    decoration: const InputDecoration(
                                                      labelText: 'Nome e cognome',
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      border: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Colors.black54),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Colors.black54),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Color.fromARGB(255, 25, 84, 132)),
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
                                                    controller: magliaControllers[squadra]![i],
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        hasChanges[squadra] = true;
                                                      });
                                                    },
                                                    validator: (value) {
                                                      if (value != null && value.isNotEmpty) {
                                                        final int? number = int.tryParse(value);
                                                        if (number == null || number < 0 || number > 99) {
                                                          return 'Numero non valido';
                                                        }
                                                      }
                                                      return null;
                                                    },
                                                    decoration: const InputDecoration(
                                                      labelText: 'N° maglia',
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      border: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Colors.black54),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Colors.black54),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Color.fromARGB(255, 25, 84, 132)),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: TextFormField(
                                                    controller: appartamentoControllers[squadra]![i],
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        hasChanges[squadra] = true;
                                                      });
                                                    },
                                                    validator: (value) {
                                                      if (value != null && value.isNotEmpty) {
                                                        final int? number = int.tryParse(value);
                                                        if (number == null) {
                                                          return 'Inserisci un numero valido';
                                                        }
                                                      }
                                                      return null;
                                                    },
                                                    decoration: const InputDecoration(
                                                      labelText: 'N° appartamento',
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      border: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Colors.black54),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Colors.black54),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Color.fromARGB(255, 25, 84, 132)),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            //const SizedBox(height: 8),
                                            //const Row(
                                            //  children: [
                                            //    Expanded(
                                            //      child: const ListTile(
                                            //        title: const Text('Gol'),
                                            //        subtitle: const Text('0'),
                                            //      ),
                                            //    ),
                                            //    const SizedBox(width: 8),
                                            //    Expanded(
                                            //      child:const ListTile(
                                            //      title: const Text('Amm'),
                                            //      subtitle: const Text('0'),
                                            //    ),),
                                            //    const SizedBox(width: 8),
                                            //    Expanded(
                                            //      child:const ListTile(
                                            //      title: const Text('Esp'),
                                            //      subtitle: const Text('0'),
                                            //    ),)
                                            //  ],
                                            //),
                                          ],
                                        ),
                                      ),
                                      Center(
                                        child: 
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _removeGiocatore(squadra, i),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _addGiocatore(squadra),
                                highlightColor: const Color.fromARGB(255, 25, 84, 132),
                              ),
                              ElevatedButton(
                                onPressed: hasChanges[squadra]! ? () {
                                  if (_formKey.currentState!.validate()) {
                                    _saveSquadra(squadra);
                                  }
                                } : null,
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
