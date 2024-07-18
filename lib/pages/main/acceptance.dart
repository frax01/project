import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ms_undraw/ms_undraw.dart';

import 'codeGenerator.dart';

class AcceptancePage extends StatefulWidget {
  const AcceptancePage({super.key, required this.title});

  final String title;

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
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
      child: const UserList(),
    ));
  }
}

ListView _buildList(AsyncSnapshot<QuerySnapshot> snapshot) {
  return ListView.separated(
    itemCount: snapshot.data!.docs.length,
    itemBuilder: (context, index) {
      var userData = snapshot.data!.docs[index];
      var userEmail = userData['email'];
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
  const UserList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user')
          .where('role', isEqualTo: '')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200.0,
                  child: UnDraw(
                    illustration: UnDrawIllustration.add_friends,
                    placeholder: const SizedBox(
                      height: 200.0,
                      width: 200.0,
                    ),
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Text(
                  'Non ci sono nuovi utenti da accettare',
                  style: TextStyle(fontSize: 20.0, color: Colors.black54),
                ),
              ],
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

            if (snapshot.data!.docs.length==1)
              const Text(
                '1 nuovo utente da accettare',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            if (snapshot.data!.docs.length>1)
              Text(
                '${snapshot.data!.docs.length} nuovi utenti da accettare',
                style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16.0),
            Expanded(
              child: _buildList(snapshot),
            ),
          ],
        );
      },
    );
  }
}
