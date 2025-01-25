import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CcAggiungiSquadre extends StatefulWidget {
  @override
  _CcAggiungiSquadreState createState() => _CcAggiungiSquadreState();
}

class _CcAggiungiSquadreState extends State<CcAggiungiSquadre> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showAddEditDialog({
    String? club,
    String? squadra,
    bool isEdit = false,
    bool isAddingClub = false,
    bool isEditingClub = false,
  }) {
    final TextEditingController clubController =
        TextEditingController(text: club);
    final TextEditingController squadraController =
        TextEditingController(text: squadra);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit
              ? (isAddingClub ? 'Modifica Club' : 'Modifica Squadra')
              : (isAddingClub ? 'Aggiungi Club' : 'Aggiungi Squadra')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAddingClub ||
                  (!isEdit &&
                      squadra == null &&
                      isAddingClub))
                TextField(
                  controller: clubController,
                  decoration: const InputDecoration(labelText: 'Nome Club'),
                ),
              if (!isAddingClub)
                TextField(
                  controller: squadraController,
                  decoration: const InputDecoration(labelText: 'Nome Squadra'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                final String newClubName = clubController.text;
                final String squadraName = squadraController.text;

                if (isAddingClub && newClubName.isNotEmpty && isEditingClub==false) {
                  final DocumentReference docRef =
                      _firestore.collection('ccSquadre').doc(newClubName);
                  final DocumentSnapshot docSnapshot = await docRef.get();

                  if (docSnapshot.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Il club esiste già')),
                    );
                  } else {
                    await docRef.set({
                      'club': newClubName,
                      'squadre': [],
                    });
                  }
                } else if (newClubName.isNotEmpty && squadraName.isNotEmpty) {
                  final DocumentReference docRef =
                      _firestore.collection('ccSquadre').doc(newClubName);
                  final DocumentSnapshot docSnapshot = await docRef.get();

                  if (docSnapshot.exists) {
                    List<String> squadre =
                        List<String>.from(docSnapshot['squadre']);
                    if (squadre.contains(squadraName)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La squadra esiste già')),
                      );
                    } else {
                      if (isEdit && squadra != null) {
                        squadre[squadre.indexOf(squadra)] = squadraName;
                      } else {
                        squadre.add(squadraName);
                      }
                      await docRef.update({'squadre': squadre});
                    }
                  }
                } else if (isEdit &&
                    club != null &&
                    newClubName.isNotEmpty &&
                    isEditingClub) {
                  final DocumentReference oldDocRef =
                      _firestore.collection('ccSquadre').doc(club);
                  final DocumentSnapshot oldDocSnapshot = await oldDocRef.get();

                  if (oldDocSnapshot.exists && club!=newClubName) {
                    List<String> squadre =
                        List<String>.from(oldDocSnapshot['squadre']);
                    final DocumentReference newDocRef =
                        _firestore.collection('ccSquadre').doc(newClubName);
                    await newDocRef.set({
                      'club': newClubName,
                      'squadre': squadre,
                    });
                    await oldDocRef.delete();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Il club non esiste o è lo stesso')),
                      );
                  }
                }

                Navigator.of(context).pop();
              },
              child: Text(isEdit ? 'Modifica' : 'Salva'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog({required String club, String? squadra}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Conferma Eliminazione'),
          content: Text('Sei sicuro di voler eliminare ${squadra ?? club}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                if (squadra != null) {
                  final DocumentReference docRef =
                      _firestore.collection('ccSquadre').doc(club);
                  final DocumentSnapshot docSnapshot = await docRef.get();

                  if (docSnapshot.exists) {
                    List<String> squadre =
                        List<String>.from(docSnapshot['squadre']);
                    squadre.remove(squadra);
                    await docRef.update({'squadre': squadre});
                  }
                } else {
                  await _firestore.collection('ccSquadre').doc(club).delete();
                }

                Navigator.of(context).pop();
              },
              child: const Text('Elimina'),
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
        title: const Text('Gestione Squadre'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 25, 84, 132),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('ccSquadre').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final clubs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: clubs.length,
            itemBuilder: (context, index) {
              final club = clubs[index];
              final clubName = club['club'];
              final squadre = List<String>.from(club['squadre']);

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(clubName),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showAddEditDialog(
                              club: clubName,
                              isEdit: true,
                              isAddingClub: true,
                              isEditingClub: true,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showDeleteDialog(club: clubName),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _showAddEditDialog(
                              club: clubName,
                              isEdit: false,
                              isAddingClub: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  children: squadre.map((squadra) {
                    return ListTile(
                      title: Text(squadra),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showAddEditDialog(
                              club: clubName,
                              squadra: squadra,
                              isEdit: true,
                              isAddingClub: false,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showDeleteDialog(
                              club: clubName,
                              squadra: squadra,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(isEdit: false, isAddingClub: true),
        child: const Icon(Icons.add),
      ),
    );
  }
}
