import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'codeGenerator.dart';

class AcceptancePage extends StatefulWidget {
  const AcceptancePage({super.key, required this.title});

  final String title;

  @override
  _AcceptancePageState createState() => _AcceptancePageState();
}

class _AcceptancePageState extends State<AcceptancePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 130, 16, 8),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const UserList(),
    );
  }
}

ListView _buildList(AsyncSnapshot<QuerySnapshot> snapshot) {
  return ListView.separated(
    itemCount: snapshot.data!.docs.length,
    itemBuilder: (context, index) {
      var userData = snapshot.data!.docs[index];
      var userEmail = userData['email'];
      return ListTile(
        title: Text(userData['name'] + ' ' + userData['surname']),
        subtitle: Text(
            'Email: $userEmail\nCreated: ${userData['created_time'].toDate()}'),
        onTap: () {
          showModalBottomSheet<void>(
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
        isThreeLine: true,
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
          return const Center(
            child: Text('There are no new users to accept.'),
          );
        }
        return Column(
          children: [
            const SizedBox(height: 16.0),
            Text(
              'There are ${snapshot.data!.docs.length} new users to accept.',
              style:
                  const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
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
