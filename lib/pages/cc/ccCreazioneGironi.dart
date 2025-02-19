import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ccNuovoGirone.dart';

class ccCreazioneGironi extends StatefulWidget {
  @override
  _ccCreazioneGironiState createState() => _ccCreazioneGironiState();
}

class _ccCreazioneGironiState extends State<ccCreazioneGironi> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestione Gironi'),
      ),
      body: StreamBuilder(
        stream: _firestore.collection('ccGironi').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nessun girone presente'));
          }
          return 
          ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['nome']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(context, doc.id),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => ccNuovoGirone())),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questo girone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              _firestore.collection('ccGironi').doc(docId).delete();
              Navigator.of(context).pop();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
