import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ccNuovoGirone.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ccCreazioneGironi extends StatefulWidget {
  @override
  _ccCreazioneGironiState createState() => _ccCreazioneGironiState();
}

class _ccCreazioneGironiState extends State<ccCreazioneGironi> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Widget> _buildSquadreList(List<dynamic> squadre) {
    return List<Widget>.generate(squadre.length, (index) {
      return Row(
        children: [
          Text(
            '${index + 1}. ',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: AutoSizeText(
              squadre[index],
              style: const TextStyle(
                fontSize: 21,
              ),
              minFontSize: 21,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          )
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gironi'),
      ),
      body: StreamBuilder(
        stream: _firestore.collection('ccGironi').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nessun girone presente', style: TextStyle(fontSize: 20),));
          }
          return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: snapshot.data!.docs.map((doc) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black54),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      title: Center(
                          child: Text('Girone ${doc['nome']}',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold))),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          ..._buildSquadreList(doc['squadre']),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(context, doc.id),
                      ),
                    ),
                  );
                }).toList(),
              ));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => ccNuovoGirone())),
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questo girone?'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              _showLoadingDialog();

              QuerySnapshot querySnapshot = await _firestore
                  .collection('ccPartiteGironi')
                  .where('girone', isEqualTo: docId)
                  .get();

              for (var doc in querySnapshot.docs) {
                await doc.reference.delete();
              }

              await _firestore.collection('ccGironi').doc(docId).delete();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
