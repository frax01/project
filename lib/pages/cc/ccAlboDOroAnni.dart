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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('ccAlboDoro').get();
    final entries = <Map<String, dynamic>>[];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final anno = data['anno'];
      if (anno != null) {
        entries.add({
          'docId': doc.id,
          'anno': anno is int ? anno : int.tryParse(anno.toString()) ?? 0,
        });
      }
    }
    entries.sort((a, b) => (b['anno'] as int).compareTo(a['anno'] as int));
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Albo d\'oro'),
        backgroundColor: const Color(0xFF00296B),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(
                  child: Text('Nessun anno disponibile',
                      style: TextStyle(fontSize: 18, color: Colors.black54)))
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
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
                                colors: [Color(0xFF0052CC), Color(0xFF003D99)],
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
                                const FaIcon(FontAwesomeIcons.medal, color: Color.fromARGB(255, 255, 255, 255), size: 28),
                                const SizedBox(width: 14),
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
                  },
                ),
    );
  }
}
