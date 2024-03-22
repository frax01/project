import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/functions/generalFunctions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'club.dart';
import '../../functions/geoFunctions.dart';
import '../../functions/notificationFunctions.dart';
import '../../functions/weatherFunctions.dart';

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
  String? title = '';
  String? startDate = '';
  String? imagePath = '';
  String? description = '';
  bool imageUploaded = false;
  bool startDateUploaded = false;
  bool endDateUploaded = false;

  Future<String> _startDate(BuildContext context, String startDate,
      {bool isCreate = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != DateTime.now()) {
      startDate = DateFormat('dd-MM-yyyy').format(picked);
    }
    isCreate ? startDateUploaded = true : null;
    return startDate;
  }

  Future<String> _endDate(
      BuildContext context, String startDate, String endDate,
      {bool isCreate = false}) async {
    if (startDate == "") {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inserisci prima la data iniziale')));
      return '';
    } else {
      DateFormat inputFormat = DateFormat('dd-MM-yyyy');
      DateTime date = inputFormat.parse(startDate);
      DateFormat outputFormat = DateFormat('yyyy-MM-dd');
      String formattedStartDate = outputFormat.format(date);
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.parse(formattedStartDate),
        firstDate: DateTime.parse(formattedStartDate),
        lastDate:
            DateTime.parse(formattedStartDate).add(const Duration(days: 365)),
      );
      if (picked != null && picked != DateTime.now()) {
        endDate = DateFormat('dd-MM-yyyy').format(picked);
      }
    }
    isCreate ? endDateUploaded = true : null;
    return endDate;
  }

  Future<String> uploadImage(String level, {bool isCreate = false}) async {
    final storageRef = FirebaseStorage.instance.ref();
    final imagesRef =
        storageRef.child('$level/${DateTime.now().toIso8601String()}.jpeg');

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    final UploadTask uploadTask = imagesRef.putData(await image!.readAsBytes());
    final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
    final String imageUrl = await snapshot.ref.getDownloadURL();

    isCreate ? imageUploaded = true : null;
    return imageUrl;
  }

  Future<void> _showEditDialog(BuildContext context, String level,
      Map<dynamic, dynamic> data, String section, String id) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    titleController.text = data['title'];
    descriptionController.text = data['description'];

    String newTitle = data['title'];
    String imagePath = data['imagePath'];
    String selectedClass = data['selectedClass'];
    String selectedOption = data['selectedOption'];
    String description = data['description'];
    String startDate = data['startDate'] ?? '';
    String endDate = data['endDate'] ?? '';
    String address = data['address'];
    String lat = data['lat'];
    String lon = data['lon'];

    String selectedAddr = "";
    String? selectedCitta = "";
    String selectedStato = "";
    String? selectedNum = "";

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(level),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: titleController,
                    onChanged: (value) {
                      newTitle = value;
                    },
                    decoration: const InputDecoration(labelText: 'Titolo'),
                  ),
                  const SizedBox(height: 16.0),
                  TypeAheadField(
                    builder: (context, controller, focusNode) {
                      String label = address;
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: false,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: label,
                        ),
                        validator: (value) {
                          if (selectedOption == 'trip' &&
                              (value == null || value.isEmpty)) {
                            return 'Inserire un indirizzo';
                          }
                          return null;
                        },
                      );
                    },
                    suggestionsCallback: (pattern) async {
                      if (pattern == '') {
                        return [];
                      } else {
                        return await getSuggestions(pattern);
                      }
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion["display_name"]),
                      );
                    },
                    onSelected: (suggestion) {
                      setState(() {
                        selectedAddr = suggestion["address"]["name"];
                        selectedCitta = suggestion["address"]["city"] ?? '';
                        selectedStato = suggestion["address"]["country"];
                        selectedNum =
                            suggestion["address"]["house_number"] ?? '';
                        lat = suggestion["lat"];
                        lon = suggestion["lon"];
                        if (selectedCitta != '' && selectedNum != '') {
                          if (selectedStato != 'Italia') {
                            address =
                                '$selectedAddr, ${selectedNum ?? ''}, ${selectedCitta ?? ''}, $selectedStato';
                          } else {
                            address =
                                '$selectedAddr, ${selectedNum ?? ''}, ${selectedCitta ?? ''}';
                          }
                        } else {
                          if (selectedStato != 'Italia') {
                            address = '$selectedAddr, $selectedStato';
                          } else {
                            address = selectedAddr;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    value: data['selectedClass'],
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value!;
                      });
                    },
                    items: [
                      '',
                      '1° liceo',
                      '2° liceo',
                      '3° liceo',
                      '4° liceo',
                      '5° liceo'
                    ].map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    hint: const Text('Seleziona un\'opzione'),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () async {
                      String imageUrl = await uploadImage(section);
                      setState(() {
                        imagePath = imageUrl;
                      });
                    },
                    child: const Text(
                        'Cambia immagine'), //mostrare una barra di caricamento
                  ),
                  const SizedBox(height: 16.0),
                  ...(section == 'weekend' || section == 'extra')
                      ? [
                          ElevatedButton(
                            onPressed: () async {
                              startDate =
                                  await _startDate(context, data['startDate']);
                              setState(() {});
                            },
                            child: Text(startDate),
                          ),
                        ]
                      : (section == 'trip' || section == 'tournament')
                          ? [
                              ElevatedButton(
                                onPressed: () async {
                                  String newDate = await _startDate(
                                      context, data['startDate']);
                                  setState(() {
                                    startDate = newDate;
                                  });
                                },
                                child: Text(startDate),
                              ),
                              const SizedBox(height: 16.0),
                              ElevatedButton(
                                onPressed: () async {
                                  String newDate = await _endDate(context,
                                      data['startDate'], data['endDate']);
                                  setState(() {
                                    endDate = newDate;
                                  });
                                },
                                child: Text(endDate),
                              ),
                            ]
                          : [],
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: descriptionController,
                    onChanged: (value) {
                      description = value;
                    },
                    decoration: const InputDecoration(labelText: 'Testo'),
                    maxLines: null,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () async {
                      await updateClubDetails(
                          id,
                          newTitle,
                          imagePath,
                          selectedClass,
                          startDate,
                          endDate,
                          description,
                          section,
                          address,
                          lat,
                          lon);
                    },
                    child: const Text('Modifica'),
                  ),
                ]),
              );
            },
          );
        });
  }

  Future<void> updateClubDetails(
      String id,
      String newTitle,
      String imagePath,
      String selectedClass,
      String startDate,
      String endDate,
      String description,
      String section,
      String indirizzo,
      String selectedLat,
      String selectedLon) async {
    try {
      if (newTitle == "") {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Inserisci un titolo')));
        return;
      }
      if (selectedClass == "") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inserisci una classe')));
        return;
      }

      Map weather =
          await fetchWeatherData(startDate, endDate, selectedLat, selectedLon);

      Map document = {
        'title': newTitle,
        'imagePath': imagePath,
        'selectedClass': selectedClass,
        'selectedOption': section,
        'description': description,
        'startDate': startDate,
        'endDate': endDate,
        'address': indirizzo,
        'lat': selectedLat,
        'lon': selectedLon,
      };

      await FirebaseFirestore.instance
          .collection('club_$section')
          .doc(id)
          .update({
        'title': newTitle,
        'imagePath': imagePath,
        'selectedClass': selectedClass,
        'selectedOption': section,
        'description': description,
        'startDate': startDate,
        'endDate': endDate,
        'address': indirizzo,
        'lat': selectedLat,
        'lon': selectedLon,
      });
      Navigator.pop(context);
      List<String> token = await fetchToken('club_class', selectedClass);
      sendNotification(token, 'Programma modificato!', newTitle,
          'modified_event', document, weather);
    } catch (e) {
      print('Errore aggiornamento utente: $e');
    }
  }

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
              Text('${weather["t_max"]}ºC'),
              Text('${weather["t_min"]}ºC'),
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
            Chip(
              label: Text(document['selectedOption'].toString().toUpperCase()),
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 7,
              ),
            ),
            const SizedBox(width: 10),
            Chip(
              label: Text(document['selectedClass'].toString().toUpperCase()),
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 7,
              ),
            ),
            const SizedBox(width: 10),
            Chip(
              label: Text(
                document['endDate'].isNotEmpty
                    ? '${document['startDate']} ~ ${document['endDate']}'
                    : document['startDate'],
              ),
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 7,
              ),
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
            child: SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      document['address'],
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  weatherTile(weather),
                ],
              ),
            ),
          ),
        ),
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
                const SizedBox(width: 15),
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
        //leading: IconButton(
        //  onPressed: () {
        //    aggiornaPagina();
        //    Navigator.pop(context);
        //  },
        //  icon: Icon(Icons.arrow_back),
        //),
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
                        _showEditDialog(
                            context,
                            'Modifica',
                            widget.document,
                            widget.document['selectedOption'],
                            widget.document['id']);
                      },
                    ),
                    PopupMenuItem(
                        child: Text('Elimina'),
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
