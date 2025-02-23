import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ccNuovaPartitaGironi.dart';
import 'ccNuovaPartitaOttavi.dart';
import 'ccModificaPartita.dart';

class CCCalendario extends StatefulWidget {
  const CCCalendario({
    super.key,
  });

  @override
  State<CCCalendario> createState() => _CCCalendarioState();
}

class _CCCalendarioState extends State<CCCalendario> {
  String _selectedSegment = 'Gironi';
  late Stream<List<Map<String, dynamic>>> _streamPartite;

  @override
  void initState() {
    super.initState();
    _streamPartite = _getPartite();
    _loadSquadre();
  }

  Map<String, String> _squadreLoghi = {};

  Future<void> _loadSquadre() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('ccSquadre').get();

    Map<String, String> squadreLoghi = {};
    for (var doc in snapshot.docs) {
      List<Map<String, dynamic>> squadre =
          List<Map<String, dynamic>>.from(doc['squadre']);
      for (var squadra in squadre) {
        squadreLoghi[squadra['squadra']] = squadra['logo'];
      }
    }

    setState(() {
      _squadreLoghi = squadreLoghi;
    });
  }

  Stream<List<Map<String, dynamic>>> _getPartite() {
    if (_selectedSegment == 'Gironi') {
      return FirebaseFirestore.instance
          .collection('ccPartiteGironi')
          .snapshots()
          .map((querySnapshot) {
        List<Map<String, dynamic>> partite = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        partite.sort((a, b) {
          int gironeComparison = a['girone'].compareTo(b['girone']);
          if (gironeComparison != 0) return gironeComparison;

          int turnoComparison = a['turno'].compareTo(b['turno']);
          if (turnoComparison != 0) return turnoComparison;

          if (a['orario'] == '' && b['orario'] == '') return 0;
          if (a['orario'] == '') return 1;
          if (b['orario'] == '') return -1;

          return a['orario'].compareTo(b['orario']);
        });

        return partite;
      });
    } else {
      return Stream.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SegmentedButton<String>(
                selectedIcon: const Icon(Icons.check),
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'Gironi',
                    label: Text('Gir', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment<String>(
                    value: 'Ottavi',
                    label: Text('Ott', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment<String>(
                    value: 'Quarti',
                    label: Text('Qua', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment<String>(
                    value: 'Semifinali',
                    label: Text('Sem', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment<String>(
                    value: 'Finali',
                    label: Text('Fin', style: TextStyle(fontSize: 12)),
                  ),
                ],
                selected: <String>{_selectedSegment},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedSegment = newSelection.first;
                    _streamPartite = _getPartite();
                  });
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _streamPartite,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Errore: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nessuna partita trovata'));
                  }

                  final partite = snapshot.data!;
                  final groupedPartite = <String, List<Map<String, dynamic>>>{};

                  for (var partita in partite) {
                    final girone = partita['girone'];
                    if (!groupedPartite.containsKey(girone)) {
                      groupedPartite[girone] = [];
                    }
                    groupedPartite[girone]!.add(partita);
                  }

                  return Column(
                    children: groupedPartite.entries.map((entry) {
                      final girone = entry.key;
                      final partiteGirone = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Girone $girone',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...partiteGirone.map((partita) {
                            final logoCasa =
                                _squadreLoghi[partita['casa']] ?? '';
                            final logoFuori =
                                _squadreLoghi[partita['fuori']] ?? '';

                            int golCasa = 0;
                            int golFuori = 0;
                            List<Map<String, dynamic>> marcatori =
                                List<Map<String, dynamic>>.from(
                                    partita['marcatori'] ?? []);
                            for (var marcatore in marcatori) {
                              if (marcatore['dove'] == 'casa') {
                                golCasa++;
                              } else if (marcatore['dove'] == 'fuori') {
                                golFuori++;
                              }
                            }

                            return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CCModificaPartita(
                                        casa: partita['casa'],
                                        fuori: partita['fuori'],
                                        logocasa: logoCasa,
                                        logofuori: logoCasa,
                                        data: '25/04/2025',
                                        orario: partita['orario'],
                                        campo: partita['campo'],
                                        arbitro: partita['arbitro'],
                                        girone: girone,
                                        iniziata: partita['iniziata'],
                                        finita: partita['finita'],
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          children: [
                                            logoCasa.isNotEmpty
                                                ? Image.network(
                                                    logoCasa,
                                                    width: 40,
                                                    height: 40,
                                                  )
                                                : const Icon(
                                                    Icons.sports_soccer),
                                            Text(partita['casa']),
                                          ],
                                        ),
                                        const SizedBox(width: 4),
                                        partita['iniziata'] || partita['finita']
                                            ? Text('$golCasa',
                                                style: const TextStyle(
                                                    fontSize: 34))
                                            : const Text(''),
                                        partita['iniziata'] || partita['finita']
                                            ? const Text(':')
                                            : const Text('VS'),
                                        partita['iniziata'] || partita['finita']
                                            ? Text('$golFuori',
                                                style: const TextStyle(
                                                    fontSize: 34))
                                            : const Text(''),
                                        const SizedBox(width: 4),
                                        Column(
                                          children: [
                                            logoFuori.isNotEmpty
                                                ? Image.network(
                                                    logoFuori,
                                                    width: 40,
                                                    height: 40,
                                                  )
                                                : const Icon(
                                                    Icons.sports_soccer),
                                            Text(partita['fuori']),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(partita['campo'] != ''
                                            ? 'H ${partita['orario']} - '
                                            : 'Ora da def. - '),
                                        Text(partita['campo'].length > 1
                                            ? 'Campo ${partita['campo'][1]}'
                                            : 'Campo non def.'),
                                        Text(partita['arbitro'] != ''
                                            ? ' - ${partita['arbitro']}'
                                            : ''),
                                      ],
                                    ),
                                    const Divider(height: 36, thickness: 1),
                                  ],
                                ));
                          }).toList(),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _selectedSegment == 'Gironi'
              ? Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CCnuovaPartitaGironi()),
                )
              : Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CCnuovaPartitaOttavi()),
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
