import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ccAlboDOroClassifica.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CcAlboDOroAnni extends StatefulWidget {
  const CcAlboDOroAnni({super.key});

  @override
  State<CcAlboDOroAnni> createState() => _CcAlboDOroAnniState();
}

class _CcAlboDOroAnniState extends State<CcAlboDOroAnni> {
  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _palmares = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final firestore = FirebaseFirestore.instance;

    // Scarica in parallelo gli albi d'oro e il documento di bonus manuale.
    final results = await Future.wait([
      firestore.collection('ccAlboDoro').get(),
      firestore.collection('ccVittorieClub').doc('bonus').get(),
    ]);
    final snapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final bonusDoc = results[1] as DocumentSnapshot<Map<String, dynamic>>;

    final entries = <Map<String, dynamic>>[];
    final Map<String, int> vittorie = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final anno = data['anno'];
      if (anno != null) {
        entries.add({
          'docId': doc.id,
          'anno': anno is int ? anno : int.tryParse(anno.toString()) ?? 0,
        });

        // Extract the winner (posizione 1) from classifica
        final List<dynamic> classifica = data['classifica'] ?? [];
        for (var item in classifica) {
          if (item is Map && item['posizione'] == 1) {
            final fullName = item['squadra'] as String? ?? '';
            final club = fullName.split(' ').first;
            if (club.isNotEmpty) {
              vittorie[club] = (vittorie[club] ?? 0) + 1;
            }
            break;
          }
        }
      }
    }

    // Somma le vittorie bonus inserite manualmente su Firestore.
    // Documento atteso: ccVittorieClub/bonus con campo `vittorie` (mappa club -> int).
    if (bonusDoc.exists) {
      final bonusData = bonusDoc.data();
      final rawBonus = bonusData?['vittorie'];
      if (rawBonus is Map) {
        rawBonus.forEach((key, value) {
          if (key is String && key.isNotEmpty) {
            final extra = value is int
                ? value
                : int.tryParse(value.toString()) ?? 0;
            if (extra > 0) {
              vittorie[key] = (vittorie[key] ?? 0) + extra;
            }
          }
        });
      }
    }

    entries.sort((a, b) => (b['anno'] as int).compareTo(a['anno'] as int));

    // Build palmares sorted by wins descending
    final palmaresEntries = vittorie.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final palmares = palmaresEntries
        .map((e) => {'squadra': e.key, 'vittorie': e.value})
        .toList();

    setState(() {
      _entries = entries;
      _palmares = palmares;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Albo d\'oro'),
        backgroundColor: const Color(0xFF00296B),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(
                  child: Text('Nessun anno disponibile',
                      style: TextStyle(fontSize: 18, color: Colors.black54)))
              : ListView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  children: [
                    // Palmares section
                    if (_palmares.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF00296B), Color(0xFF003D99)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00296B)
                                  .withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Palmares',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ...List.generate(_palmares.length, (index) {
                              final item = _palmares[index];
                              final squadra = item['squadra'] as String;
                              final vittorie = item['vittorie'] as int;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${index + 1}.',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        squadra,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        vittorie,
                                        (_) => const Padding(
                                          padding: EdgeInsets.only(left: 3),
                                          child: FaIcon(
                                            FontAwesomeIcons.trophy,
                                            color: Color(0xFFFFD700),
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Years list
                    ...List.generate(_entries.length, (index) {
                      final entry = _entries[index];
                      final anno = entry['anno'] as int;
                      final docId = entry['docId'] as String;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CcAlboDOroClassifica(
                                      docId: docId, anno: anno),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0052CC),
                                    Color(0xFF003D99)
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF003D99)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'CC $anno',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios,
                                      color: Colors.white54, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}
