import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ccNuovoProgramma.dart';

class CCProgramma extends StatefulWidget {
  const CCProgramma({super.key});

  @override
  State<CCProgramma> createState() => _CCProgrammaState();
}

class _CCProgrammaState extends State<CCProgramma> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ccProgramma').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Errore: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nessun programma trovato'));
                }

                final programmi = snapshot.data!.docs;
                programmi.sort((a, b) {
                  int dateComparison = a['data'].compareTo(b['data']);
                  if (dateComparison != 0) return dateComparison;
                  return a['orario'].compareTo(b['orario']);
                });

                Map<String, List<QueryDocumentSnapshot>> groupedProgrammi = {};
                for (var programma in programmi) {
                  String data = programma['data'];
                  if (!groupedProgrammi.containsKey(data)) {
                    groupedProgrammi[data] = [];
                  }
                  groupedProgrammi[data]!.add(programma);
                }

                return ListView.builder(
                  itemCount: groupedProgrammi.keys.length,
                  itemBuilder: (context, index) {
                    String data = groupedProgrammi.keys.elementAt(index);
                    List<QueryDocumentSnapshot> programmiPerData = groupedProgrammi[data]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            data,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...programmiPerData.map((programma) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CCNuovoProgramma(
                                    programmaId: programma.id,
                                    data: programma['data'],
                                    orario: programma['orario'],
                                    titolo: programma['titolo'],
                                    squadre: programma['squadre'],
                                    incarico: programma['incarico'],
                                    altro: programma['altro'],
                                    codice: programma['codice'],
                                    categoria: programma['categoria'],
                                  ),
                                ),
                              );
                            },
                            child: AbsorbPointer(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  elevation: 5,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16.0),
                                      title: Column(
                                        children: [
                                          Text(programma['titolo'], style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 3),
                                          programma['squadre'].isNotEmpty
                                              ? Text((programma['squadre'] as List<dynamic>).join(', '), style: const TextStyle(fontSize: 18))
                                              : Container(),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          programma['incarico'].isNotEmpty
                                              ? const Column(children: [SizedBox(height: 8), Text("Incarico", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))])
                                              : Container(),
                                          programma['incarico'].isNotEmpty
                                              ? Text((programma['incarico'] as List<dynamic>).join(', '), style: const TextStyle(fontSize: 18))
                                              : Container(),
                                          programma['altro'] != ''
                                              ? const Column(children: [SizedBox(height: 8), Text("Info", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))])
                                              : Container(),
                                          programma['altro'] != ''
                                              ? Text(programma['altro'], style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic))
                                              : Container(),
                                        ],
                                      ),
                                      leading: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(programma['orario'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CCNuovoProgramma()),
          );
        },
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}