import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:club/config.dart';

class TabScorer extends StatefulWidget {
  const TabScorer({super.key, required this.document});

  //final String email;
  //final String status;
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
  int goalCount = 1;

  @override
  void initState() {
    super.initState();
    _scorerCollection = FirebaseFirestore.instance.collection('club_scorer');
    _scorersStream =
        _scorerCollection.orderBy('goal', descending: true).snapshots();

    sendNotification(
        'f1QP4F2hQ4G8c21NnliqST:APA91bHb5beI32WGr-Olb95hDitqSy06FL0yfhf0VR5Xism6pIcem2tzLEMHOju57sUXcU3S7VYKI5tL1kHOWsjJpEdpv7GkeSu2YnRTXrX-IxlFNkp0D1Iy4S7gVL73ahODo0n0oXpI');
  }

  Future<void> sendNotification(String fcmToken) async {
    final String serverKey = Config.serverKey;
    final String fcmUrl = 'https://fcm.googleapis.com/fcm/send';
    Uri uri = Uri.parse(fcmUrl);

    final Map<String, dynamic> notification = {
      'title': 'Nuovo aggiornamento torneo',
      'body': 'Scopri le ultime novità nel torneo!',
    };

    final Map<String, dynamic> data = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': '1',
      'status': 'done',
    };

    final Map<String, dynamic> body = {
      'to': fcmToken,
      'notification': notification,
      'data': data,
    };

    final http.Response response = await http.post(
      uri,
      body: jsonEncode(body),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
    );

    if (response.statusCode == 200) {
      print('Notifica inviata con successo!');
    } else {
      print('Errore nell\'invio della notifica: ${response.reasonPhrase}');
    }
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
                        'goal': goalCount,
                      });
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
      int counter, String scorerId) async {
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
                      'Class: ${scorerData['class']}, Goals: ${scorerData['goal']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      widget.document["status"] == 'Admin'
                          ? IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showDialog(
                                    scorerData['name'],
                                    scorerData['surname'],
                                    scorerData['class'],
                                    scorerData['goal'],
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
            },
          );
        },
      ),
      floatingActionButton:
          widget.document['status'] == 'Admin' && bottomLevel == 'torneo'
              ? SpeedDial(
                  children: [
                    SpeedDialChild(
                      child: const Text("1°"),
                      onTap: () {
                        _showAddDialog("1° media");
                      },
                    ),
                    SpeedDialChild(
                      child: const Text("2°"),
                      onTap: () {
                        _showAddDialog("2° media");
                      },
                    ),
                    SpeedDialChild(
                      child: const Text("3°"),
                      onTap: () {
                        _showAddDialog("3° media");
                      },
                    ),
                  ],
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }
}
