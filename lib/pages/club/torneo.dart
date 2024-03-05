import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TabScorer extends StatefulWidget {
  const TabScorer({super.key, required this.email, required this.status});

  final String email;
  final String status;

  @override
  _TabScorerState createState() => _TabScorerState();
}

class _TabScorerState extends State<TabScorer> {

  late CollectionReference<Map<String, dynamic>> _scorerCollection;
  late Stream<QuerySnapshot> _scorersStream;
  String name = '';
  String surname = '';
  String selectedTeam = 'beginner';
  int goalCount = 1;

  @override
  void initState() {
    super.initState();
    _scorerCollection = FirebaseFirestore.instance.collection('football_scorer');
    _scorersStream = _scorerCollection.orderBy('goal', descending: true).snapshots();
  }

  Future<void> _showAddDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Aggiungi Scorer'),
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
                  DropdownButton<String>(
                    value: selectedTeam,
                    onChanged: (value) {
                      setState(() {
                        selectedTeam = value!;
                      });
                    },
                    items: ['beginner', 'intermediate', 'advanced']
                        .map<DropdownMenuItem<String>>((String team) {
                      return DropdownMenuItem<String>(
                        value: team,
                        child: Text(team),
                      );
                    }).toList(),
                  ),
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
                  },
                  child: const Text('Annulla'),
                ),
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('football_scorer')
                        .add({
                      'name': name,
                      'surname': surname,
                      'team': selectedTeam,
                      'goal': goalCount,
                    });
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

  Future<void> _showDialog(String name, String surname, String selectedTeam, int counter, String scorerId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        int localCounter = counter;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Modifica Scorer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Name: $name'),
                  Text('Surname: $surname'),
                  Text('Team: $selectedTeam'),
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
                        .update({'goal': localCounter});
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

          return ListView.builder(
            itemCount: scorers.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> scorerData =
                  scorers[index].data() as Map<String, dynamic>;
              String scorerId = scorers[index].id;

              return Card(
                child: ListTile(
                  title: Text('${scorerData['name']} ${scorerData['surname']}'),
                  subtitle: Text(
                      'Team: ${scorerData['team']}, Goals: ${scorerData['goal']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      widget.status == 'Admin'
                      ? IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showDialog(scorerData['name'], scorerData['surname'], scorerData['team'], scorerData['goal'], scorerId);
                          },
                        )
                      : Container(),
                      widget.status == 'Admin'
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
            },
          );
        },
      ),
      floatingActionButton: widget.status == 'Admin'
      ? FloatingActionButton(
          onPressed: () {
            _showAddDialog();
          },
          child: const Icon(Icons.add),
        )
      : null,
    );
  }
}
