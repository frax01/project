import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ccNuovoProgramma.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CCProgrammaCompleto extends StatefulWidget {
  const CCProgrammaCompleto({super.key});

  @override
  State<CCProgrammaCompleto> createState() => _CCProgrammaCompletoState();
}

class _CCProgrammaCompletoState extends State<CCProgrammaCompleto> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programma completo'),
      ),
      body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ccProgramma')
                  .snapshots(),
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
                    List<QueryDocumentSnapshot> programmiPerData =
                        groupedProgrammi[data]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 12, 16, 6),
                          child: Text(
                            data == '23/04/2025'
                            ? 'Mercoledì 23'
                            : data == '24/04/2025'
                                ? 'Giovedì 24'
                                : data == '25/04/2025'
                                    ? 'Venerdì 25'
                                    : data == '26/04/2025'
                                        ? 'Sabato 26'
                                        : 'Domenica 27',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ),
                        ...programmiPerData.map((programma) {
                          return Card(
                            margin:
                                const EdgeInsets.fromLTRB(12.0, 0, 12.0, 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 5,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: ExpansionTile(
                                shape: Border.all(color: Colors.transparent),
                                collapsedIconColor: Colors.black,
                                iconColor: Colors.black,
                                title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (programma['categoria'] == 'pasto')
                                        Row(children: [
                                          Image.asset(
                                            'images/spaghetti.png',
                                            width: 30,
                                            height: 30,
                                          ),
                                          const SizedBox(width: 8),
                                        ]),
                                      if (programma['categoria'] == 'partita')
                                        Row(children: [
                                          Image.asset(
                                            'images/calcio.png',
                                            width: 30,
                                            height: 30,
                                          ),
                                          const SizedBox(width: 8),
                                        ]),
                                      if (programma['categoria'] == 'show')
                                        Row(children: [
                                          Image.asset(
                                            'images/show.png',
                                            width: 30,
                                            height: 30,
                                          ),
                                          const SizedBox(width: 8),
                                        ]),
                                      if (programma['categoria'] == 'altro')
                                        Row(children: [
                                          Image.asset(
                                            'images/fuoco.png',
                                            width: 30,
                                            height: 30,
                                          ),
                                          const SizedBox(width: 8),
                                        ]),
                                      Expanded(
                                        child: AutoSizeText(
                                          '${programma['orario']} ${programma['titolo']}',
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          minFontSize: 19,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CCNuovoProgramma(
                                                  programmaId: programma.id,
                                                  data: programma['data'],
                                                  orario: programma['orario'],
                                                  titolo: programma['titolo'],
                                                  squadre: programma['squadre'],
                                                  incarico:
                                                      programma['incarico'],
                                                  altro: programma['altro'],
                                                  codice: programma['codice'],
                                                  categoria:
                                                      programma['categoria'],
                                                ),
                                              ),
                                            );
                                          },
                                          icon:
                                              const Icon(Icons.edit, size: 20)),
                                    ]),
                                children: [
                                  programma['squadre'].isNotEmpty ||
                                          programma['incarico'].isNotEmpty ||
                                          programma['altro'] != ''
                                      ? Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16.0, 0, 16.0, 8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              programma['squadre'].isNotEmpty
                                                  ? Text(
                                                      (programma['squadre']
                                                              as List<dynamic>)
                                                          .join(', '),
                                                      style: const TextStyle(
                                                          fontSize: 18),
                                                    )
                                                  : Container(),
                                              programma['incarico'].isNotEmpty
                                                  ? const Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        SizedBox(height: 8),
                                                        Text(
                                                          "Incarico",
                                                          style: TextStyle(
                                                            fontSize: 19,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Container(),
                                              programma['incarico'].isNotEmpty
                                                  ? Text(
                                                      (programma['incarico']
                                                              as List<dynamic>)
                                                          .join(', '),
                                                      style: const TextStyle(
                                                          fontSize: 18),
                                                    )
                                                  : Container(),
                                              programma['altro'] != ''
                                                  ? const Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        SizedBox(height: 8),
                                                        Text(
                                                          "Info",
                                                          style: TextStyle(
                                                            fontSize: 19,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Container(),
                                              programma['altro'] != ''
                                                  ? Text(
                                                      programma['altro'],
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    )
                                                  : Container(),
                                            ],
                                          ),
                                        )
                                      : const Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              16.0, 0, 16.0, 8.0),
                                          child: Text("Nessuna informazione",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontStyle: FontStyle.italic)))
                                ],
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
    );
  }
}
