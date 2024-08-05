import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Status extends StatefulWidget {
  const Status({super.key, required this.club});

  final String club;

  @override
  _StatusState createState() => _StatusState();
}

class _StatusState extends State<Status> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permessi utente'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('user')
            .where('club', isEqualTo: widget.club)
            .where('role', whereIn: ['Tutor', 'Ragazzo'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data!.docs;

          users.sort((a, b) {
            final firstNameA = a['name'].toLowerCase();
            final firstNameB = b['name'].toLowerCase();
            return firstNameA.compareTo(firstNameB);
          });

          List<ListTile> userTiles = [];
          for (var user in users) {
            final firstName = user['name'];
            final lastName = user['surname'];
            final status = user['status'];
            final userId = user.id;

            final userTile = ListTile(
              title: Text('$firstName $lastName', style: const TextStyle(fontSize: 20.0),),
              subtitle: Text(status == 'User' ? 'Utente' : 'Admin', style: const TextStyle(fontSize: 15.0),),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              onTap: () => _updateStatus(context, userId, status),
            );

            userTiles.add(userTile);
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: ListView(
              children: ListTile.divideTiles(
                context: context,
                tiles: userTiles,
              ).toList(),
            ),
          );
        },
      ),
    );
  }

  void _updateStatus(BuildContext context, String userId, String currentStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma'),
          content: currentStatus=='User'?
            const Text('Cambiare lo status da Utente a Admin?', style: const TextStyle(fontSize: 20.0))
            : const Text('Cambiare lo status da Admin a Utente?', style: const TextStyle(fontSize: 20.0)),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Conferma'),
              onPressed: () async {
                final newStatus = currentStatus == 'User' ? 'Admin' : 'User';
                await _firestore.collection('user').doc(userId).update({
                  'status': newStatus,
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
