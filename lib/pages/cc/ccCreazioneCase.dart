import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CcCreazioneCase extends StatefulWidget {
  @override
  _CcCreazioneCaseState createState() => _CcCreazioneCaseState();
}

class _CcCreazioneCaseState extends State<CcCreazioneCase> {
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _postiController = TextEditingController();
  String? _selectedClub;
  List<String> _clubs = [];

  @override
  void initState() {
    super.initState();
    _fetchClubs();
  }

  Future<void> _fetchClubs() async {
    final QuerySnapshot result = await FirebaseFirestore.instance.collection('ccSquadre').get();
    final List<DocumentSnapshot> documents = result.docs;
    setState(() {
      _clubs = documents.map((doc) => doc['club'] as String).toList();
    });
  }

  Future<void> _showDialog({String? numero, String? posti, String? club, bool isEditing = false}) async {
    if (isEditing) {
      _numeroController.text = numero!;
      _postiController.text = posti!;
      _selectedClub = club;
    } else {
      _numeroController.clear();
      _postiController.clear();
      _selectedClub = null;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Modifica Casa' : 'Crea Casa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _numeroController,
                decoration: InputDecoration(labelText: 'Numero casa'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _postiController,
                decoration: InputDecoration(labelText: 'Numero di posti'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedClub,
                hint: Text('Seleziona Club'),
                items: _clubs.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedClub = newValue;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                if (_numeroController.text.isEmpty || _postiController.text.isEmpty) {
                  // Show error
                  return;
                }

                final numero = _numeroController.text;
                final posti = int.parse(_postiController.text);
                final club = _selectedClub ?? '';

                final docRef = FirebaseFirestore.instance.collection('ccCase').doc(numero);

                if (isEditing) {
                  final doc = await docRef.get();
                  if (doc.exists) {
                    final List<dynamic> persone = doc['persone'];
                    for (var persona in persone) {
                      final squadra = persona['squadra'];
                      final nome = persona['nome'];
                      final squadraDoc = FirebaseFirestore.instance.collection('ccIscrizioniSquadre').doc(squadra);
                      final squadraData = await squadraDoc.get();
                      final giocatori = List<Map<String, dynamic>>.from(squadraData['giocatori']);
                      final giocatore = giocatori.firstWhere((g) => g['nome'] == nome);
                      giocatore['appartamento'] = '';
                      await squadraDoc.update({'giocatori': giocatori});
                    }
                    await docRef.update({
                      'posti': posti,
                      'club': club,
                      'persone': [],
                    });
                  }
                } else {
                  final doc = await docRef.get();
                  if (doc.exists) {
                    // Show error
                    return;
                  }
                  await docRef.set({
                    'numero': numero,
                    'posti': posti,
                    'persone': [],
                    'club': club,
                  });
                }

                Navigator.of(context).pop();
              },
              child: Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestione case'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ccCase').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final cases = snapshot.data!.docs;

          return ListView.builder(
            itemCount: cases.length,
            itemBuilder: (context, index) {
              final caseData = cases[index];
              final numero = caseData['numero'];
              final posti = caseData['posti'];
              final persone = List<Map<String, dynamic>>.from(caseData['persone']);
              final club = caseData['club'];

              return Card(
                child: ExpansionTile(
                  title: Text('Casa $numero'),
                  children: [
                    ListTile(
                      title: Text('Posti: $posti'),
                      subtitle: Text('Club: $club'),
                    ),
                    ...persone.map((persona) {
                      return ListTile(
                        title: Text('Nome: ${persona['nome']}'),
                        subtitle: Text('Squadra: ${persona['squadra']}'),
                      );
                    }).toList(),
                    TextButton(
                      onPressed: () => _showDialog(
                        numero: numero,
                        posti: posti.toString(),
                        club: club,
                        isEditing: true,
                      ),
                      child: Text('Modifica'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: Icon(Icons.add),
      ),
    );
  }
}