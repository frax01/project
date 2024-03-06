import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  int weather_code = 0;
  int temperature_min = 0;
  int temperature_max = 0;

  List w_code = [];
  List t_min = [];
  List t_max = [];
  bool check = false;

  //Bisogna fare due funzioni diverse, una per i trip e una per weekend e extra perchè sennò c'è il problema dei future 
  //oppure non usare le variabili globali ma locali
  Future<String> _fetchWeatherData(startDate, endDate) async {
    String weatherImageUrl = '';
    weather_code = 0;
    temperature_min = 0;
    temperature_max = 0;
    check = false;
    DateFormat inputFormat = DateFormat("dd-MM-yyyy");
    DateFormat outputFormat = DateFormat("yyyy-MM-dd");
    DateTime startParsedDate = inputFormat.parse(startDate);
    String startOutputDate = outputFormat.format(startParsedDate);

    DateTime today = DateTime.now();
    DateTime startDateCheck = inputFormat.parse(startDate);
    Duration difference = startDateCheck.difference(today);
    int daysDifference = difference.inDays;
    if (daysDifference >= 16) {
      check = false;
      return '';
    } else if (endDate != '' &&
        startDateCheck.isBefore(today) &&
        today.isBefore(DateFormat('dd-MM-yyyy').parse(endDate))) {
      startOutputDate = outputFormat.format(today);
      check = true;
      final response = await http.get(
        Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=45.4613&longitude=9.1595&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Europe%2FRome&start_date=$startOutputDate&end_date=$startOutputDate'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        weather_code = data['daily']['weather_code'][0];
        temperature_min = (data['daily']['temperature_2m_min'][0] < 0)
            ? data['daily']['temperature_2m_min'][0].ceil()
            : data['daily']['temperature_2m_min'][0].floor();
        temperature_max = (data['daily']['temperature_2m_max'][0] < 0)
            ? data['daily']['temperature_2m_max'][0].ceil()
            : data['daily']['temperature_2m_max'][0].floor();
        print('Weather_code: $weather_code');
        print('Temperature Min: $temperature_min');
        print('Temperature Max: $temperature_max');
      } else {
        throw Exception('Failed to fetch weather data');
      }
      String weatherImage = 'Weather/$weather_code.png';
      Reference ref = FirebaseStorage.instance.ref().child(weatherImage);
      weatherImageUrl = await ref.getDownloadURL();
      return weatherImageUrl;
    } else if (endDate != '') {
      //trip
      check = true;

      DateTime today = DateTime.now();
      DateTime endDateCheck = DateFormat('dd-MM-yyyy').parse(endDate);
      Duration difference = endDateCheck.difference(today);
      int daysDifference = difference.inDays;
      String endOutputDate = '';
      if (daysDifference >= 16) {
        DateTime endParsedDate = today.add(const Duration(days: 15));
        endOutputDate = outputFormat.format(endParsedDate);
      } else {
        DateTime endParsedDate = inputFormat.parse(endDate);
        endOutputDate = outputFormat.format(endParsedDate);
      }
      print(endOutputDate);
      final response = await http.get(
        Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=45.4613&longitude=9.1595&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Europe%2FRome&start_date=$startOutputDate&end_date=$endOutputDate'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        w_code = data['daily']['weather_code'];
        t_min = data['daily']['temperature_2m_min'];
        t_max = data['daily']['temperature_2m_max'];

        double sum = 0;
        for (double value in t_min) {
          sum += value;
        }
        temperature_min = ((sum / t_min.length) < 0)
            ? (sum / t_min.length).ceil()
            : (sum / t_min.length).floor();

        sum = 0;
        for (double value in t_max) {
          sum += value;
        }
        temperature_max = ((sum / t_max.length) < 0)
            ? (sum / t_max.length).ceil()
            : (sum / t_max.length).floor();

        t_min.forEach((team) {
          print(team);
        });
        //print('Temperature Min: $temperature_min');
        //print('Temperature Max: $temperature_max');
      } else {
        throw Exception('Failed to fetch weather data');
      }
      String weatherImage = 'Weather/${w_code[0]}.png';
      Reference ref = FirebaseStorage.instance.ref().child(weatherImage);
      weatherImageUrl = await ref.getDownloadURL();
      return weatherImageUrl;
    } else {
      check = true;
      final response = await http.get(
        Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=45.4613&longitude=9.1595&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Europe%2FRome&start_date=$startOutputDate&end_date=$startOutputDate'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        weather_code = data['daily']['weather_code'][0];
        temperature_min = (data['daily']['temperature_2m_min'][0] < 0)
            ? data['daily']['temperature_2m_min'][0].ceil()
            : data['daily']['temperature_2m_min'][0].floor();
        temperature_max = (data['daily']['temperature_2m_max'][0] < 0)
            ? data['daily']['temperature_2m_max'][0].ceil()
            : data['daily']['temperature_2m_max'][0].floor();
        print('Weather_code: $weather_code');
        print('Temperature Min: $temperature_min');
        print('Temperature Max: $temperature_max');
      } else {
        throw Exception('Failed to fetch weather data');
      }
      String weatherImage = 'Weather/$weather_code.png';
      Reference ref = FirebaseStorage.instance.ref().child(weatherImage);
      weatherImageUrl = await ref.getDownloadURL();
      return weatherImageUrl;
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
        setState(() {
          endDate = DateFormat('dd-MM-yyyy').format(picked);
        });
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
    String description = data['description'];
    String startDate = data['startDate'] ?? '';
    String endDate = data['endDate'] ?? '';

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
                  DropdownButtonFormField<String>(
                    value: data['selectedClass'],
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value!;
                      });
                    },
                    items: ['', '1° media', '2° media', '3° media']
                        .map((String option) {
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
                    child: const Text('Cambia immagine'),
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
                          section);
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
      String section) async {
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
      });
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
              var endDate = document['endDate'] ?? '';
              var imagePath = document['imagePath'];
              var description = document['description'];
              return FutureBuilder(
                future: _fetchWeatherData(startDate, endDate),
                builder: (BuildContext context,
                    AsyncSnapshot<String> weatherSnapshot) {
                  if (weatherSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Container();
                  } else {
                    String? imageUrl = weatherSnapshot.data;
                    return Container(
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
                                if (document['endDate'] != '')
                                  Text('Data finale: ${document['endDate']}'),
                                Image(
                                  image: NetworkImage(imagePath),
                                  height: 100,
                                  width: 100,
                                ),
                                Text('Descrizione: $description'),
                                check
                                    ? Text('Temp min: $temperature_min')
                                    : Container(),
                                check
                                    ? Text('Temp max: $temperature_max')
                                    : Container(),
                                if (imageUrl == null || imageUrl == '')
                                  const Text('Weather non disponibile')
                                else
                                  Image(
                                    image: NetworkImage(imageUrl),
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
                                  _showEditDialog(
                                      data["selectedOption"], data, level, id);
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
                                              Navigator.of(context).pop(false);
                                            },
                                          ),
                                          TextButton(
                                            child: const Text('Si'),
                                            onPressed: () {
                                              Navigator.of(context).pop(true);
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
                    );
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
