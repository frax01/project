import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CcGestioneArbitri extends StatefulWidget {
  const CcGestioneArbitri({super.key});

  @override
  State<CcGestioneArbitri> createState() => _CcGestioneArbitriState();
}

class _CcGestioneArbitriState extends State<CcGestioneArbitri> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Arbitri/Refertisti'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ccStaff').orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }

          final staffDocs = snapshot.data?.docs ?? [];

          if (staffDocs.isEmpty) {
            return const Center(child: Text('Nessun membro dello staff trovato.'));
          }

          return ListView.builder(
            itemCount: staffDocs.length,
            itemBuilder: (context, index) {
              final doc = staffDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final nome = data['nome'] ?? 'Sconosciuto';
              final isArbitro = data['isArbitro'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: SwitchListTile(
                  title: Text(nome, style: const TextStyle(fontSize: 17)),
                  subtitle: const Text('Abilitato per le partite'),
                  value: isArbitro,
                  activeColor: const Color.fromARGB(255, 37, 201, 43),
                  onChanged: (bool value) async {
                    await FirebaseFirestore.instance
                        .collection('ccStaff')
                        .doc(doc.id)
                        .set({'isArbitro': value}, SetOptions(merge: true));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
