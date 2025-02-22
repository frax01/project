import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class CcAggiungiSquadre extends StatefulWidget {
  @override
  _CcAggiungiSquadreState createState() => _CcAggiungiSquadreState();
}

class _CcAggiungiSquadreState extends State<CcAggiungiSquadre> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String placeHolder = 'Logo squadra';
  PlatformFile? file;

  Future<String?> _uploadFileToFirebase(PlatformFile file) async {
    if (file.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Percorso del file non disponibile'),
        ),
      );
      return null;
    }

    try {
      final bytes = File(file.path!).readAsBytesSync();
      final storageRef =
          FirebaseStorage.instance.ref().child('logo/${file.name}');
      final uploadTask = storageRef.putData(bytes);
      final snapshot = await uploadTask.whenComplete(() {});

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante il caricamento del file'),
        ),
      );
      return null;
    }
  }

  void _showAddEditDialog({
    String? club,
    Map<String, dynamic>? squadra,
    bool isEdit = false,
    bool isAddingClub = false,
    bool isEditingClub = false,
  }) {
    final TextEditingController clubController =
        TextEditingController(text: club);
    final TextEditingController squadraController =
        TextEditingController(text: squadra?['squadra']);
    String? logoUrl = squadra?['logo'];

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
                Column(
                  children: [
                    TextField(
                      controller: squadraController,
                      decoration: const InputDecoration(labelText: 'Nome Squadra'),
                    ),
                    const SizedBox(height: 15),
                    FormField<PlatformFile>(
                      validator: (value) {
                        if (file == null && logoUrl == null) {
                          return 'Seleziona un file';
                        }
                        return null;
                      },
                      builder: (formFieldState) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                textStyle: const TextStyle(fontSize: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 5,
                              ),
                              onPressed: () async {
                                FilePickerResult? result = await FilePicker.platform.pickFiles();
                                if (result != null) {
                                  setState(() {
                                    file = result.files.first;
                                    placeHolder = file!.name;
                                  });
                                  formFieldState.didChange(file);
                                }
                              },
                              child: Text(
                                logoUrl=='' || logoUrl==null ? placeHolder : 'Cambia logo',
                                style: const TextStyle(fontSize: 16.0),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (formFieldState.hasError)
                              Text(
                                formFieldState.errorText!,
                                style: TextStyle(color: Theme.of(context).primaryColor),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                )
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

                if (isAddingClub && newClubName.isNotEmpty && isEditingClub == false) {
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
                    List<Map<String, dynamic>> squadre =
                        List<Map<String, dynamic>>.from(docSnapshot['squadre']);
                    bool squadraExists = squadre.any((s) => s['squadra'] == squadraName && s['squadra'] != squadra?['squadra']);
                    if (squadraExists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La squadra esiste già')),
                      );
                    } else {
                      if (isEdit && squadra != null) {
                        int index = squadre.indexWhere((s) => s['squadra'] == squadra['squadra']);
                        if (index != -1) {
                          squadre[index] = {
                            'squadra': squadraName,
                            'logo': file != null ? await _uploadFileToFirebase(file!) : '',
                          };
                        }
                      } else {
                        squadre.add({
                          'squadra': squadraName,
                          'logo': file != null ? await _uploadFileToFirebase(file!) : '',
                        });
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

                  if (oldDocSnapshot.exists && club != newClubName) {
                    List<Map<String, dynamic>> squadre =
                        List<Map<String, dynamic>>.from(oldDocSnapshot['squadre']);
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

  void _showDeleteDialog({required String club, Map<String, dynamic>? squadra}) {
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
                    List<Map<String, dynamic>> squadre = List<Map<String, dynamic>>.from(docSnapshot['squadre']);
                    squadre.removeWhere((s) => s['squadra'] == squadra['squadra'] && s['logo'] == squadra['logo']);
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
              final squadre = List<Map<String, dynamic>>.from(club['squadre']);

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  shape: Border.all(color: Colors.transparent),
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
                      title: Text(squadra['squadra']?? ''),
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
