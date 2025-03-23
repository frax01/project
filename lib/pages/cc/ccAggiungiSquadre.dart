import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';

class CcAggiungiSquadre extends StatefulWidget {
  @override
  _CcAggiungiSquadreState createState() => _CcAggiungiSquadreState();
}

class _CcAggiungiSquadreState extends State<CcAggiungiSquadre> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String placeHolder = 'Aggiungi logo';
  PlatformFile? fileF;

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
  PlatformFile? localFileF = fileF;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit
                ? (isAddingClub ? 'Modifica Club' : 'Modifica Squadra')
                : (isAddingClub ? 'Aggiungi Club' : 'Aggiungi Squadra')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAddingClub || (!isEdit && squadra == null && isAddingClub))
                  TextField(
                    controller: clubController,
                    decoration: const InputDecoration(labelText: 'Nome Club'),
                  ),
                if (!isAddingClub)
                  Column(
                    children: [
                      TextField(
                        controller: squadraController,
                        decoration:
                            const InputDecoration(labelText: 'Nome Squadra'),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        onPressed: () async {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles();
                          if (result != null) {
                            setDialogState(() {
                              localFileF = result.files.first;
                              placeHolder = localFileF!.name;
                              print("File selezionato: $localFileF");
                            });
                          }
                        },
                        child: Text(
                          logoUrl == '' || logoUrl == null
                              ? placeHolder
                              : 'Cambia logo',
                          style: const TextStyle(fontSize: 16.0),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (localFileF == null && logoUrl == null)
                        const Text(
                          'Seleziona un file',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  )
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () async {
                  _showLoadingDialog();

                  final String newClubName = clubController.text;
                  final String squadraName = squadraController.text;

                  if (isAddingClub &&
                      newClubName.isNotEmpty &&
                      isEditingClub == false) {
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
                  } else if (newClubName.isNotEmpty &&
                      squadraName.isNotEmpty) {
                    final DocumentReference docRef =
                        _firestore.collection('ccSquadre').doc(newClubName);
                    final DocumentSnapshot docSnapshot = await docRef.get();

                    if (docSnapshot.exists) {
                      List<Map<String, dynamic>> squadre =
                          List<Map<String, dynamic>>.from(
                              docSnapshot['squadre']);
                      bool squadraExists = squadre.any((s) =>
                          s['squadra'] == squadraName &&
                          s['squadra'] != squadra?['squadra']);
                      if (squadraExists) {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('La squadra esiste già')),
                        );
                      } else {
                        if (isEdit && squadra != null) {
                          int index = squadre.indexWhere(
                              (s) => s['squadra'] == squadra['squadra']);
                          if (index != -1) {
                            squadre[index] = {
                              'squadra': squadraName,
                              'logo': localFileF != null
                                  ? await _uploadFileToFirebase(localFileF!)
                                  : '',
                            };
                          }
                        } else {
                          squadre.add({
                            'squadra': squadraName,
                            'logo': localFileF != null
                                ? await _uploadFileToFirebase(localFileF!)
                                : '',
                          });
                        }
                        await docRef.update({'squadre': squadre});
                      }
                    }
                  }

                  setState(() {
                    fileF = null;
                    placeHolder = 'Aggiungi logo';
                  });

                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(isEdit ? 'Modifica' : 'Salva'),
              ),
            ],
          );
        },
      );
    },
  );
}

  void _showDeleteDialog(
      {required String club, Map<String, dynamic>? squadra}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Conferma Eliminazione'),
          content: const Text('Sei sicuro di voler eliminare?'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                _showLoadingDialog();
                if (squadra != null) {
                  final DocumentReference docRef =
                      _firestore.collection('ccSquadre').doc(club);
                  final DocumentSnapshot docSnapshot = await docRef.get();

                  if (docSnapshot.exists) {
                    List<Map<String, dynamic>> squadre =
                        List<Map<String, dynamic>>.from(docSnapshot['squadre']);
                    squadre.removeWhere((s) =>
                        s['squadra'] == squadra['squadra'] &&
                        s['logo'] == squadra['logo']);
                    await docRef.update({'squadre': squadre});
                  }
                } else {
                  await _firestore.collection('ccSquadre').doc(club).delete();
                }

                Navigator.of(context).pop();
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
        title: const Text('Gestione squadre'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF00296B),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('ccSquadre').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nessun club presente'),
            );
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
                  child: Card(
                    elevation: 5,
                    child: ExpansionTile(
                      shape: Border.all(color: Colors.transparent),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: AutoSizeText(
                              clubName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              minFontSize: 18,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
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
                                onPressed: () =>
                                    _showDeleteDialog(club: clubName),
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
                        return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(children: [
                              const Divider(
                                  height: 8,
                                  thickness: 0.75,
                                  color: Colors.black54),
                              ListTile(
                                leading: squadra['logo'] != null &&
                                        squadra['logo'] != ''
                                    ? Image.network(
                                        squadra['logo'],
                                        width: 40,
                                        height: 40,
                                      )
                                    : const Icon(Icons.sports_soccer),
                                title: AutoSizeText(
                                  squadra['squadra'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                  minFontSize: 16,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ), //Text(squadra['squadra'] ?? ''),
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
                              ),
                            ]));
                      }).toList(),
                    ),
                  ));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(isEdit: false, isAddingClub: true),
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}
