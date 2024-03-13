import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:club/functions.dart';
import 'program.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

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
  List<Map<String, dynamic>> allDocuments = [];
  String? title;
  String? startDate;
  String? imagePath;
  String? description;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map> _fetchWeatherData(startDate, endDate, lat, lon) async {
    Map<String, dynamic> weather = {};
    int weatherCode = 0;
    int temperatureMin = 0;
    int temperatureMax = 0;

    DateFormat inputFormat = DateFormat("dd-MM-yyyy");
    DateFormat outputFormat = DateFormat("yyyy-MM-dd");

    DateTime startInputDate = inputFormat.parse(startDate);
    String startOutputDate = outputFormat.format(startInputDate);

    DateTime today = DateTime.now();
    String todayOutputFormat = outputFormat.format(today);

    Duration startDifference = startInputDate.difference(today);
    int startDaysDifference = startDifference.inDays;

    if (startDaysDifference >= 16) {
      return {
        "t_min": '',
        "t_max": '',
        "w_code": '',
        "image": '',
        "check": false,
      };
    } else if (endDate != '' &&
        (startInputDate.isBefore(today) || startInputDate == today) &&
        (today.isBefore(DateFormat('dd-MM-yyyy').parse(endDate)) ||
            DateFormat('dd-MM-yyyy').parse(endDate) == today)) {
      final response = await http.get(
        Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Europe%2FRome&start_date=$todayOutputFormat&end_date=$todayOutputFormat'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        weatherCode = data['daily']['weather_code'][0];
        temperatureMin = (data['daily']['temperature_2m_min'][0] < 0)
            ? data['daily']['temperature_2m_min'][0].ceil()
            : data['daily']['temperature_2m_min'][0].floor();
        temperatureMax = (data['daily']['temperature_2m_max'][0] < 0)
            ? data['daily']['temperature_2m_max'][0].ceil()
            : data['daily']['temperature_2m_max'][0].floor();
      } else {
        throw Exception('Failed to fetch weather data');
      }
      Reference ref =
          FirebaseStorage.instance.ref().child('Weather/$weatherCode.png');
      String weatherImageUrl = await ref.getDownloadURL();
      weather = {
        "t_min": temperatureMin,
        "t_max": temperatureMax,
        "w_code": weatherCode,
        "image": weatherImageUrl,
        "check": true,
      };
      return weather;
    } else if (endDate != '') {
      List tMin = [];
      List tMax = [];

      DateTime endInputDate = inputFormat.parse(endDate);
      Duration endDifference = endInputDate.difference(today);
      int endDaysDifference = endDifference.inDays;
      String endOutputDate = '';

      if (endDaysDifference >= 16) {
        DateTime endInputDate = today.add(const Duration(days: 15));
        endOutputDate = outputFormat.format(endInputDate);
      } else {
        DateTime endInputdDate = inputFormat.parse(endDate);
        endOutputDate = outputFormat.format(endInputdDate);
      }
      final response = await http.get(
        Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Europe%2FRome&start_date=$startOutputDate&end_date=$endOutputDate'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        tMin = data['daily']['temperature_2m_min'];
        tMax = data['daily']['temperature_2m_max'];

        double sum = 0;
        for (double value in tMin) {
          sum += value;
        }
        temperatureMin = ((sum / tMin.length) < 0)
            ? (sum / tMin.length).ceil()
            : (sum / tMin.length).floor();

        sum = 0;
        for (double value in tMax) {
          sum += value;
        }
        temperatureMax = ((sum / tMax.length) < 0)
            ? (sum / tMax.length).ceil()
            : (sum / tMax.length).floor();
      } else {
        throw Exception('Failed to fetch weather data');
      }
      weather = {
        "t_min": temperatureMin,
        "t_max": temperatureMax,
        "w_code": '',
        "image": '',
        "check": true,
      };
      return weather;
    } else {
      final response = await http.get(
        Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Europe%2FRome&start_date=$startOutputDate&end_date=$startOutputDate'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        weatherCode = data['daily']['weather_code'][0];
        temperatureMin = (data['daily']['temperature_2m_min'][0] < 0)
            ? data['daily']['temperature_2m_min'][0].ceil()
            : data['daily']['temperature_2m_min'][0].floor();
        temperatureMax = (data['daily']['temperature_2m_max'][0] < 0)
            ? data['daily']['temperature_2m_max'][0].ceil()
            : data['daily']['temperature_2m_max'][0].floor();
      } else {
        throw Exception('Failed to fetch weather data');
      }
      Reference ref =
          FirebaseStorage.instance.ref().child('Weather/$weatherCode.png');
      String weatherImageUrl = await ref.getDownloadURL();
      weather = {
        "t_min": temperatureMin,
        "t_max": temperatureMax,
        "w_code": weatherCode,
        "image": weatherImageUrl,
        "check": true,
      };
      return weather;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchData() async {
    allDocuments = [];
    List<String> clubCollections = ['club_weekend', 'club_trip', 'club_extra'];

    for (String collectionName in clubCollections) {
      CollectionReference collection =
          FirebaseFirestore.instance.collection(collectionName);

      QuerySnapshot querySnapshot = await collection
          .where('selectedClass', isEqualTo: widget.selectedClass)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> documents = querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();

        allDocuments.addAll(documents);
      }
    }

    return allDocuments;
  }

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

  Future<Map> loadBoxData(String id, String level) async {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('${widget.section}_$level')
        .doc(id)
        .get();

    Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;

    return data;
  }

  Future<void> deleteDocument(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
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
                        selectedNum = suggestion["address"]["house_number"] ?? '';
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
      sendNotification(
          token, 'Programma modificato!', newTitle, 'modified_event');
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
      future: _fetchData(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else {
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
                future: _fetchWeatherData(startDate, endDate, lat, lon),
                builder:
                    (BuildContext context, AsyncSnapshot<Map> weatherSnapshot) {
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        ? Text('Temp min: ${weather["t_min"]}')
                                        : Container(),
                                    weather["check"]
                                        ? Text('Temp max: ${weather["t_max"]}')
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
                                      data = await loadBoxData(id, level);
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
        }
      },
    );
  }
}
