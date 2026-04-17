import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CcAlboDOroClassifica extends StatefulWidget {
  final String docId;
  final int anno;

  const CcAlboDOroClassifica(
      {super.key, required this.docId, required this.anno});

  @override
  State<CcAlboDOroClassifica> createState() => _CcAlboDOroClassificaState();
}

class _CcAlboDOroClassificaState extends State<CcAlboDOroClassifica> {
  List<Map<String, dynamic>> _classifica = [];
  List<Map<String, dynamic>> _marcatori = [];
  bool _isLoading = true;
  bool _showClassifica = true;

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ccAlboDoro')
          .doc(widget.docId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final List<dynamic> squadre = data['classifica'] ?? [];
        final List<dynamic> marcatori = data['marcatori'] ?? [];
        setState(() {
          _classifica =
              squadre.map((s) => Map<String, dynamic>.from(s)).toList();
          _classifica.sort((a, b) =>
              (a['posizione'] as int).compareTo(b['posizione'] as int));
          _marcatori =
              marcatori.map((m) => Map<String, dynamic>.from(m)).toList();
          _marcatori
              .sort((a, b) => (b['gol'] as int).compareTo(a['gol'] as int));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text('CC ${widget.anno}'),
        backgroundColor: const Color(0xFF00296B),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Toggle buttons
                    Container(
                      color: const Color(0xFF00296B),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _showClassifica = true),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _showClassifica
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Classifica',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _showClassifica
                                        ? Colors.white
                                        : Colors.white60,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _showClassifica = false),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: !_showClassifica
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Capocannonieri',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !_showClassifica
                                        ? Colors.white
                                        : Colors.white60,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: _showClassifica
                          ? _classifica.isEmpty
                              ? const Center(
                                  child: Text('Nessun dato disponibile',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.black54)))
                              : _buildClassificaView()
                          : _marcatori.isEmpty
                              ? const Center(
                                  child: Text('Nessun marcatore',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.black54)))
                              : _buildMarcatoriView(),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // ──────────────── CLASSIFICA VIEW ────────────────

  Widget _buildClassificaView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          const SizedBox(height: 16),
          if (_classifica.length >= 3) _buildTopPodium(),
          const SizedBox(height: 10),
          _buildMiddleList(),
          const SizedBox(height: 10),
          if (_classifica.length >= 6) _buildBottomPodium(),
        ],
      ),
    );
  }

  // ──────────────── TOP PODIUM ────────────────

  Widget _buildTopPodium() {
    final first = _classifica[0];
    final second = _classifica[1];
    final third = _classifica[2];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF00296B), Color(0xFF001845)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 10),
          Expanded(
              child: _buildPodiumItem(second, 2, 100, const Color(0xFFC0C0C0))),
          const SizedBox(width: 8),
          Expanded(
              child: _buildPodiumItem(first, 1, 130, const Color(0xFFFFD700))),
          const SizedBox(width: 8),
          Expanded(
              child: _buildPodiumItem(third, 3, 80, const Color(0xFFCD7F32))),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
      Map<String, dynamic> team, int position, double height, Color color) {
    // 2nd place: round bottom-left; 3rd place: round bottom-right
    BorderRadius podiumRadius;
    if (position == 2) {
      podiumRadius = const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
        bottomLeft: Radius.circular(10),
      );
    } else if (position == 3) {
      podiumRadius = const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
        bottomRight: Radius.circular(10),
      );
    } else {
      podiumRadius = const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTeamLogo(team['logo'] ?? '', 44),
        const SizedBox(height: 4),
        Text(
          team['squadra'] ?? '',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.9),
                color.withValues(alpha: 0.5),
              ],
            ),
            borderRadius: podiumRadius,
          ),
          child: Center(
            child: Text(
              '$position°',
              style: TextStyle(
                fontSize: position == 1 ? 32 : 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: const [
                  Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 4,
                      color: Color(0x60000000)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────── MIDDLE LIST ────────────────

  Widget _buildMiddleList() {
    final int endIndex =
        _classifica.length >= 6 ? _classifica.length - 3 : _classifica.length;
    final middleTeams = _classifica.sublist(
        3 < _classifica.length ? 3 : _classifica.length, endIndex);

    if (middleTeams.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: middleTeams.map((team) {
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${team['posizione']}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildTeamLogo(team['logo'] ?? '', 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    team['squadra'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ──────────────── BOTTOM PODIUM ────────────────

  Widget _buildBottomPodium() {
    final total = _classifica.length;
    final last = _classifica[total - 1];
    final secondLast = _classifica[total - 2];
    final thirdLast = _classifica[total - 3];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              Expanded(
                  child: Container(height: 1, color: Colors.grey.shade300)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('💀', style: TextStyle(fontSize: 20)),
              ),
              Expanded(
                  child: Container(height: 1, color: Colors.grey.shade300)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.only(bottom: 16, top: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0C11), Color(0xFF1A0608)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 10),
              Expanded(
                  child: _buildBottomPodiumItem(
                      secondLast, 70, const Color(0xFF5C4033), 'secondLast')),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildBottomPodiumItem(
                      last, 90, const Color(0xFF8B0000), 'last')),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildBottomPodiumItem(
                      thirdLast, 55, const Color(0xFF5C4033), 'thirdLast')),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPodiumItem(
      Map<String, dynamic> team, double height, Color color, String slot) {
    // last (center): round top-left; secondLast (left): round top-right
    BorderRadius podiumRadius;
    if (slot == 'secondLast') {
      // 15th place: round top-left
      podiumRadius = const BorderRadius.only(
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(10),
        topLeft: Radius.circular(10),
      );
    } else if (slot == 'thirdLast') {
      // 14th place: round top-right
      podiumRadius = const BorderRadius.only(
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(10),
        topRight: Radius.circular(10),
      );
    } else {
      podiumRadius = const BorderRadius.only(
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(10),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.5),
                color.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: podiumRadius,
          ),
          child: Center(
            child: Text(
              '${team['posizione']}°',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white70,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _buildTeamLogo(team['logo'] ?? '', 36),
        const SizedBox(height: 3),
        Text(
          team['squadra'] ?? '',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ──────────────── MARCATORI VIEW ────────────────

  Widget _buildMarcatoriView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _marcatori.length,
      itemBuilder: (context, index) {
        final m = _marcatori[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: index < 3
                    ? FaIcon(
                        FontAwesomeIcons.medal,
                        color: index == 0
                            ? Colors.amber
                            : index == 1
                                ? Colors.grey
                                : Colors.brown,
                        size: 22,
                      )
                    : Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['nome'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      m['squadra'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${m['gol']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────── HELPERS ────────────────

  Widget _buildTeamLogo(String logoUrl, double size) {
    if (logoUrl.isEmpty) {
      return FaIcon(FontAwesomeIcons.shieldHalved,
          color: Colors.grey, size: size * 0.7);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: Image.network(
        logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => FaIcon(FontAwesomeIcons.shieldHalved,
            color: Colors.grey, size: size * 0.7),
      ),
    );
  }
}
