import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
              child: const Text("NO"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text("YES"),
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

  List<Widget> _buildList(List<QueryDocumentSnapshot> scorers) {
    var i = 0;
    return scorers.map((scorer) {
      Map<String, dynamic> scorerData = scorer.data() as Map<String, dynamic>;
      String scorerId = scorer.id;
      ++i;
      return Card(
        elevation: 5.0,
        surfaceTintColor: Colors.white,
        child: ListTile(
          titleAlignment: ListTileTitleAlignment.center,
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              i == 1
                  ? const FaIcon(
                      FontAwesomeIcons.medal,
                      color: Colors.amber,
                    )
                  : i == 2
                      ? const FaIcon(
                          FontAwesomeIcons.medal,
                          color: Colors.grey,
                        )
                      : i == 3
                          ? const FaIcon(
                              FontAwesomeIcons.medal,
                              color: Colors.brown,
                            )
                          : Text('$i',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          title: Text('${scorerData['name']} ${scorerData['surname']}'),
          subtitle: Text(scorerData['class']),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${scorerData['points']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20.0),
                  ),
                  const SizedBox(width: 2.0),
                  const Icon(Icons.star, color: Colors.amber, size: 25.0)
                ],
              ),
              const SizedBox(width: 8.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${scorerData['goals']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20.0),
                  ),
                  const SizedBox(width: 2.0),
                  const Icon(Icons.sports_soccer,
                      color: Colors.green, size: 25.0)
                ],
              ),
              const SizedBox(width: 8.0),
              widget.document["status"] == 'Admin'
                  ? IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showDialog(
                            scorerData['name'],
                            scorerData['surname'],
                            scorerData['class'],
                            scorerData['points'],
                            scorerData['goals'],
                            scorerId);
                      },
                    )
                  : Container(),
              widget.document["status"] == 'Admin'
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _deleteScorer(scorerId);
                      },
                    )
                  : Container(),
            ],
          ),
        ),
      );
    }).toList();
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
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                forceElevated: true,
                expandedHeight: 250.0,
                automaticallyImplyLeading: false,
                centerTitle: true,
                pinned: true,
                floating: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text("11 ideale",
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  centerTitle: true,
                  expandedTitleScale: 3.0,
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.fadeTitle,
                  ],
                  background: Image.asset(
                    'images/CC.jpeg',
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.5),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  _buildList(scorers),
                ),
              ),
            ],
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
