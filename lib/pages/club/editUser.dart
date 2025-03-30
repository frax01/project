import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';

class EditUser extends StatefulWidget {
  const EditUser(
      {super.key, required this.club, required this.id, required this.name});

  final String club;
  final String id;
  final String name;

  @override
  _EditUserState createState() => _EditUserState();
}

class _EditUserState extends State<EditUser> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedRole = '';
  String _selectedStatus = '';
  String selectedClubClass = "";
  List _selectedClass = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Modifica utente'),
          centerTitle: true,
        ),
        body: StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('user').doc(widget.id).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>?;

              final List<String> roleOptions = ["Ragazzo", "Genitore", "Tutor"];
              final List<String> statusOptions = ["User", "Admin"];

              final role = userData!['role'];
              final status = userData['status'];
              final classes = userData['club_class'];

              final List<String> tiberClubClassOptions = [
                '4° elem',
                '5° elem',
                '1° media',
                '2° media',
                '3° media',
                "1° liceo",
                "2° liceo",
                "3° liceo",
                "4° liceo",
                "5° liceo",
              ];
              final List<String> deltaClubClassOptions = [
                "1° liceo",
                "2° liceo",
                "3° liceo",
                "4° liceo",
                "5° liceo",
              ];
              final List<String> rampaClubClassOptions = [
                "1° liceo",
                "2° liceo",
                "3° liceo",
                "4° liceo",
                "5° liceo",
              ];

              if (_selectedRole.isEmpty) {
                _selectedRole = role;
              }
              if (_selectedStatus.isEmpty) {
                _selectedStatus = status;
              }
              if (_selectedClass.isEmpty) {
                _selectedClass = classes;
              }

              int getClassOrder(String className) {
                if (className.contains("media")) {
                  return int.parse(className[0]);
                } else {
                  return int.parse(className[0]) + 10;
                }
              }

              Widget buildDropdownClasse(String label, List<String> options,
                  void Function(String?) onChanged) {
                return 
                    MultiSelectDialogField(
                      title: const Text('Seleziona le classi'),
                      selectedColor: Theme.of(context).primaryColor,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      items: options
                          .map((option) =>
                              MultiSelectItem<String>(option, option))
                          .toList(),
                      buttonText: const Text('Classe', style: TextStyle(fontSize: 20),),
                      confirmText: const Text('Ok'),
                      cancelText: const Text('Annulla'),
                      initialValue: _selectedClass,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserire almeno una classe';
                        }
                        return null;
                      },
                      onConfirm: (value) {
                        setState(() {
                          _selectedClass = List<String>.from(value);
                          _selectedClass.sort((a, b) =>
                              getClassOrder(a).compareTo(getClassOrder(b)));
                        });
                      },
                );
              }

              Future<void> updateUser() async {
                try {
                  await _firestore.collection('user').doc(widget.id).update({
                    'role': _selectedRole,
                    'status': _selectedStatus,
                    'club_class': _selectedClass,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Dati aggiornati con successo')),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')),
                  );
                }
              }

              void showConfirmationDialog() {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Conferma aggiornamento'),
                      content:
                          const Text('Sei sicuro di voler aggiornare i dati?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Annulla'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        ElevatedButton(
                          child: const Text('Conferma'),
                          onPressed: () {
                            updateUser();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              }

              Future<void> deleteUser() async {
                try {
                  await _firestore.collection('user').doc(widget.id).delete();
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Errore durante l\'eliminazione: $e')),
                  );
                }
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person, size: 30,),
                      title: const Text('Nome'),
                      subtitle: AutoSizeText(
                        widget.name,
                        style: const TextStyle(fontSize: 25.0),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 20,),
                    ExpansionTile(
                      title: Text(_selectedRole, style: const TextStyle(fontSize: 20),),
                      leading: const Icon(Icons.admin_panel_settings, size: 30,),
                      children: roleOptions.map<Widget>((elem) {
                        return ListTile(
                          title: Text(elem, style: const TextStyle(fontSize: 18)),
                          leading: Checkbox(
                            value: _selectedRole == elem,
                            onChanged: (bool? value) {
                              if (value == true) {
                                setState(() {
                                  _selectedRole = elem;
                                });
                              }
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _selectedRole = elem;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ExpansionTile(
                      title: Text(_selectedStatus, style: const TextStyle(fontSize: 20),),
                      leading: const Icon(Icons.settings, size: 30,),
                      children: statusOptions.map<Widget>((elem) {
                        return ListTile(
                          title: Text(elem, style: const TextStyle(fontSize: 18),),
                          leading: Checkbox(
                            value: _selectedStatus == elem,
                            onChanged: (bool? value) {
                              if (value == true) {
                                setState(() {
                                  _selectedStatus = elem;
                                });
                              }
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _selectedStatus = elem;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: buildDropdownClasse(
                          "Classe",
                          widget.club == 'Tiber Club'
                            ? tiberClubClassOptions
                            : widget.club == 'Rmapa Club'
                            ? rampaClubClassOptions
                            : deltaClubClassOptions, (value) {
                              setState(() {
                                selectedClubClass = value.toString();
                              });
                            }
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Conferma Eliminazione'),
                                  content: const Text(
                                      'Sei sicuro di voler eliminare questo utente?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Annulla'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Elimina utente'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (shouldDelete == true) {
                              await deleteUser();
                            }
                          },
                          child: const Text('Elimina utente'),
                        ),
                        ElevatedButton(
                          onPressed: showConfirmationDialog,
                          child: const Text('Conferma'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }));
  }
}
