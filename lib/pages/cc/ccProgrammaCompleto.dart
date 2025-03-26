import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ccNuovoProgramma.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CCProgrammaCompleto extends StatefulWidget {
  const CCProgrammaCompleto({super.key, required this.ccRole});

  final String ccRole;

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
        stream:
            FirebaseFirestore.instance.collection('ccProgramma').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nessun programma trovato', style: TextStyle(fontSize: 19, color: Colors.black54)));
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

          Future<List<String>> _getNomiSquadre(List<String> codiciSquadre) async {
            List<String> nomiSquadre = [];
            for (String codice in codiciSquadre) {
              List<String> parts = codice.split(' ');
              String tipoS = parts[0];
              String codiceS = parts[1];
              if (tipoS == 'girone') {
                final querySnapshot = await FirebaseFirestore.instance
                    .collection('ccPartiteGironi')
                    .where('turno', isEqualTo: codiceS)
                    .get();
                if (querySnapshot.docs.isNotEmpty) {
                  for (var doc in querySnapshot.docs) {
                    nomiSquadre.add(doc['casa']);
                    nomiSquadre.add(doc['fuori']);
                  }
                }
              } else {
                tipoS = tipoS[0].toUpperCase() + tipoS.substring(1);
                final querySnapshot = await FirebaseFirestore.instance
                    .collection('ccPartite$tipoS')
                    .where('codice', isEqualTo: codiceS)
                    .get();
                if (querySnapshot.docs.isNotEmpty) {
                  for (var doc in querySnapshot.docs) {
                    if (doc['casa'] != '') nomiSquadre.add(doc['casa']);
                    if (doc['fuori'] != '') nomiSquadre.add(doc['fuori']);
                  }
                }
              }
            }
            return nomiSquadre;
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
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                  ...programmiPerData.map((programma) {
                    return Card(
                      margin: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 16.0),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (programma['categoria'] == 'pasto')
                                  Row(children: [
                                    Image.asset(
                                      'images/spaghetti.png',
                                      width: 25,
                                      height: 25,
                                    ),
                                    const SizedBox(width: 8),
                                  ]),
                                if (programma['categoria'] == 'partita')
                                  Row(children: [
                                    Image.asset(
                                      'images/calcio.png',
                                      width: 25,
                                      height: 25,
                                    ),
                                    const SizedBox(width: 8),
                                  ]),
                                if (programma['categoria'] == 'show')
                                  Row(children: [
                                    Image.asset(
                                      'images/show.png',
                                      width: 25,
                                      height: 25,
                                    ),
                                    const SizedBox(width: 8),
                                  ]),
                                if (programma['categoria'] == 'altro')
                                  Row(children: [
                                    Image.asset(
                                      'images/fuoco.png',
                                      width: 25,
                                      height: 25,
                                    ),
                                    const SizedBox(width: 8),
                                  ]),
                                Expanded(
                                  child: AutoSizeText(
                                    '${programma['orario']} ${programma['titolo']}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    minFontSize: 17,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                widget.ccRole=='staff' ? IconButton(
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
                                            codiceSquadre:
                                                programma['codiceSquadre'],
                                            incarico: programma['incarico'],
                                            codiceIncarico:
                                                programma['codiceIncarico'],
                                            altro: programma['altro'],
                                            categoria: programma['categoria'],
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit, size: 20)) : Container(),
                              ]),
                          children: [
                            programma['squadre'].isNotEmpty ||
                                          programma['codiceSquadre']
                                              .isNotEmpty ||
                                          programma['incarico'].isNotEmpty ||
                                          programma['codiceIncarico']
                                              .isNotEmpty ||
                                          programma['altro'] != ''
                                      ? Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16.0, 0, 16.0, 8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              programma['squadre'].isNotEmpty ||
                                                      programma['codiceSquadre']
                                                          .isNotEmpty
                                                  ? FutureBuilder<List<String>>(
                                                      future: _getNomiSquadre(List<
                                                              String>.from(
                                                          programma[
                                                              'codiceSquadre'])),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return const Center(child:CircularProgressIndicator());
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return Text(
                                                              'Errore: ${snapshot.error}');
                                                        } else {
                                                          List<String> squadre =
                                                              List<String>.from(
                                                                  programma[
                                                                      'squadre']);
                                                          if (snapshot
                                                                  .hasData &&
                                                              snapshot.data!
                                                                  .isNotEmpty) {
                                                            squadre.addAll(
                                                                snapshot.data!);
                                                          }
                                                          return Text(
                                                            squadre.join(', '),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        15),
                                                          );
                                                        }
                                                      },
                                                    )
                                                  : Container(),
                                              programma['incarico']
                                                          .isNotEmpty ||
                                                      programma[
                                                              'codiceIncarico']
                                                          .isNotEmpty
                                                  ? FutureBuilder<List<String>>(
                                                      future: _getNomiSquadre(List<
                                                              String>.from(
                                                          programma[
                                                              'codiceIncarico'])),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return const Center(child: CircularProgressIndicator());
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return Text(
                                                              'Errore: ${snapshot.error}');
                                                        } else {
                                                          List<String> squadre =
                                                              List<String>.from(
                                                                  programma[
                                                                      'incarico']);
                                                          if (snapshot
                                                                  .hasData &&
                                                              snapshot.data!
                                                                  .isNotEmpty) {
                                                            squadre.addAll(
                                                                snapshot.data!);
                                                          }
                                                          return Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              const SizedBox(
                                                                  height: 8),
                                                              const Text(
                                                                "Incarico",
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 17,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              Text(
                                                                squadre
                                                                    .join(', '),
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            15),
                                                              )
                                                            ],
                                                          );
                                                        }
                                                      },
                                                    )
                                                  : Container(),
                                              programma['altro'] != ''
                                                  ? Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const SizedBox(
                                                            height: 8),
                                                        const Text(
                                                          "Info",
                                                          style: TextStyle(
                                                            fontSize: 17,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          programma['altro'],
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 15,
                                                            fontStyle: FontStyle
                                                                .italic,
                                                          ),
                                                        )
                                                      ],
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
                                                  fontSize: 16,
                                                  fontStyle:
                                                      FontStyle.italic))),
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
