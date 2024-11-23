import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VisibilitySelectionPage extends StatefulWidget {
  const VisibilitySelectionPage({super.key, this.visibility, required this.club});

  final Map<String, bool>? visibility;
  final String club;

  @override
  _VisibilitySelectionPageState createState() => _VisibilitySelectionPageState();
}

class _VisibilitySelectionPageState extends State<VisibilitySelectionPage> {
  Map<String, bool> _selectedUsers = {};
  bool _selectAll = false;
  Map<String, List<Map<String, String>>> _usersByRole = {};
  bool _isLoading = true;
  int number = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<Map<String, bool>> _selectAllTutor() async {
    final roles = ['Tutor', 'Ragazzo', 'Genitore'];
    final querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('role', whereIn: roles)
        .where('club', isEqualTo: widget.club)
        .get();

    Map<String, bool> select = {};

    for (var doc in querySnapshot.docs) {
      final email = doc['email'] as String;
      select[email]=true;
    }
    return select;
  }

  Future<void> _loadUsers() async {
    try {
      final roles = ['Tutor', 'Ragazzo', 'Genitore'];
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('role', whereIn: roles)
          .where('club', isEqualTo: widget.club)
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
        number++;
      }

      setState(() {
        _usersByRole = usersByRole;
        _initializeSelectedUsers();
        _isLoading = false;
        _selectAll = _selectedUsers.length == number ? true : false;
      });
    } catch (e) {
      print('Errore durante il caricamento degli utenti: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeSelectedUsers() {
    if(widget.visibility==null || widget.visibility!.isEmpty) {
      _selectedUsers = {
        for (var role in _usersByRole.keys)
          if (role == 'Tutor')
            for (var user in _usersByRole[role]!) user['email']!: true
      };
    } else {
      _selectedUsers = widget.visibility ?? {};
    }
  }

  Widget _buildRoleSection(String role) {
    if (!_usersByRole.containsKey(role)) {
      return const SizedBox.shrink();
    }
    final users = _usersByRole[role]!;

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
                if (value == false) {
                  _selectedUsers.remove(user['email']);
                } else {
                  _selectedUsers[user['email']!] = true;
                }
                if (value == false) {
                  _selectAll = false;
                }
              });
            },
          );
        }),
      ],
    );
  }

  void _handleSelectAll(bool? value) async {
    if (value == true) {
      final allTutors = await _selectAllTutor();
      setState(() {
        _selectAll = true;
        _selectedUsers = allTutors;
      });
    } else {
      setState(() {
        _selectAll = false;
        _selectedUsers.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visibilità'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          CheckboxListTile(
            title: const Text('Seleziona tutti'),
            value: _selectAll,
            onChanged: _handleSelectAll,
          ),
          Expanded(
            child: ListView(
              children: [
                _buildRoleSection('Tutor'),
                _buildRoleSection('Ragazzo'),
                _buildRoleSection('Genitore'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                final selectedEmails = _selectedUsers.entries
                    .where((entry) => entry.value)
                    .map((entry) => entry.key)
                    .toList();
                Navigator.pop(context, selectedEmails);
              },
              child: const Text('Conferma'),
            ),
          ),
        ],
      ),
    );
  }
}