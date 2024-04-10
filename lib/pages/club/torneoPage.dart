import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ms_undraw/ms_undraw.dart';

class TabScorer extends StatefulWidget {
  const TabScorer({super.key, required this.document});

  final Map document;

  @override
  _TabScorerState createState() => _TabScorerState();
}

class _TabScorerState extends State<TabScorer> {
  late CollectionReference<Map<String, dynamic>> _scorerCollection;
  late Stream<QuerySnapshot> _scorersStream;
  String name = '';
  String surname = '';
  String bottomLevel = 'torneo';
  int pointCount = 1;
  int goalCount = 1;

  @override
  void initState() {
    super.initState();
    _scorerCollection = FirebaseFirestore.instance.collection('club_scorer');
    _scorersStream = _scorerCollection
        .orderBy('points', descending: true)
        .orderBy('goals', descending: true)
        .snapshots();
  }

  Future<void> _showAddDialog(String selectedClass) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(selectedClass),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (value) {
                      setState(() {
                        name = value;
                      });
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Surname'),
                    onChanged: (value) {
                      setState(() {
                        surname = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (pointCount > 1) {
                            setState(() {
                              pointCount = pointCount - 1;
                            });
                          }
                        },
                        child: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: 8.0),
                      Text('$pointCount'),
                      const SizedBox(width: 8.0),
                      const Text('Punti'),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            pointCount = pointCount + 1;
                          });
                        },
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (goalCount > 1) {
                            setState(() {
                              goalCount = goalCount - 1;
                            });
                          }
                        },
                        child: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: 8.0),
                      Text('$goalCount'),
                      const SizedBox(width: 8.0),
                      const Text('Goal'),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            goalCount = goalCount + 1;
                          });
                        },
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    pointCount = 1;
                    goalCount = 1;
                  },
                  child: const Text('Annulla'),
                ),
                TextButton(
                  onPressed: () async {
                    if (name != "" && surname != "") {
                      await FirebaseFirestore.instance
                          .collection('club_scorer')
                          .add({
                        'name': name,
                        'surname': surname,
                        'class': selectedClass,
                        'points': pointCount,
                        'goals': goalCount,
                      });
                      pointCount = 1;
                      goalCount = 1;
                      Navigator.of(context).pop();
                    } else if (name == "") {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Inserisci il nome')));
                    } else if (surname == "") {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Inserisci il cognome')));
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDialog(String name, String surname, String selectedClass,
      int counter, int goal, String scorerId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        int localCounter = counter;
        int goalCounter = goal;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Modifica Scorer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Name: $name'),
                  Text('Surname: $surname'),
                  Text('Team: $selectedClass'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (localCounter > 1) {
                            setState(() {
                              localCounter--;
                            });
                          }
                        },
                        child: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: 8.0),
                      Text('$localCounter'),
                      const SizedBox(width: 8.0),
                      const Text('Punti'),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            localCounter++;
                          });
                        },
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (goalCounter > 1) {
                            setState(() {
                              goalCounter--;
                            });
                          }
                        },
                        child: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: 8.0),
                      Text('$goalCounter'),
                      const SizedBox(width: 8.0),
                      const Text('Goal'),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            goalCounter++;
                          });
                        },
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Annulla'),
                ),
                TextButton(
                  onPressed: () async {
                    await _scorerCollection
                        .doc(scorerId)
                        .update({'points': localCounter, 'goals': goalCounter});
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteScorer(String scorerId) async {
    final confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Conferma"),
          content: const Text("Sei sicuro di voler eliminare questo scorer?"),
          actions: <Widget>[
            ElevatedButton(
              child: const Text("No"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text("Si"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete) {
      await _scorerCollection.doc(scorerId).delete();
    }
  }

  Table _buildTable(List<QueryDocumentSnapshot> scorers) {
    TableRow spacer = TableRow(
      children: <Widget>[
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        widget.document["status"] == 'Admin'
            ? const SizedBox(height: 8)
            : Container(),
      ],
    );
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
              child: Text(
                '',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
              child: Text(
                'Nome',
                textAlign: TextAlign.left,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
              child: Text(
                'Punti',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
              child: Text(
                'Goal',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            widget.document["status"] == 'Admin'
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
                    child: Text(
                      '',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                : Container(),
          ],
        ),
        spacer,
        ...scorers
            .asMap()
            .entries
            .map((entry) {
              int index = entry.key;
              QueryDocumentSnapshot scorer = entry.value;
              Map<String, dynamic> scorerData =
                  scorer.data() as Map<String, dynamic>;
              String scorerId = scorer.id;
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
                children: [
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${scorerData['name']} ${scorerData['surname']}',
                          textAlign: TextAlign.left,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${scorerData['class']}',
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
                    child: Text(
                      '${scorerData['points']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20.0),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
                    child: Text(
                      '${scorerData['goals']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20.0),
                    ),
                  ),
                  widget.document["status"] == 'Admin'
                      ? PopupMenuButton(itemBuilder: (context) {
                          return [
                            PopupMenuItem(
                              value: 0,
                              child: ListTile(
                                title: const Text('Modifica'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _showDialog(
                                      scorerData['name'],
                                      scorerData['surname'],
                                      scorerData['class'],
                                      scorerData['points'],
                                      scorerData['goals'],
                                      scorerId);
                                },
                              ),
                            ),
                            PopupMenuItem(
                              value: 1,
                              child: ListTile(
                                title: const Text('Elimina'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _deleteScorer(scorerId);
                                },
                              ),
                            ),
                          ];
                        })
                      : Container(),
                ],
              );
            })
            .expand((element) => [element, spacer])
            .toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _scorersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }
          List<QueryDocumentSnapshot> scorers = snapshot.data!.docs;
          if (scorers.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200.0,
                  child: UnDraw(
                    illustration: UnDrawIllustration.junior_soccer,
                    placeholder: const SizedBox(
                      height: 200.0,
                      width: 200.0,
                    ),
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Text(
                  'Non ci sono giocatori registrati',
                  style: TextStyle(fontSize: 20.0, color: Colors.black54),
                ),
              ],
            );
          }
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(child: _buildTable(scorers)),
          );
        },
      ),
      floatingActionButton:
          widget.document['status'] == 'Admin' && bottomLevel == 'torneo'
              ? SpeedDial(
                  icon: Icons.add,
                  activeIcon: Icons.close,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  children: [
                    SpeedDialChild(
                      child: const Text("1°"),
                      onTap: () {
                        _showAddDialog("1° liceo");
                      },
                    ),
                    SpeedDialChild(
                      child: const Text("2°"),
                      onTap: () {
                        _showAddDialog("2° liceo");
                      },
                    ),
                    SpeedDialChild(
                      child: const Text("3°"),
                      onTap: () {
                        _showAddDialog("3° liceo");
                      },
                    ),
                    SpeedDialChild(
                      child: const Text("4°"),
                      onTap: () {
                        _showAddDialog("4° liceo");
                      },
                    ),
                    SpeedDialChild(
                      child: const Text("5°"),
                      onTap: () {
                        _showAddDialog("5° liceo");
                      },
                    ),
                  ],
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }
}
