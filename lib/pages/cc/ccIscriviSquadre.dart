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
  Map<String, List<String>> giocatori = {};
  Map<String, bool> hasChanges = {};

  @override
  void initState() {
    super.initState();
    _loadSquadre();
  }

  Future<void> _loadSquadre() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('ccSquadre')
        .where('club', isEqualTo: widget.club)
        .get();

    setState(() {
      squadre = snapshot.docs.expand((doc) => List<String>.from(doc['squadre'])).toList();
      for (var squadra in squadre) {
        print("Squadra: $squadra");
        giocatori[squadra] = [];
        hasChanges[squadra] = false;
      }
    });
  }

  void _addGiocatore(String squadra) {
    setState(() {
      giocatori[squadra]!.add('');
      hasChanges[squadra] = true;
    });
  }

  void _removeGiocatore(String squadra, int index) {
    setState(() {
      giocatori[squadra]!.removeAt(index);
      hasChanges[squadra] = true;
    });
  }

  void _saveSquadra(String squadra) async {
    await FirebaseFirestore.instance.collection('ccIscrizioniSquadre').add({
      'nomeSquadra': squadra,
      'giocatori': giocatori[squadra],
    });

    setState(() {
      hasChanges[squadra] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iscrivi Squadre'),
      ),
      body: ListView.builder(
        itemCount: squadre.length,
        itemBuilder: (context, index) {
          String squadra = squadre[index];
          return ExpansionTile(
            title: Text(squadra),
            children: [
              ListView.builder(
                shrinkWrap: true,
                itemCount: giocatori[squadra]!.length,
                itemBuilder: (context, i) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: giocatori[squadra]![i]),
                          onChanged: (value) {
                            giocatori[squadra]![i] = value;
                            hasChanges[squadra] = true;
                          },
                          autofocus: true,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _removeGiocatore(squadra, i),
                      ),
                    ],
                  );
                },
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => _addGiocatore(squadra),
                  ),
                  if (hasChanges[squadra]!)
                    ElevatedButton(
                      onPressed: () => _saveSquadra(squadra),
                      child: Text('Salva'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}