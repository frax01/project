import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ms_undraw/ms_undraw.dart';

class Counter extends StatelessWidget {
  const Counter({
    Key? key,
    required this.title,
    required this.onUp,
    required this.onDown,
    required this.getCount,
  }) : super(key: key);

  final String title;
  final Function() onUp;
  final Function() onDown;
  final Function() getCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            if (getCount() > 1) {
              onDown();
            }
          },
          child: const Icon(Icons.remove),
        ),
        const SizedBox(width: 10.0),
        Column(
          children: [
            Text('${getCount()}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title),
          ],
        ),
        const SizedBox(width: 10.0),
        ElevatedButton(
          onPressed: () {
            onUp();
          },
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}

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

  Future<void> _showAddDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Nuovo giocatore"),
              content: SingleChildScrollView (
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Nome'),
                    onChanged: (value) {
                      setState(() {
                        name = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10.0),
                  Counter(
                    title: 'punti',
                    onUp: () {
                      setState(() {
                        pointCount = pointCount + 1;
                      });
                    },
                    onDown: () {
                      setState(() {
                        pointCount = pointCount - 1;
                      });
                    },
                    getCount: () => pointCount,
                  ),
                  const SizedBox(height: 10.0),
                  Counter(
                    title: 'goal',
                    onUp: () {
                      setState(() {
                        goalCount = goalCount + 1;
                      });
                    },
                    onDown: () {
                      setState(() {
                        goalCount = goalCount - 1;
                      });
                    },
                    getCount: () => goalCount,
                  ),
                ],
              )),
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
                    if (name != "") {
                      await FirebaseFirestore.instance
                          .collection('club_scorer')
                          .add({
                        'name': name,
                        'points': pointCount,
                        'goals': goalCount,
                      });
                      pointCount = 1;
                      goalCount = 1;
                      Navigator.of(context).pop();
                    } else if (name == "") {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Inserisci il nome')));
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

  Future<void> _showDialog(String name, //String selectedClass,
      int counter, int goal, String scorerId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        int localCounter = counter;
        int goalCounter = goal;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('$name'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Counter(
                    title: 'punti',
                    onUp: () {
                      setState(() {
                        localCounter++;
                      });
                    },
                    onDown: () {
                      if (localCounter > 1) {
                        setState(() {
                          localCounter--;
                        });
                      }
                    },
                    getCount: () => localCounter,
                  ),
                  const SizedBox(height: 10.0),
                  Counter(
                    title: 'goal',
                    onUp: () {
                      setState(() {
                        goalCounter++;
                      });
                    },
                    onDown: () {
                      if (goalCounter > 1) {
                        setState(() {
                          goalCounter--;
                        });
                      }
                    },
                    getCount: () => goalCounter,
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
          content: const Text("Eliminare il giocatore?"),
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
    var spacerChildren = <Widget>[
      const SizedBox(height: 8),
      const SizedBox(height: 8),
      const SizedBox(height: 8),
      const SizedBox(height: 8),
    ];
    if (widget.document["status"] == 'Admin') {
      spacerChildren.add(const SizedBox(height: 8));
    }
    TableRow spacer = TableRow(
      children: spacerChildren,
    );

    var columnWidths = <int, TableColumnWidth>{
      0: const FlexColumnWidth(1),
      1: const FlexColumnWidth(3),
      2: const FlexColumnWidth(1),
      3: const FlexColumnWidth(1),
    };
    if (widget.document["status"] == 'Admin') {
      columnWidths[4] = const FlexColumnWidth(1);
    }

    var firstRow = TableRow(
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
      ],
    );
    if (widget.document["status"] == 'Admin') {
      firstRow.children.add(
        const Padding(
          padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
          child: Text(
            '',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Table(
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        firstRow,
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

              var rowChildren = <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
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
                  padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${scorerData['name']}',
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
                  child: Text(
                    '${scorerData['points']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20.0),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
                  child: Text(
                    '${scorerData['goals']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20.0),
                  ),
                ),
              ];
              if (widget.document["status"] == 'Admin') {
                rowChildren.add(
                  PopupMenuButton(itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        value: 0,
                        child: ListTile(
                          title: const Text('Modifica'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showDialog(
                                scorerData['name'],
                                //scorerData['class'],
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
                  }),
                );
              }

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
            })
            .expand((element) => [element, spacer])
            .toList(),
      ],
    );
  }

  Widget _smallLayout(BuildContext context) {
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTable(scorers),
                  const SizedBox(height: 60.0),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton:
          widget.document['status'] == 'Admin' && bottomLevel == 'torneo'
              ? FloatingActionButton(
                  onPressed: () {
                    _showAddDialog();
                  },
                  child: Icon(Icons.add),
                  shape: CircleBorder(),
                  backgroundColor: Colors.white,
                )
              : null,
    );
  }

  Widget _largeLayout(BuildContext context) {
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
            return Center(
              child: Column(
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
              ),
            );
          }
          return Center(
            child: SizedBox(
              width: 500,
              height: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(child: _buildTable(scorers)),
              ),
            ),
          );
        },
      ),
      floatingActionButton:
          widget.document['status'] == 'Admin' && bottomLevel == 'torneo'
              ? FloatingActionButton(
                  onPressed: () {
                    _showAddDialog();
                  },
                  child: Icon(Icons.add),
                )
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      smallLayout: _smallLayout(context),
      largeLayout: _largeLayout(context),
    );
  }
}


