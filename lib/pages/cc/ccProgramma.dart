import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ccNuovoProgramma.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'ccProgrammaCompleto.dart';
import 'pdfView.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CCProgramma extends StatefulWidget {
  const CCProgramma({super.key, required this.ccRole});

  final String ccRole;

  @override
  State<CCProgramma> createState() => _CCProgrammaState();
}

class _CCProgrammaState extends State<CCProgramma> {
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

  Future<void> _openFileOrLink(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }

    try {
      await FlutterWebBrowser.openWebPage(url: url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore nell\'aperatura del link')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _getDocumentsFromStorage() async {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ListResult result = await storage.ref('giornalino/').listAll();

  final List<Map<String, dynamic>> documents = [];
  for (var item in result.items) {
    final String url = await item.getDownloadURL();
    final FullMetadata metadata = await item.getMetadata();
    final DateTime updated = metadata.updated ?? DateTime.now();

    documents.add({'url': url, 'updated': updated});
  }

  // Ordina i documenti in base alla data di aggiornamento
  documents.sort((a, b) => a['updated'].compareTo(b['updated']));

  return documents;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Center(
                  child: Image.asset(
                    'images/champions.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: 25.0,
                  top: 40.0,
                  child: Image.asset(
                    'images/logo_champions_bianco.png',
                    width: 150,
                    height: 150,
                  ),
                ),
                Positioned(
                  right: 12.0,
                  top: 12.0,
                  child: InkWell(
                    onTap: () async {
                      final FirebaseStorage storage = FirebaseStorage.instance;
                      final ref = storage.ref().child('DocumentiCC/IMG-20250414-WA0009.jpg');
                        final url = await ref.getDownloadURL();
                        _openFileOrLink(url);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.map, // Icona della mappa
                        size: 28,
                        color: Color(0xFF00296B),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12.0,
                  top: 65.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerPage(
                            pdfPath: 'images/RegolamentoChampionsClub2025.pdf',//'assets/document.pdf', // Percorso del PDF
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.description, // Icona del regolamento
                        size: 28,
                        color: Color(0xFF00296B),
                      ),
                    ),
                  ),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
          future: _getDocumentsFromStorage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Positioned(
                bottom: 16.0,
                right: 12.0,
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Positioned(
                bottom: 16.0,
                right: 12.0,
                child: Container(),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Positioned(
                bottom: 16.0,
                right: 12.0,
                child: Container(),
              );
            }

            final documents = snapshot.data!;
            return Positioned(
              bottom: 16.0,
              right: 12.0,
              child: Row(
                children: List.generate(documents.length, (index) {
                  final document = documents[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: InkWell(
                    onTap: () {
                      _openFileOrLink(document['url']);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(child: Text('${index + 1}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00296B)),)
                      ),
                    ),
                  ),
                  );
                }),
              ),
            );
          },
        ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ccProgramma')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Errore: ${snapshot.error}')),
                );
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Nessun programma trovato',
                  style: TextStyle(fontSize: 19, color: Colors.black54),))
                );
              }

              final programmi = snapshot.data!.docs;
              programmi.sort((a, b) {
                int dateComparison = a['data'].compareTo(b['data']);
                if (dateComparison != 0) return dateComparison;
                return a['orario'].compareTo(b['orario']);
              });

              Map<String, List<QueryDocumentSnapshot>> groupedProgrammi = {};
              DateTime now = DateTime.now();
              QueryDocumentSnapshot? lastBeforeNow;

              for (var programma in programmi) {
                String data = programma['data'];
                DateTime programmaDate = DateFormat('dd/MM/yyyy').parse(data);
                DateTime programmaTime =
                    DateFormat('HH:mm').parse(programma['orario']);
                DateTime programmaDateTime = DateTime(
                  programmaDate.year,
                  programmaDate.month,
                  programmaDate.day,
                  programmaTime.hour,
                  programmaTime.minute,
                );

                if (programmaDateTime.isAfter(now)) {
                  if (lastBeforeNow != null) {
                    String lastBeforeNowData = lastBeforeNow['data'];
                    if (lastBeforeNowData == data) {
                      if (!groupedProgrammi.containsKey(data)) {
                        groupedProgrammi[data] = [];
                      }
                      groupedProgrammi[data]!.add(lastBeforeNow);
                    }
                    lastBeforeNow = null;
                  }
              
                  if (!groupedProgrammi.containsKey(data)) {
                    groupedProgrammi[data] = [];
                  }
                  groupedProgrammi[data]!.add(programma);
                } else {
                  lastBeforeNow = programma;
                }
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    String data = groupedProgrammi.keys.elementAt(index);
                    List<QueryDocumentSnapshot> programmiPerData =
                        groupedProgrammi[data]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 12, 16, 6),
                          child: index == 0
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child:
                                    AutoSizeText(
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
                                        minFontSize: 19,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CCProgrammaCompleto(
                                                  ccRole: widget.ccRole),
                                        ),
                                      ),
                                      child: const Text(
                                        "Programma completo",
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                )
                              :
                              AutoSizeText(
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
                                 minFontSize: 19,
                                 overflow: TextOverflow.ellipsis,
                                 maxLines: 1,
                              ),
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
                                      Row(
                                        children: [
                                          Image.asset(
                                            'images/spaghetti.png',
                                            width: 25,
                                            height: 25,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                                    if (programma['categoria'] == 'partita')
                                      Row(
                                        children: [
                                          Image.asset(
                                            'images/calcio.png',
                                            width: 25,
                                            height: 25,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                                    if (programma['categoria'] == 'show')
                                      Row(
                                        children: [
                                          Image.asset(
                                            'images/show.png',
                                            width: 25,
                                            height: 25,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                                    if (programma['categoria'] == 'altro')
                                      Row(
                                        children: [
                                          Image.asset(
                                            'images/fuoco.png',
                                            width: 25,
                                            height: 25,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
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
                                    widget.ccRole == 'staff'
                                        ? IconButton(
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
                                                    squadre:
                                                        programma['squadre'],
                                                    codiceSquadre: programma[
                                                        'codiceSquadre'],
                                                    incarico:
                                                        programma['incarico'],
                                                    codiceIncarico: programma[
                                                        'codiceIncarico'],
                                                    altro: programma['altro'],
                                                    categoria:
                                                        programma['categoria'],
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.edit,
                                                size: 20),
                                          )
                                        : Container(),
                                  ],
                                ),
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
                                                              Align(
                                                                alignment: Alignment.centerLeft,
                                                                child: Text(
                                                                  squadre.join(', '),
                                                                  style: const TextStyle(fontSize: 15),
                                                                ),
                                                              ),
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
                        }),
                      ],
                    );
                  },
                  childCount: groupedProgrammi.keys.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: widget.ccRole == 'staff'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CCNuovoProgramma()),
                );
              },
              shape: const CircleBorder(),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}