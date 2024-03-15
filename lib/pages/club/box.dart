import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:club/functions/notificationFunctions.dart';
import 'program.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:club/functions/geoFunctions.dart';
import 'package:club/functions/dataFunctions.dart';
import 'package:club/functions/weatherFunctions.dart';
import 'package:club/functions/generalFunctions.dart';

class Box extends StatefulWidget {
  const Box({
    super.key,
    required this.selectedClass,
    required this.section,
  });

  final String selectedClass;
  final String section;

  @override
  State<Box> createState() => _BoxState();
}

class _BoxState extends State<Box> {
  String? title;
  String? startDate;
  String? imagePath;
  String? description;

  Future<String> _startDate(BuildContext context, String startDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != DateTime.now()) {
      startDate = DateFormat('dd-MM-yyyy').format(picked);
    }
    return startDate;
  }

  Future<String> _endDate(
      BuildContext context, String startDate, String endDate) async {
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
    return endDate;
  }

  Future<void> _showEditDialog(String level, Map<dynamic, dynamic> data,
      String section, String id) async {
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
      if (title == "") {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Inserisci un titolo')));
        return;
      }
      if (selectedClass == "") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inserisci una classe')));
        return;
      }

      Map weather = await fetchWeatherData(startDate, endDate, selectedLat, selectedLon);

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
          .collection('${widget.section}_$section')
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
      List<String> token = await fetchToken('club_class', selectedClass);
      print(token);
      sendNotification(token, 'Programma modificato!', newTitle,
          'modified_event', document, weather);
      Navigator.pop(context);
    } catch (e) {
      print('Errore aggiornamento utente: $e');
    }
  }

  Future<String> uploadImage(String level) async {
    final storageRef = FirebaseStorage.instance.ref();
    final imagesRef =
        storageRef.child('$level/${DateTime.now().toIso8601String()}.jpeg');

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    final UploadTask uploadTask = imagesRef.putData(await image!.readAsBytes());
    final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
    final String imageUrl = await snapshot.ref.getDownloadURL();

    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchData([], widget.selectedClass),
      builder: (BuildContext context,
          AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else {
          if (snapshot.hasData) {
            List<Map<String, dynamic>> allDocuments = snapshot.data!;
            allDocuments.sort((a, b) =>
                (a['startDate'] as String).compareTo(b['startDate'] as String));
            return ListView.builder(
              itemCount: allDocuments.length,
              itemBuilder: (context, index) {
                var document = allDocuments[index];
                var id = document['id'];
                var title = document['title'];
                var level = document['selectedOption'];
                var startDate = document['startDate'];
                var endDate = document['endDate'];
                var imagePath = document['imagePath'];
                var description = document['description'];
                var address = document['address'];
                var lat = document["lat"];
                var lon = document["lon"];
                return FutureBuilder(
                  future: fetchWeatherData(startDate, endDate, lat, lon),
                  builder: (BuildContext context,
                      AsyncSnapshot<Map> weatherSnapshot) {
                    if (weatherSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Container();
                    } else {
                      Map? weather = weatherSnapshot.data;
                      return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProgramScreen(
                                      document: document, weather: weather)),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.all(10.0),
                            padding: const EdgeInsets.all(15.0),
                            decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Titolo: $title',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text('Data iniziale: $startDate'),
                                      Text('Classe: ${widget.selectedClass}'),
                                      Text('Categoria: $level'),
                                      if (document['endDate'] != '')
                                        Text(
                                            'Data finale: ${document['endDate']}'),
                                      Image(
                                        image: NetworkImage(imagePath),
                                        height: 100,
                                        width: 100,
                                      ),
                                      Text('Descrizione: $description'),
                                      Text('Dove: $address'),
                                      weather!["check"]
                                          ? Text(
                                              'Temp min: ${weather["t_min"]}')
                                          : Container(),
                                      weather["check"]
                                          ? Text(
                                              'Temp max: ${weather["t_max"]}')
                                          : Container(),
                                      if (weather["image"] == null ||
                                          weather["image"] == '')
                                        Container()
                                      else
                                        Image(
                                          image: NetworkImage(weather["image"]),
                                          height: 30,
                                          width: 30,
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        Map<dynamic, dynamic> data = {};
                                        data = await loadBoxData(id, level, widget.section);
                                        _showEditDialog(data["selectedOption"],
                                            data, level, id);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        bool? shouldDelete = await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Elimina'),
                                              content: const Text(
                                                  'Sei sicuro di voler eliminare il programma?'),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: const Text('No'),
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(false);
                                                  },
                                                ),
                                                TextButton(
                                                  child: const Text('Si'),
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(true);
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        if (shouldDelete == true) {
                                          setState(() {
                                            deleteDocument(
                                                '${widget.section}_$level', id);
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ));
                    }
                  },
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text('Errore: ${snapshot.error}');
          } else {
            return const Text('Nessun dato disponibile');
          }
        }
      },
    );
  }
}