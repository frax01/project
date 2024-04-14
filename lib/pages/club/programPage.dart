import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:club/functions/generalFunctions.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'addEditProgram.dart';

class ProgramPage extends StatefulWidget {
  const ProgramPage({
    Key? key,
    required this.document,
    required this.weather,
    required this.isAdmin,
  }) : super(key: key);

  final Map document;
  final Map weather;
  final bool isAdmin;

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  Future<void> _showDeleteDialog(BuildContext context, String id) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Elimina'),
          content: const Text('Sei sicuro di voler eliminare questo evento?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  deleteDocument(
                      'club_${widget.document["selectedOption"]}', id);
                });
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
  }

  Widget weatherTile(Map weather) {
    if (weather["check"] == "true" || weather["check"]) {
      return Row(
        children: [
          Image.network(weather["image"], width: 50, height: 50),
          const SizedBox(width: 10),
          Column(
            children: [
              Text('${weather["t_max"]}ºC',
                  style: const TextStyle(color: Colors.red)),
              Text('${weather["t_min"]}ºC',
                  style: const TextStyle(color: Colors.blue)),
            ],
          ),
        ],
      );
    } else {
      return const ListTile(
        title:
            Text('Nessuna informazione\nmeteo', style: TextStyle(fontSize: 15)),
      );
    }
  }

  Widget details(document, weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
                child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: List<Widget>.generate(
                      document['selectedClass'].length, (index) {
                String classValue = document['selectedClass'][index].toString();
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(classValue),
                  ),
                );
              })),
            )),
            const SizedBox(width: 15),
            Chip(
              label: Text(
                document['endDate'].isNotEmpty
                    ? '${convertDateFormat(document['startDate'])} ~ ${convertDateFormat(document['endDate'])}'
                    : convertDateFormat(document['startDate']),
              ),
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 5,
              ),
              backgroundColor: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        Card(
            surfaceTintColor: Colors.white,
            elevation: 5,
            margin: const EdgeInsets.all(0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dove',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          document['address'],
                          style: const TextStyle(fontSize: 15),
                        ),
                        //const SizedBox(height: 15),
                        //Text(
                        //  document['endDate'].isNotEmpty
                        //      ? '${convertDateFormat(document['startDate'])} ~ ${convertDateFormat(document['endDate'])}'
                        //      : '${convertDateFormat(document['startDate'])}',
                        //),
                      ]),
                  weatherTile(weather),
                ],
              ),
            )),
        const SizedBox(height: 20.0),
        Card(
          surfaceTintColor: Colors.white,
          elevation: 5,
          margin: const EdgeInsets.all(0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Descrizione',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  document['description'],
                  style: const TextStyle(fontSize: 17),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget smallScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 5,
                  child: Image.network(
                    widget.document['imagePath'],
                  ),
                ),
                Positioned(
                    bottom: -25,
                    left: 15,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 7,
                            offset: const Offset(
                                0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        child: Text(
                          widget.document['title'],
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 30.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: details(widget.document, widget.weather),
            ),
          ],
        ),
      ),
    );
  }

  Widget bigScreen() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    height: double.infinity,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 5,
                      child: Image.network(
                        widget.document['imagePath'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    right: -15,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            spreadRadius: 2,
                            blurRadius: 15,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        child: Text(
                          widget.document['title'],
                          style: const TextStyle(
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              // flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(60, 20, 20, 20),
                child: details(widget.document, widget.weather),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.document['selectedOption'] == 'weekend'
            ? const Text('Sabato')
            : widget.document['selectedOption'] == 'trip'
                ? const Text('Viaggio')
                : const Text('Extra'),
        actions: [
          IconButton(
            onPressed: () {
              Share.share('Guarda questo evento nel Tiber!\n\n'
                  'Titolo: ${widget.document['title']}\n'
                  'Indirizzo: ${widget.document['address']}\n'
                  'Data: ${widget.document['startDate']} ~ ${widget.document['endDate']}\n'
                  'Descrizione: ${widget.document['description']}\n');
            },
            icon: const Icon(
              Icons.share,
            ),
          ),
          widget.isAdmin
              ? PopupMenuButton(itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      child: const Text('Modifica'),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => AddEditProgram(
                                  selectedOption:
                                      widget.document['selectedOption'],
                                  document: widget.document,
                                )));
                      },
                    ),
                    PopupMenuItem(
                        child: const Text('Elimina'),
                        onTap: () {
                          _showDeleteDialog(context, widget.document['id']);
                        }),
                  ];
                })
              : const SizedBox.shrink(),
        ],
      ),
      body: AdaptiveLayout(
        smallLayout: smallScreen(),
        largeLayout: bigScreen(),
      ),
    );
  }
}
