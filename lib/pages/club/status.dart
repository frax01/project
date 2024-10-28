import 'package:club/pages/club/editUser.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
        title: const Text('Iscritti'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('user')
            .where('club', isEqualTo: widget.club)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data!.docs;

          List<QueryDocumentSnapshot> tutors = [];
          List<QueryDocumentSnapshot> ragazzi = [];
          List<QueryDocumentSnapshot> genitori = [];

          for (var user in users) {
            final role = user['role'];
            if (role == 'Tutor') {
              tutors.add(user);
            } else if (role == 'Ragazzo') {
              ragazzi.add(user);
            } else if (role == 'Genitore') {
              genitori.add(user);
            }
          }

          tutors.sort((a, b) =>
              a['name'].toLowerCase().compareTo(b['name'].toLowerCase()));
          ragazzi.sort((a, b) =>
              a['name'].toLowerCase().compareTo(b['name'].toLowerCase()));
          genitori.sort((a, b) =>
              a['name'].toLowerCase().compareTo(b['name'].toLowerCase()));

          List<Widget> createUserTiles(List<QueryDocumentSnapshot> users) {
            final tiles = users.map((user) {
              final firstName = user['name'];
              final lastName = user['surname'];
              final status = user['status'] == 'User' ? 'Utente' : 'Admin';
              //final role = user['role'];
              final classes = user['club_class'];
              final userId = user.id;

              return ListTile(
                title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      AutoSizeText(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                        maxLines: 1,
                        minFontSize: 18,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]),
                subtitle: Text('${classes.join(', ')}',
                    style: const TextStyle(fontSize: 15.0)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EditUser(
                            club: widget.club,
                            id: userId,
                            name: '$firstName $lastName'))),
              );
            }).toList();

            return ListTile.divideTiles(
              context: context,
              tiles: tiles,
              color: Colors.grey,
            ).toList();
          }

          int index = createUserTiles(tutors).length +
              createUserTiles(ragazzi).length +
              createUserTiles(genitori).length;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: ListView(
              children: [
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: Text(index==1? "$index utente" : "$index utenti",
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
                const Text('Tutor',
                    style:
                        TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                ...createUserTiles(tutors),
                const SizedBox(height: 20),
                const Text('Ragazzi',
                    style:
                        TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                ...createUserTiles(ragazzi),
                const SizedBox(height: 20),
                const Text('Genitori',
                    style:
                        TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                ...createUserTiles(genitori),
              ],
            ),
          );
        },
      ),
    );
  }
}
