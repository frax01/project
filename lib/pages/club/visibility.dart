import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VisibilitySelectionPage extends StatefulWidget {
  const VisibilitySelectionPage({super.key, required this.visibility});

  final Map visibility;

  @override
  _VisibilitySelectionPageState createState() => _VisibilitySelectionPageState();
}

class _VisibilitySelectionPageState extends State<VisibilitySelectionPage> {
  Map<String, bool> _selectedUsers = {};
  bool _selectAll = false;
  Map<String, List<Map<String, String>>> _usersByRole = {};
  bool _isSelectedUsersInitialized = false;

  Future<Map<String, List<Map<String, String>>>> _loadUsers() async {
    final roles = ['Tutor', 'Ragazzo', 'Genitore'];
    final querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('role', whereIn: roles)
        .where('club', isEqualTo: 'Tiber Club')
        .get();

    final usersByRole = <String, List<Map<String, String>>>{};
    for (var role in roles) {
      usersByRole[role] = [];
    }
    for (var doc in querySnapshot.docs) {
      final user = {
        'email': doc['email'] as String,
        'name': doc['name'] as String,
        'surname': doc['surname'] as String,
      };
      final role = doc['role'] as String;
      if (usersByRole.containsKey(role)) {
        usersByRole[role]!.add(user);
      }
    }

    // Inizializza _selectedUsers con i tutor
    if (!_isSelectedUsersInitialized) {
      final emails = usersByRole['Tutor']!.map((tutor) => tutor['email']!).toList();
      List<String> tutorEmails = _selectedUsers.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      //for (Map<String, bool> elem in _selectedUsers) {
      //
      //}
      //final emails = _selectedUsers!.map((tutor) => tutor['email']!).toList();
      print("emails: ${widget.visibility}");
      print("emails: $emails");
      print("tutor: $tutorEmails");
      setState(() {
        for (var email in tutorEmails) {
          widget.visibility[email] = true;
        }
        _isSelectedUsersInitialized = true;
      });
    }

    return usersByRole;
  }

  void _updateSelectedUsers(Map<String, List<Map<String, String>>> usersByRole) {
    final allUsers = usersByRole.values.expand((list) => list).toList();
    setState(() {
      _selectedUsers = {
        for (var user in allUsers) user['email']!: _selectAll,
      };
    });
  }

  Widget _buildRoleSection(String role, List<Map<String, String>> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(role, style: const TextStyle(fontSize: 18)),
        ),
        ...users.map((user) {
          return CheckboxListTile(
            title: Text('${user['name']} ${user['surname']}'),
            value: _selectedUsers[user['email']] ?? false,
            onChanged: (bool? value) {
              setState(() {
                _selectedUsers[user['email']!] = value!;
                print("sele: $_selectedUsers");
                if (!value) {
                  _selectAll = false;
                }
              });
            },
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visibilità'),
      ),
      body: FutureBuilder<Map<String, List<Map<String, String>>>>(
        future: _loadUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nessun utente trovato.'));
          } else {
            final usersByRole = snapshot.data!;
            return Column(
              children: [
                ListTile(
                  title: const Text('Seleziona tutti'),
                  trailing: Checkbox(
                    value: _selectAll,
                    onChanged: (bool? value) {
                      setState(() {
                        _selectAll = value!;
                        _updateSelectedUsers(usersByRole);
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildRoleSection('Tutor', usersByRole['Tutor'] ?? []),
                      _buildRoleSection('Ragazzo', usersByRole['Ragazzo'] ?? []),
                      _buildRoleSection('Genitore', usersByRole['Genitore'] ?? []),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedEmails = _selectedUsers;
                          //.entries
                          //.where((entry) => entry.value)
                          //.map((entry) => entry.key)
                          //.toList();
                      Navigator.pop(context, selectedEmails);
                    },
                    child: const Text('Conferma'),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
