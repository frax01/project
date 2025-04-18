import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'codeGenerator.dart';

class AcceptancePage extends StatefulWidget {
  const AcceptancePage({super.key, required this.club});

  final String club;

  @override
  _AcceptancePageState createState() => _AcceptancePageState();
}

class _AcceptancePageState extends State<AcceptancePage> {
  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Accetta utenti'),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: UserList(club: widget.club),
        ));
  }
}

ListView _buildList(AsyncSnapshot<QuerySnapshot> snapshot, String club) {
  return ListView.separated(
    itemCount: snapshot.data!.docs.length,
    itemBuilder: (context, index) {
      var userData = snapshot.data!.docs[index];
      var userEmail = userData['email'];
      var userId = userData.id;
      return ListTile(
        title: Text(userData['name'] + ' ' + userData['surname'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(userEmail),
        onTap: () {
          showModalBottomSheet<void>(
            useSafeArea: true,
            isScrollControlled: true,
            showDragHandle: true,
            context: context,
            builder: (BuildContext context) {
              return UserDetailsPage(
                title: 'User Details',
                userEmail: userEmail,
                userName: userData['name'] + ' ' + userData['surname'],
                userId: userId,
                club: club,
              );
            },
          );
        },
      );
    },
    separatorBuilder: (BuildContext context, int index) {
      return const Divider(
        indent: 10,
        endIndent: 10,
      );
    },
  );
}

class UserList extends StatelessWidget {
  const UserList({super.key, required this.club});

  final String club;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user')
          .where('club', isEqualTo: club)
          .where('role', isEqualTo: '')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Non ci sono nuovi utenti da accettare',
              style: TextStyle(fontSize: 20.0, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          );
        }
        return Column(
          children: [
            const SizedBox(height: 16.0),
            if (snapshot.data!.docs.isEmpty)
              const Text(
                'Non ci sono nuovi utenti da accettare',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            if (snapshot.data!.docs.length == 1)
              const Text(
                '1 nuovo utente da accettare',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            if (snapshot.data!.docs.length > 1)
              Text(
                '${snapshot.data!.docs.length} nuovi utenti da accettare',
                style: const TextStyle(
                    fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16.0),
            Expanded(
              child: _buildList(snapshot, club),
            ),
          ],
        );
      },
    );
  }
}
