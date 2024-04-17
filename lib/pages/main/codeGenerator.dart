import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/functions/notificationFunctions.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage(
      {super.key,
      required this.title,
      required this.userEmail,
      required this.userName});

  final String userEmail;
  final String title;
  final String userName;

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  String selectedRole = "";
  String selectedClubClass = "";
  String selectedStatus = "";
  List<String> classList = [];

  final List<String> roleOptions = ["", "Ragazzo", "Genitore", "Tutor"];
  final List<String> clubClassOptions = [
    '1° media',
    '2° media',
    '3° media',
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
                  buildDropdownClasse("Classe", clubClassOptions, (value) {
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
                        onPressed: () {
                          return Navigator.pop(context);
                        },
                        child: const Text('Indietro'),
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a role')));
        return;
      }
      if (selectedStatus == "") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a status')));
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
      List token = querySnapshot.docs.first["token"];
      sendNotification(token, 'Sei stato accettato!', 'Fai di nuovo Login', 'accepted');
      Navigator.pop(context);
    } catch (e) {
      print('Error updating user details: $e');
    }
  }
}
