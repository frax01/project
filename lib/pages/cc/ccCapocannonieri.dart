import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CCCapocannonieri extends StatefulWidget {
  const CCCapocannonieri({super.key});

  @override
  State<CCCapocannonieri> createState() => _CCCapocannonieriState();
}

class _CCCapocannonieriState extends State<CCCapocannonieri> {
  Stream<Map<String, int>> _getMarcatori() async* {
    final collections = [
      'ccPartiteGironi',
      'ccPartiteOttavi',
      'ccPartiteQuarti',
      'ccPartiteSemifinali',
      'ccPartiteFinali'
    ];

    Map<String, int> marcatori = {};

    for (var collection in collections) {
      final querySnapshot = await FirebaseFirestore.instance.collection(collection).get();
      for (var doc in querySnapshot.docs) {
        List<dynamic> marcatoriList = doc['marcatori'] ?? [];
        for (var marcatore in marcatoriList) {
          String nome = marcatore['nome'];
          if (marcatori.containsKey(nome)) {
            marcatori[nome] = marcatori[nome]! + 1;
          } else {
            marcatori[nome] = 1;
          }
        }
      }
    }

    yield marcatori;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Map<String, int>>(
        stream: _getMarcatori(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nessun marcatore trovato'));
          }

          final marcatori = snapshot.data!;
          final sortedMarcatori = marcatori.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView.builder(
            itemCount: sortedMarcatori.length,
            itemBuilder: (context, index) {
              final marcatore = sortedMarcatori[index];
              return Card(
                child: ListTile(
                  title: Text(marcatore.key),
                  trailing: Text('${marcatore.value} gol'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}