//import 'package:adaptive_layout/adaptive_layout.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:flutter/material.dart';
//import 'package:flutter_speed_dial/flutter_speed_dial.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';
//import 'package:ms_undraw/ms_undraw.dart';
//
//class Counter extends StatelessWidget {
//  const Counter({
//    Key? key,
//    required this.title,
//    required this.onUp,
//    required this.onDown,
//    required this.getCount,
//  }) : super(key: key);
//
//  final String title;
//  final Function() onUp;
//  final Function() onDown;
//  final Function() getCount;
//
//  @override
//  Widget build(BuildContext context) {
//    return Row(
//      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//      children: [
//        ElevatedButton(
//          onPressed: () {
//            if (getCount() > 1) {
//              onDown();
//            }
//          },
//          child: const Icon(Icons.remove),
//        ),
//        const SizedBox(width: 10.0),
//        Column(
//          children: [
//            Text('${getCount()}',
//                style:
//                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//            Text(title),
//          ],
//        ),
//        const SizedBox(width: 10.0),
//        ElevatedButton(
//          onPressed: () {
//            onUp();
//          },
//          child: const Icon(Icons.add),
//        ),
//      ],
//    );
//  }
//}
//
//class TabScorer extends StatefulWidget {
//  const TabScorer({super.key, required this.document});
//
//  final Map document;
//
//  @override
//  _TabScorerState createState() => _TabScorerState();
//}
//
//class _TabScorerState extends State<TabScorer> {
//  late CollectionReference<Map<String, dynamic>> _scorerCollection;
//  late Stream<QuerySnapshot> _scorersStream;
//  String name = '';
//  String surname = '';
//  String bottomLevel = 'torneo';
//  int pointCount = 1;
//  int goalCount = 1;
//
//  @override
//  void initState() {
//    super.initState();
//    _scorerCollection = FirebaseFirestore.instance.collection('club_scorer');
//    _scorersStream = _scorerCollection
//        .orderBy('points', descending: true)
//        .orderBy('goals', descending: true)
//        .snapshots();
//  }
//
//  Future<void> _showAddDialog(String selectedClass) async {
//    return showDialog<void>(
//      context: context,
//      builder: (BuildContext context) {
//        return StatefulBuilder(
//          builder: (context, setState) {
//            return AlertDialog(
//              title: Text(selectedClass),
//              content: Column(
//                mainAxisSize: MainAxisSize.min,
//                children: [
//                  TextField(
//                    decoration: const InputDecoration(labelText: 'Name'),
//                    onChanged: (value) {
//                      setState(() {
//                        name = value;
//                      });
//                    },
//                  ),
//                  const SizedBox(height: 10.0),
//                  TextField(
//                    decoration: const InputDecoration(labelText: 'Surname'),
//                    onChanged: (value) {
//                      setState(() {
//                        surname = value;
//                      });
//                    },
//                  ),
//                  const SizedBox(height: 10.0),
//                  Counter(
//                    title: 'punti',
//                    onUp: () {
//                      setState(() {
//                        pointCount = pointCount + 1;
//                      });
//                    },
//                    onDown: () {
//                      setState(() {
//                        pointCount = pointCount - 1;
//                      });
//                    },
//                    getCount: () => pointCount,
//                  ),
//                  const SizedBox(height: 10.0),
//                  Counter(
//                    title: 'goal',
//                    onUp: () {
//                      setState(() {
//                        goalCount = goalCount + 1;
//                      });
//                    },
//                    onDown: () {
//                      setState(() {
//                        goalCount = goalCount - 1;
//                      });
//                    },
//                    getCount: () => goalCount,
//                  ),
//                ],
//              ),
//              actions: <Widget>[
//                TextButton(
//                  onPressed: () {
//                    Navigator.of(context).pop();
//                    pointCount = 1;
//                    goalCount = 1;
//                  },
//                  child: const Text('Annulla'),
//                ),
//                TextButton(
//                  onPressed: () async {
//                    if (name != "" && surname != "") {
//                      await FirebaseFirestore.instance
//                          .collection('club_scorer')
//                          .add({
//                        'name': name,
//                        'surname': surname,
//                        'class': selectedClass,
//                        'points': pointCount,
//                        'goals': goalCount,
//                      });
//                      pointCount = 1;
//                      goalCount = 1;
//                      Navigator.of(context).pop();
//                    } else if (name == "") {
//                      ScaffoldMessenger.of(context).showSnackBar(
//                          const SnackBar(content: Text('Inserisci il nome')));
//                    } else if (surname == "") {
//                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                          content: Text('Inserisci il cognome')));
//                    }
//                  },
//                  child: const Text('OK'),
//                ),
//              ],
//            );
//          },
//        );
//      },
//    );
//  }
//
//  Future<void> _showDialog(String name, String surname, String selectedClass,
//      int counter, int goal, String scorerId) async {
//    return showDialog<void>(
//      context: context,
//      builder: (BuildContext context) {
//        int localCounter = counter;
//        int goalCounter = goal;
//        return StatefulBuilder(
//          builder: (BuildContext context, StateSetter setState) {
//            return AlertDialog(
//              title: Text('$name $surname'),
//              content: Column(
//                mainAxisSize: MainAxisSize.min,
//                children: [
//                  Counter(
//                    title: 'punti',
//                    onUp: () {
//                      setState(() {
//                        localCounter++;
//                      });
//                    },
//                    onDown: () {
//                      if (localCounter > 1) {
//                        setState(() {
//                          localCounter--;
//                        });
//                      }
//                    },
//                    getCount: () => localCounter,
//                  ),
//                  const SizedBox(height: 10.0),
//                  Counter(
//                    title: 'goal',
//                    onUp: () {
//                      setState(() {
//                        goalCounter++;
//                      });
//                    },
//                    onDown: () {
//                      if (goalCounter > 1) {
//                        setState(() {
//                          goalCounter--;
//                        });
//                      }
//                    },
//                    getCount: () => goalCounter,
//                  ),
//                ],
//              ),
//              actions: <Widget>[
//                TextButton(
//                  onPressed: () {
//                    Navigator.of(context).pop();
//                  },
//                  child: const Text('Annulla'),
//                ),
//                TextButton(
//                  onPressed: () async {
//                    await _scorerCollection
//                        .doc(scorerId)
//                        .update({'points': localCounter, 'goals': goalCounter});
//                    Navigator.of(context).pop();
//                  },
//                  child: const Text('OK'),
//                ),
//              ],
//            );
//          },
//        );
//      },
//    );
//  }
//
//  Future<void> _deleteScorer(String scorerId) async {
//    final confirmDelete = await showDialog(
//      context: context,
//      builder: (BuildContext context) {
//        return AlertDialog(
//          title: const Text("Conferma"),
//          content: const Text("Sei sicuro di voler eliminare questo scorer?"),
//          actions: <Widget>[
//            ElevatedButton(
//              child: const Text("No"),
//              onPressed: () {
//                Navigator.of(context).pop(false);
//              },
//            ),
//            ElevatedButton(
//              child: const Text("Si"),
//              onPressed: () {
//                Navigator.of(context).pop(true);
//              },
//            ),
//          ],
//        );
//      },
//    );
//
//    if (confirmDelete) {
//      await _scorerCollection.doc(scorerId).delete();
//    }
//  }
//
//  Table _buildTable(List<QueryDocumentSnapshot> scorers) {
//    var spacerChildren = <Widget>[
//      const SizedBox(height: 8),
//      const SizedBox(height: 8),
//      const SizedBox(height: 8),
//      const SizedBox(height: 8),
//    ];
//    if (widget.document["status"] == 'Admin') {
//      spacerChildren.add(const SizedBox(height: 8));
//    }
//    TableRow spacer = TableRow(
//      children: spacerChildren,
//    );
//
//    var columnWidths = <int, TableColumnWidth>{
//      0: const FlexColumnWidth(1),
//      1: const FlexColumnWidth(3),
//      2: const FlexColumnWidth(1),
//      3: const FlexColumnWidth(1),
//    };
//    if (widget.document["status"] == 'Admin') {
//      columnWidths[4] = const FlexColumnWidth(1);
//    }
//
//    var firstRow = TableRow(
//      children: [
//        const Padding(
//          padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
//          child: Text(
//            '',
//            textAlign: TextAlign.center,
//            style: TextStyle(fontWeight: FontWeight.bold),
//          ),
//        ),
//        const Padding(
//          padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
//          child: Text(
//            'Nome',
//            textAlign: TextAlign.left,
//            style: TextStyle(fontWeight: FontWeight.bold),
//          ),
//        ),
//        const Padding(
//          padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
//          child: Text(
//            'Punti',
//            textAlign: TextAlign.center,
//            style: TextStyle(fontWeight: FontWeight.bold),
//          ),
//        ),
//        const Padding(
//          padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
//          child: Text(
//            'Goal',
//            textAlign: TextAlign.center,
//            style: TextStyle(fontWeight: FontWeight.bold),
//          ),
//        ),
//      ],
//    );
//    if (widget.document["status"] == 'Admin') {
//      firstRow.children.add(
//        const Padding(
//          padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
//          child: Text(
//            '',
//            textAlign: TextAlign.center,
//            style: TextStyle(fontWeight: FontWeight.bold),
//          ),
//        ),
//      );
//    }
//
//    return Table(
//      columnWidths: columnWidths,
//      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
//      children: [
//        firstRow,
//        spacer,
//        ...scorers
//            .asMap()
//            .entries
//            .map((entry) {
//              int index = entry.key;
//              QueryDocumentSnapshot scorer = entry.value;
//              Map<String, dynamic> scorerData =
//                  scorer.data() as Map<String, dynamic>;
//              String scorerId = scorer.id;
//
//              var rowChildren = <Widget>[
//                Padding(
//                  padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
//                  child: index == 0
//                      ? const Center(
//                          child: FaIcon(
//                            FontAwesomeIcons.medal,
//                            color: Colors.amber,
//                          ),
//                        )
//                      : index == 1
//                          ? const Center(
//                              child: FaIcon(
//                                FontAwesomeIcons.medal,
//                                color: Colors.grey,
//                              ),
//                            )
//                          : index == 2
//                              ? const Center(
//                                  child: FaIcon(
//                                    FontAwesomeIcons.medal,
//                                    color: Colors.brown,
//                                  ),
//                                )
//                              : Text(
//                                  '${index + 1}',
//                                  textAlign: TextAlign.center,
//                                  style: const TextStyle(
//                                      fontSize: 20,
//                                      fontWeight: FontWeight.bold),
//                                ),
//                ),
//                Padding(
//                  padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
//                  child: Column(
//                    crossAxisAlignment: CrossAxisAlignment.start,
//                    children: [
//                      Text(
//                        '${scorerData['name']} ${scorerData['surname']}',
//                        textAlign: TextAlign.left,
//                        style: const TextStyle(fontWeight: FontWeight.bold),
//                      ),
//                      Text(
//                        '${scorerData['class']}',
//                        textAlign: TextAlign.left,
//                      ),
//                    ],
//                  ),
//                ),
//                Padding(
//                  padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
//                  child: Text(
//                    '${scorerData['points']}',
//                    textAlign: TextAlign.center,
//                    style: const TextStyle(
//                        fontWeight: FontWeight.bold, fontSize: 20.0),
//                  ),
//                ),
//                Padding(
//                  padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
//                  child: Text(
//                    '${scorerData['goals']}',
//                    textAlign: TextAlign.center,
//                    style: const TextStyle(
//                        fontWeight: FontWeight.bold, fontSize: 20.0),
//                  ),
//                ),
//              ];
//              if (widget.document["status"] == 'Admin') {
//                rowChildren.add(
//                  PopupMenuButton(itemBuilder: (context) {
//                    return [
//                      PopupMenuItem(
//                        value: 0,
//                        child: ListTile(
//                          title: const Text('Modifica'),
//                          onTap: () {
//                            Navigator.of(context).pop();
//                            _showDialog(
//                                scorerData['name'],
//                                scorerData['surname'],
//                                scorerData['class'],
//                                scorerData['points'],
//                                scorerData['goals'],
//                                scorerId);
//                          },
//                        ),
//                      ),
//                      PopupMenuItem(
//                        value: 1,
//                        child: ListTile(
//                          title: const Text('Elimina'),
//                          onTap: () {
//                            Navigator.of(context).pop();
//                            _deleteScorer(scorerId);
//                          },
//                        ),
//                      ),
//                    ];
//                  }),
//                );
//              }
//
//              return TableRow(
//                decoration: BoxDecoration(
//                  color: Colors.white,
//                  boxShadow: [
//                    BoxShadow(
//                      color: Colors.grey.withOpacity(0.5),
//                      spreadRadius: 1,
//                      blurRadius: 1,
//                      offset: const Offset(0, 1),
//                    ),
//                  ],
//                  borderRadius: BorderRadius.circular(10.0),
//                ),
//                children: rowChildren,
//              );
//            })
//            .expand((element) => [element, spacer])
//            .toList(),
//      ],
//    );
//  }
//
//  Widget _smallLayout(BuildContext context) {
//    return Scaffold(
//      body: StreamBuilder<QuerySnapshot>(
//        stream: _scorersStream,
//        builder: (context, snapshot) {
//          if (snapshot.connectionState == ConnectionState.waiting) {
//            return const Center(child: CircularProgressIndicator());
//          }
//          if (snapshot.hasError) {
//            return Center(child: Text('Errore: ${snapshot.error}'));
//          }
//          List<QueryDocumentSnapshot> scorers = snapshot.data!.docs;
//          if (scorers.isEmpty) {
//            return Column(
//              mainAxisAlignment: MainAxisAlignment.center,
//              children: [
//                SizedBox(
//                  height: 200.0,
//                  child: UnDraw(
//                    illustration: UnDrawIllustration.junior_soccer,
//                    placeholder: const SizedBox(
//                      height: 200.0,
//                      width: 200.0,
//                    ),
//                    color: Theme.of(context).primaryColor,
//                  ),
//                ),
//                const Text(
//                  'Non ci sono giocatori registrati',
//                  style: TextStyle(fontSize: 20.0, color: Colors.black54),
//                ),
//              ],
//            );
//          }
//          return Padding(
//            padding: const EdgeInsets.all(8.0),
//            child: SingleChildScrollView(
//              child: Column(
//                children: [
//                  _buildTable(scorers),
//                  const SizedBox(height: 60.0),
//                ],
//              ),
//            ),
//          );
//        },
//      ),
//      floatingActionButton:
//          widget.document['status'] == 'Admin' && bottomLevel == 'torneo'
//              ? SpeedDial(
//                  icon: Icons.add,
//                  activeIcon: Icons.close,
//                  backgroundColor: Colors.white,
//                  foregroundColor: Colors.black,
//                  children: [
//                    SpeedDialChild(
//                      child: const Text("1°"),
//                      onTap: () {
//                        _showAddDialog("1° liceo");
//                      },
//                    ),
//                    SpeedDialChild(
//                      child: const Text("2°"),
//                      onTap: () {
//                        _showAddDialog("2° liceo");
//                      },
//                    ),
//                    SpeedDialChild(
//                      child: const Text("3°"),
//                      onTap: () {
//                        _showAddDialog("3° liceo");
//                      },
//                    ),
//                    SpeedDialChild(
//                      child: const Text("4°"),
//                      onTap: () {
//                        _showAddDialog("4° liceo");
//                      },
//                    ),
//                    SpeedDialChild(
//                      child: const Text("5°"),
//                      onTap: () {
//                        _showAddDialog("5° liceo");
//                      },
//                    ),
//                  ],
//                  child: const Icon(Icons.add),
//                )
//              : null,
//    );
//  }
//
//  Widget _largeLayout(BuildContext context) {
//    return Scaffold(
//      body: StreamBuilder<QuerySnapshot>(
//        stream: _scorersStream,
//        builder: (context, snapshot) {
//          if (snapshot.connectionState == ConnectionState.waiting) {
//            return const Center(child: CircularProgressIndicator());
//          }
//          if (snapshot.hasError) {
//            return Center(child: Text('Errore: ${snapshot.error}'));
//          }
//          List<QueryDocumentSnapshot> scorers = snapshot.data!.docs;
//          if (scorers.isEmpty) {
//            return Center(
//              child: Column(
//                mainAxisAlignment: MainAxisAlignment.center,
//                children: [
//                  SizedBox(
//                    height: 200.0,
//                    child: UnDraw(
//                      illustration: UnDrawIllustration.junior_soccer,
//                      placeholder: const SizedBox(
//                        height: 200.0,
//                        width: 200.0,
//                      ),
//                      color: Theme.of(context).primaryColor,
//                    ),
//                  ),
//                  const Text(
//                    'Non ci sono giocatori registrati',
//                    style: TextStyle(fontSize: 20.0, color: Colors.black54),
//                  ),
//                ],
//              ),
//            );
//          }
//          return Center(
//            child: SizedBox(
//              width: 500,
//              height: double.infinity,
//              child: Padding(
//                padding: const EdgeInsets.all(8.0),
//                child: SingleChildScrollView(child: _buildTable(scorers)),
//              ),
//            ),
//          );
//        },
//      ),
//      floatingActionButton:
//          widget.document['status'] == 'Admin' && bottomLevel == 'torneo'
//              ? SpeedDial(
//                  icon: Icons.add,
//                  activeIcon: Icons.close,
//                  backgroundColor: Colors.white,
//                  foregroundColor: Colors.black,
//                  children: [
//                    SpeedDialChild(
//                      child: const Text("1°"),
//                      onTap: () {
//                        _showAddDialog("1° liceo");
//                      },
//                    ),
//                    SpeedDialChild(
//                      child: const Text("2°"),
//                      onTap: () {
//                        _showAddDialog("2° liceo");
//                      },
//                    ),
//                    SpeedDialChild(
//                      child: const Text("3°"),
//                      onTap: () {
//                        _showAddDialog("3° liceo");
//                      },
//                    ),
//                    SpeedDialChild(
//                      child: const Text("4°"),
//                      onTap: () {
//                        _showAddDialog("4° liceo");
//                      },
//                    ),
//                    SpeedDialChild(
//                      child: const Text("5°"),
//                      onTap: () {
//                        _showAddDialog("5° liceo");
//                      },
//                    ),
//                  ],
//                  child: const Icon(Icons.add),
//                )
//              : null,
//    );
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return AdaptiveLayout(
//      smallLayout: _smallLayout(context),
//      largeLayout: _largeLayout(context),
//    );
//  }
//}
//