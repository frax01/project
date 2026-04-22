import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ccNuovoProgramma.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'ccProgrammaCompleto.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:url_launcher/url_launcher.dart';
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
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nell\'apertura del link: $e')),
      );
    }
  }

  void _openLocalImages(List<String> assetPaths, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LocalImageViewer(assetPaths: assetPaths, title: title),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getDocumentsFromStorage() async {
    final FirebaseStorage storage = FirebaseStorage.instance;
    final ListResult result = await storage.ref('giornalino/').listAll();

    final List<Map<String, dynamic>> documents = [];
    for (var item in result.items) {
      final String url = await item.getDownloadURL();
      final FullMetadata metadata = await item.getMetadata();
      final DateTime updated = metadata.updated ?? DateTime.now();

      documents.add({
        'url': url,
        'updated': updated,
        'ref': item,
      });
    }

    // Ordina i documenti in base alla data di aggiornamento
    documents.sort((a, b) => a['updated'].compareTo(b['updated']));

    return documents;
  }

  Future<void> _deleteDocument(Reference ref) async {
    try {
      await ref.delete();
      setState(() {}); // Refresh the UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giornalino eliminato correttamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
      );
    }
  }

  void _confirmDelete(Reference ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Giornalino'),
        content: const Text('Sei sicuro di voler eliminare questo giornalino?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDocument(ref);
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                  right: 6.0,
                  top: 10.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () async {
                          if (Platform.isIOS) {
                            _openLocalImages([
                              'images/regolamentoPag1.png',
                              'images/regolamentoPag2.png',
                            ], 'Regolamento');
                          } else {
                            final FirebaseStorage storage =
                                FirebaseStorage.instance;
                            final ref = storage
                                .ref()
                                .child('DocumentiCC/regolamento.pdf');
                            final url = await ref.getDownloadURL();
                            _openFileOrLink(url);
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.description,
                                size: 16,
                                color: Color(0xFF00296B),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Regolamento',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF00296B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      InkWell(
                        onTap: () async {
                          if (Platform.isIOS) {
                            _openLocalImages(['images/mappa.jpg'], 'Mappa');
                          } else {
                            final FirebaseStorage storage =
                                FirebaseStorage.instance;
                            final ref = storage
                                .ref()
                                .child('DocumentiCC/IMG-20250414-WA0009.jpg');
                            final url = await ref.getDownloadURL();
                            _openFileOrLink(url);
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.map,
                                size: 16,
                                color: Color(0xFF00296B),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Mappa',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF00296B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getDocumentsFromStorage(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Positioned(
                        bottom: 16.0,
                        right: 20.0,
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        ),
                      );
                    } else if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final documents = snapshot.data!;
                    return Positioned(
                      bottom: 10.0,
                      right: 6.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(documents.length, (index) {
                          final document = documents[index];
                          final isFirst = index == 0;
                          final isLast = index == documents.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(
                              left: isFirst ? 0 : 2.0,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashColor: widget.ccRole == 'staff'
                                    ? Colors.red.withValues(alpha: 0.3)
                                    : null,
                                highlightColor: widget.ccRole == 'staff'
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : null,
                                onTap: () {
                                  _openFileOrLink(document['url']);
                                },
                                onLongPress: widget.ccRole == 'staff'
                                    ? () {
                                        _confirmDelete(document['ref']);
                                      }
                                    : null,
                                borderRadius: BorderRadius.only(
                                  topLeft: isFirst
                                      ? const Radius.circular(20)
                                      : Radius.zero,
                                  bottomLeft: isFirst
                                      ? const Radius.circular(20)
                                      : Radius.zero,
                                  topRight: isLast
                                      ? const Radius.circular(20)
                                      : Radius.zero,
                                  bottomRight: isLast
                                      ? const Radius.circular(20)
                                      : Radius.zero,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: isFirst
                                          ? const Radius.circular(20)
                                          : Radius.zero,
                                      bottomLeft: isFirst
                                          ? const Radius.circular(20)
                                          : Radius.zero,
                                      topRight: isLast
                                          ? const Radius.circular(20)
                                          : Radius.zero,
                                      bottomRight: isLast
                                          ? const Radius.circular(20)
                                          : Radius.zero,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.newspaper,
                                        size: 16,
                                        color: Color(0xFF00296B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Giorno ${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF00296B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
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
                    child: Center(
                        child: Text(
                  'Nessun programma',
                  style: TextStyle(fontSize: 19, color: Colors.black54),
                )));
              }

              final programmi = snapshot.data!.docs;
              programmi.sort((a, b) {
                final dateA = DateFormat('dd/MM/yyyy').parse(a['data']);
                final dateB = DateFormat('dd/MM/yyyy').parse(b['data']);
                int dateComparison = dateA.compareTo(dateB);
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
                          padding: const EdgeInsets.fromLTRB(16.0, 4, 16, 6),
                          child: index == 0
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: AutoSizeText(
                                        data == '30/04/2026'
                                            ? 'Giovedì 30'
                                            : data == '01/05/2026'
                                                ? 'Venerdì 1'
                                                : data == '02/05/2026'
                                                    ? 'Sabato 2'
                                                    : 'Domenica 3',
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
                              : AutoSizeText(
                                  data == '30/04/2026'
                                      ? 'Giovedì 30'
                                      : data == '01/05/2026'
                                          ? 'Venerdì 1'
                                          : data == '02/05/2026'
                                              ? 'Sabato 2'
                                              : 'Domenica 3',
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
                            shadowColor: Colors.black54,
                            surfaceTintColor: Colors.transparent,
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
                                    if (programma['categoria'] == 'info')
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            size: 25,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                                    if (programma['categoria'] == 'preghiera')
                                      Row(
                                        children: [
                                          const Text(
                                            '🙏',
                                            style: TextStyle(fontSize: 22),
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
                                                          .isNotEmpty ||
                                                      programma['incarico']
                                                          .isNotEmpty ||
                                                      programma[
                                                              'codiceIncarico']
                                                          .isNotEmpty
                                                  ? FutureBuilder<
                                                      List<List<String>>>(
                                                      future: Future.wait([
                                                        _getNomiSquadre(List<
                                                                String>.from(
                                                            programma[
                                                                'codiceSquadre'])),
                                                        _getNomiSquadre(List<
                                                                String>.from(
                                                            programma[
                                                                'codiceIncarico'])),
                                                      ]),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return const Center(
                                                              child:
                                                                  CircularProgressIndicator());
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
                                                              snapshot.data![0]
                                                                  .isNotEmpty) {
                                                            squadre.addAll(
                                                                snapshot
                                                                    .data![0]);
                                                          }

                                                          List<String>
                                                              incarico =
                                                              List<String>.from(
                                                                  programma[
                                                                      'incarico']);
                                                          if (snapshot
                                                                  .hasData &&
                                                              snapshot.data![1]
                                                                  .isNotEmpty) {
                                                            incarico.addAll(
                                                                snapshot
                                                                    .data![1]);
                                                          }

                                                          if (squadre.isEmpty &&
                                                              incarico
                                                                  .isEmpty) {
                                                            return Center(
                                                              child: Text(
                                                                "In aggiornamento",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic),
                                                              ),
                                                            );
                                                          }

                                                          return Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              if (squadre
                                                                  .isNotEmpty)
                                                                Text(
                                                                  squadre.join(
                                                                      ', '),
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          15),
                                                                ),
                                                              if (incarico
                                                                  .isNotEmpty) ...[
                                                                if (squadre
                                                                    .isNotEmpty)
                                                                  const SizedBox(
                                                                      height:
                                                                          8),
                                                                const Text(
                                                                  "Incarico",
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        17,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .centerLeft,
                                                                  child: Text(
                                                                    incarico.join(
                                                                        ', '),
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            15),
                                                                  ),
                                                                ),
                                                              ],
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
                                                        if (programma[
                                                                    'squadre']
                                                                .isNotEmpty ||
                                                            programma[
                                                                    'codiceSquadre']
                                                                .isNotEmpty ||
                                                            programma[
                                                                    'incarico']
                                                                .isNotEmpty ||
                                                            programma[
                                                                    'codiceIncarico']
                                                                .isNotEmpty)
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

class _LocalImageViewer extends StatelessWidget {
  final List<String> assetPaths;
  final String title;
  const _LocalImageViewer({required this.assetPaths, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF00296B),
        foregroundColor: Colors.white,
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: assetPaths.length,
            itemBuilder: (_, i) => Image.asset(assetPaths[i]),
          ),
        ),
      ),
    );
  }
}
