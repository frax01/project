import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CCCapocannonieri extends StatefulWidget {
  const CCCapocannonieri({super.key});

  @override
  State<CCCapocannonieri> createState() => _CCCapocannonieriState();
}

class _CCCapocannonieriState extends State<CCCapocannonieri> {
  Map<String, String> squadre = {};

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
      final querySnapshot =
          await FirebaseFirestore.instance.collection(collection).get();
      for (var doc in querySnapshot.docs) {
        List<dynamic> marcatoriList = doc['marcatori'] ?? [];
        for (var marcatore in marcatoriList) {
          String nome = marcatore['nome'];
          String dove = marcatore['dove'];
          String cosa = marcatore['cosa'];
          String squadra = '';
          if (dove == 'casa' && cosa == 'gol') {
            squadra = doc['casa'];
            if (marcatori.containsKey(nome)) {
            marcatori[nome] = marcatori[nome]! + 1;
          } else {
            marcatori[nome] = 1;
            squadre[nome] = squadra;
          }
          } else if (dove == 'fuori' && cosa == 'gol') {
            squadra = doc['fuori'];
            if (marcatori.containsKey(nome)) {
            marcatori[nome] = marcatori[nome]! + 1;
          } else {
            marcatori[nome] = 1;
            squadre[nome] = squadra;
          }
          }
        }
      }
    }

    yield marcatori;
  }

  Table _buildTable(List<MapEntry<String, int>> scorers) {
    var spacerChildren = <Widget>[
      const SizedBox(height: 8),
      const SizedBox(height: 8),
      const SizedBox(height: 8),
    ];
    TableRow spacer = TableRow(
      children: spacerChildren,
    );

    var columnWidths = <int, TableColumnWidth>{
      0: const FlexColumnWidth(1),
      1: const FlexColumnWidth(3),
      2: const FlexColumnWidth(1),
    };

    List<Widget> children = [
      const Padding(
        padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
        child: Text(
          '',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(16.0, 8.0, 4.0, 8.0),
        child: Text(
          'Nome',
          textAlign: TextAlign.left,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
        child: Text(
          'Goal',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    ];

    var firstRow = TableRow(children: children);
    int index = 0;

    return Table(
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        firstRow,
        spacer,
        ...scorers.asMap().entries.map((entry) {
          final marcatore = entry.value;
          var rowChildren = <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
              child: index == 0
                  ? const Center(
                      child: FaIcon(
                        FontAwesomeIcons.medal,
                        color: Colors.amber,
                      ),
                    )
                  : index == 1
                      ? const Center(
                          child: FaIcon(
                            FontAwesomeIcons.medal,
                            color: Colors.grey,
                          ),
                        )
                      : index == 2
                          ? const Center(
                              child: FaIcon(
                                FontAwesomeIcons.medal,
                                color: Colors.brown,
                              ),
                            )
                          : Text(
                              '${index + 1}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    marcatore.key,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    squadre[marcatore.key] ?? '',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
              child: Text(
                marcatore.value.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 24.0),
              ),
            ),
          ];

          index++;

          return TableRow(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
              borderRadius: BorderRadius.circular(10.0),
            ),
            children: rowChildren,
          );
        }).expand((element) => [element, spacer]),
      ],
    );
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
          final List<MapEntry<String, int>> sortedMarcatori = marcatori.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildTable(sortedMarcatori),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}