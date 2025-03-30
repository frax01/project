import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/functions/notificationFunctions.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage(
      {super.key,
      required this.title,
      required this.userEmail,
      required this.userName,
      required this.userId,
      required this.club});

  final String userId;
  final String userEmail;
  final String title;
  final String userName;
  final String club;

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  String selectedRole = "";
  String selectedClubClass = "";
  String selectedStatus = "";
  List<String> classList = [];

  final List<String> roleOptions = ["", "Ragazzo", "Genitore", "Tutor"];
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
  final List<String> statusOptions = ["", "User", "Admin"];

  Future<void> _refresh() async {
    setState(() {});
  }

  Future<void> _deleteUser() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      await firestore.collection('user').doc(widget.userId).delete();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: RefreshIndicator(
      onRefresh: _refresh,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                        fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.userEmail,
                  ),
                  const SizedBox(height: 16.0),
                  buildDropdown("Ruolo", roleOptions, (value) {
                    setState(() {
                      selectedRole = value.toString();
                    });
                  }),
                  buildDropdownClasse(
                      "Classe",
                      widget.club == 'Tiber Club'
                          ? tiberClubClassOptions
                          : widget.club == 'Rampa Club'
                          ? rampaClubClassOptions
                          : deltaClubClassOptions, (value) {
                    setState(() {
                      selectedClubClass = value.toString();
                    });
                  }),
                  buildDropdown("Status", statusOptions, (value) {
                    setState(() {
                      selectedStatus = value.toString();
                    });
                  }),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                            await _deleteUser();
                          }
                        },
                        child: const Text('Rifiuta'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          updateUserDetails();
                        },
                        child: const Text('Accetta'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget buildDropdownClasse(
      String label, List<String> options, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        MultiSelectDialogField(
          title: const Text('Seleziona le classi'),
          selectedColor: Theme.of(context).primaryColor,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          items: options
              .map((option) => MultiSelectItem<String>(option, option))
              .toList(),
          buttonText: const Text('Classe'),
          confirmText: const Text('Ok'),
          cancelText: const Text('Annulla'),
          initialValue: classList,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Inserire almeno una classe';
            }
            return null;
          },
          onConfirm: (value) {
            setState(() {
              classList = value;
            });
          },
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }

  Widget buildDropdown(
      String label, List<String> options, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          isExpanded: true,
          value: label == "Ruolo" ? selectedRole : selectedStatus,
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }

  void updateUserDetails() async {
    try {
      if (selectedRole == "") {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Seleziona un ruolo')));
        return;
      }
      if (selectedStatus == "") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seleziona uno status')));
        return;
      }

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore
          .collection('user')
          .where('email', isEqualTo: widget.userEmail)
          .get();
      String documentId = querySnapshot.docs.first.id;

      await FirebaseFirestore.instance
          .collection('user')
          .doc(documentId)
          .update({
        'role': selectedRole,
        'club_class': classList,
        'status': selectedStatus,
      });
      List tokenList = querySnapshot.docs.first["token"];
      List<String> token = [];
      for (var elem in tokenList) {
        if (elem is String) {
          token.add(elem);
        } else if (elem is Map<String, String>) {
          token.add(elem.values.first);
        }
      }
      sendNotification(
          token, 'Sei stato accettato!', 'Fai di nuovo Login', 'accepted');
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante l\'accettazione dell\'utente'),
        ),
      );
    }
  }
}
