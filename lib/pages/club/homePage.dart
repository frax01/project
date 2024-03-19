import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/functions/dataFunctions.dart';
import 'package:club/functions/geoFunctions.dart';
import 'package:club/functions/notificationFunctions.dart';
import 'package:club/functions/weatherFunctions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'programPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.selectedClass,
    required this.section,
    required this.isAdmin,
  });

  final String selectedClass;
  final String section;
  final bool isAdmin;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool imageUploaded = false;
  bool startDateUploaded = false;
  bool endDateUploaded = false;

  final _listItems = <Widget>[];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    var items = await fetchData([], widget.selectedClass);
    var weather = [];
    for (var item in items) {
      var startDate = item['startDate'];
      var endDate = item['endDate'];
      var lat = item["lat"];
      var lon = item["lon"];
      var weatherData = await fetchWeatherData(startDate, endDate, lat, lon);
      weather.add(weatherData);
    }

    var future = Future(() {});
    for (var i = 0; i < items.length; i++) {
      future = future.then((_) {
        return Future.delayed(const Duration(milliseconds: 100), () {
          _listItems.add(buildCard(items[i], weather[i]));
          _listKey.currentState!.insertItem(i);
        });
      });
    }
  }

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

  Future<void> _showAddEvent(String selectedOption) async {
    String title = '';
    String imagePath = '';
    String selectedClass = '';
    String startDate = '';
    String endDate = '';
    String description = '';
    String selectedAddr = "";
    String? selectedCitta = "";
    String selectedStato = "";
    String? selectedNum = "";
    String selectedLon = "";
    String selectedLat = "";
    String indirizzo = '';

    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(selectedOption),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Titolo'),
                      onChanged: (value) {
                        setState(() {
                          title = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty || value == '') {
                          return 'Inserire il titolo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TypeAheadField(
                      builder: (context, controller, focusNode) {
                        String label = (selectedOption == 'trip')
                            ? 'Dove?'
                            : 'Dove? (facoltativo)';
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
                          selectedLat = suggestion["lat"];
                          selectedLon = suggestion["lon"];

                          if (selectedCitta != '' && selectedNum != '') {
                            if (selectedStato != 'Italia') {
                              indirizzo =
                                  '$selectedAddr, ${selectedNum ?? ''}, ${selectedCitta ?? ''}, $selectedStato';
                            } else {
                              indirizzo =
                                  '$selectedAddr, ${selectedNum ?? ''}, ${selectedCitta ?? ''}';
                            }
                          } else {
                            if (selectedStato != 'Italia') {
                              indirizzo = '$selectedAddr, $selectedStato';
                            } else {
                              indirizzo = selectedAddr;
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: selectedClass,
                      onChanged: (value) {
                        setState(() {
                          selectedClass = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserire la classe';
                        }
                        return null;
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
                      hint: const Text('Seleziona una classe'),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () async {
                        String imageUrl =
                            await uploadImage(selectedOption, isCreate: true);
                        setState(() {
                          imagePath = imageUrl;
                        });
                      },

                      child: Text(imageUploaded
                          ? 'Cambia immagine'
                          : 'Carica Immagine'), //mostrare una barra di caricamento
                    ),
                    const SizedBox(height: 16.0),
                    ...(selectedOption == 'weekend' ||
                            selectedOption == 'extra')
                        ? [
                            ElevatedButton(
                              onPressed: () async {
                                startDate = await _startDate(context, startDate,
                                    isCreate: true);
                                setState(() {});
                              },
                              child:
                                  Text(startDateUploaded ? startDate : 'Data'),
                            ),
                          ]
                        : (selectedOption == 'trip' ||
                                selectedOption == 'tournament')
                            ? [
                                ElevatedButton(
                                  onPressed: () async {
                                    startDate = await _startDate(
                                        context, startDate,
                                        isCreate: true);
                                    setState(() {});
                                  },
                                  child: Text(startDateUploaded
                                      ? startDate
                                      : 'Data iniziale'),
                                ),
                                const SizedBox(height: 16.0),
                                ElevatedButton(
                                  onPressed: () async {
                                    endDate = await _endDate(
                                        context, startDate, endDate,
                                        isCreate: true);
                                    setState(() {});
                                  },
                                  child: Text(endDateUploaded
                                      ? endDate
                                      : 'Data finale'),
                                ),
                              ]
                            : [],
                    const SizedBox(height: 16.0),
                    TextFormField(
                      onChanged: (value) {
                        description = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserire una descrizione';
                        }
                        return null;
                      },
                      decoration:
                          const InputDecoration(labelText: 'Descrizione'),
                      maxLines: null,
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            imageUploaded = false;
                            startDateUploaded = false;
                            endDateUploaded = false;
                            Navigator.of(context).pop();
                          },
                          child: const Text('Annulla'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              await createEvent(
                                  title,
                                  selectedOption,
                                  imagePath,
                                  selectedClass,
                                  startDate,
                                  endDate,
                                  description,
                                  indirizzo,
                                  selectedLat,
                                  selectedLon);
                              imageUploaded = false;
                              startDateUploaded = false;
                              endDateUploaded = false;
                            }
                          },
                          child: const Text('Crea'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> createEvent(
      String title,
      String selectedOption,
      String imagePath,
      String selectedClass,
      String startDate,
      String endDate,
      String description,
      String address,
      String lat,
      String lon) async {
    try {
      if ((selectedOption == 'weekend' || selectedOption == 'extra') &&
          startDate == "") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a date')));
        return;
      }
      if ((selectedOption == 'trip') && (startDate == "" || endDate == "")) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select the start and the end date')));
        return;
      }
      //if (imagePath == "") {
      //  ScaffoldMessenger.of(context).showSnackBar(
      //      const SnackBar(content: Text('Please select an image')));
      //  return;
      //}
      if (address == '') {
        address = 'Tiber Club';
        lat = '41.91805195';
        lon = '12.47788708';
      }

      FirebaseFirestore firestore = FirebaseFirestore.instance;

      Map weather = await fetchWeatherData(startDate, endDate, lat, lon);

      Map document = {
        'title': title,
        'selectedOption': selectedOption,
        'imagePath': imagePath,
        'selectedClass': selectedClass,
        'description': description,
        'startDate': startDate,
        'endDate': endDate,
        'address': address,
        'lat': lat,
        'lon': lon,
      };

      await firestore
          .collection('${widget.section.toLowerCase()}_$selectedOption')
          .add({
        'title': title,
        'selectedOption': selectedOption,
        'imagePath': imagePath,
        'selectedClass': selectedClass,
        'description': description,
        'startDate': startDate,
        'endDate': endDate,
        'address': address,
        'lat': lat,
        'lon': lon,
      });
      Navigator.pop(context);
      List<String> token = await fetchToken('club_class', selectedClass);
      sendNotification(
          token, 'Nuovo programma!', title, 'new_event', document, weather);
    } catch (e) {
      print('Errore durante la creazione dell\'evento: $e');
    }
  }

  Widget buildCard(document, weather) {
    var id = document['id'];
    var title = document['title'];
    var level = document['selectedOption'];
    var startDate = document['startDate'];
    var endDate = document['endDate'];
    var imagePath = document['imagePath'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: OpenContainer(
        clipBehavior: Clip.antiAlias,
        closedElevation: 5.0,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        closedBuilder: (context, action) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.network(
                      imagePath,
                      width: 400,
                      height: 250,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return const Center(
                            child: SizedBox(
                              width: 400,
                              height: 250,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(7.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 7.0,
                                ),
                              ],
                            ),
                            child: endDate != ""
                                ? Text('$startDate ～ $endDate',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))
                                : Text('$startDate',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20.0)),
                        Text(
                          level == 'weekend'
                              ? 'Weekend'
                              : level == 'extra'
                                  ? 'Extra'
                                  : level == 'trip'
                                      ? 'Gita'
                                      : 'Torneo',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        openBuilder: (context, action) {
          return ProgramPage(
              document: document, weather: weather!, isAdmin: widget.isAdmin);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AnimatedList(
          key: _listKey,
          initialItemCount: _listItems.length,
          itemBuilder: (context, index, animation) {
            return FadeTransition(
              opacity: animation,
              child: _listItems[index],
            );
          },
        ),
      ),
      floatingActionButton: widget.isAdmin
          ? SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.calendar_today),
                  label: 'Weekend',
                  onTap: () {
                    _showAddEvent("weekend");
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.holiday_village),
                  label: 'Trip',
                  onTap: () {
                    _showAddEvent("trip");
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.star),
                  label: 'Extra',
                  onTap: () {
                    _showAddEvent("extra");
                  },
                ),
              ],
            )
          : null,
    );
  }
}
