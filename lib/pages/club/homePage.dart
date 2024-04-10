import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/pages/club/programCard.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ms_undraw/ms_undraw.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

import '../../functions/dataFunctions.dart';
import '../../functions/geoFunctions.dart';
import '../../functions/notificationFunctions.dart';
import '../../functions/weatherFunctions.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.selectedClass,
    required this.section,
    required this.isAdmin,
  });

  final List selectedClass;
  final String section;
  final bool isAdmin;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _listItems = <ProgramCard>[];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  bool imageUploaded = false;
  bool startDateUploaded = false;
  bool endDateUploaded = false;

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
    //String selectedClass = '';
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

    final List<String> allOptions = [
      '1° liceo',
      '2° liceo',
      '3° liceo',
      '4° liceo',
      '5° liceo'
    ];
    List<String> selectedFormClass = [];

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
                    MultiSelectDialogField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      items: allOptions
                          .map((option) =>
                              MultiSelectItem<String>(option, option))
                          .toList(),
                      buttonText: const Text('Classe'),
                      confirmText: const Text('Ok'),
                      cancelText: const Text('Annulla'),
                      initialValue: selectedFormClass,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserire almeno una classe';
                        }
                        return null;
                      },
                      onConfirm: (value) {
                        setState(() {
                          selectedFormClass = value;
                          print("select: $selectedFormClass");
                        });
                      },
                    ),
                    //DropdownButtonFormField<String>(
                    //  value: selectedClass,
                    //  onChanged: (value) {
                    //    setState(() {
                    //      selectedClass = value!;
                    //    });
                    //  },
                    //  validator: (value) {
                    //    if (value == null || value.isEmpty) {
                    //      return 'Inserire la classe';
                    //    }
                    //    return null;
                    //  },
                    //  items: [
                    //    '',
                    //    '1° liceo',
                    //    '2° liceo',
                    //    '3° liceo',
                    //    '4° liceo',
                    //    '5° liceo'
                    //  ].map((String option) {
                    //    return DropdownMenuItem<String>(
                    //      value: option,
                    //      child: Text(option),
                    //    );
                    //  }).toList(),
                    //  hint: const Text('Seleziona una classe'),
                    //),
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
                    //...(selectedOption == 'weekend' ||
                    //        selectedOption == 'extra')
                    //    ? [
                    //        ElevatedButton(
                    //          onPressed: () async {
                    //            startDate = await _startDate(context, startDate,
                    //                isCreate: true);
                    //            setState(() {});
                    //          },
                    //          child:
                    //              Text(startDateUploaded ? startDate : 'Data'),
                    //        ),
                    //      ]
                    //    : (selectedOption == 'trip' ||
                    //            selectedOption == 'tournament')
                    //        ? [
                    //            ElevatedButton(
                    //              onPressed: () async {
                    //                startDate = await _startDate(
                    //                    context, startDate,
                    //                    isCreate: true);
                    //                setState(() {});
                    //              },
                    //              child: Text(startDateUploaded
                    //                  ? startDate
                    //                  : 'Data iniziale'),
                    //            ),
                    //            const SizedBox(height: 16.0),
                    //            ElevatedButton(
                    //              onPressed: () async {
                    //                endDate = await _endDate(
                    //                    context, startDate, endDate,
                    //                    isCreate: true);
                    //                setState(() {});
                    //              },
                    //              child: Text(endDateUploaded
                    //                  ? endDate
                    //                  : 'Data finale'),
                    //            ),
                    //          ]
                    //        : [],
                    //const SizedBox(height: 16.0),
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
                                  selectedFormClass,
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
      List selectedFormClass,
      String startDate,
      String endDate,
      String description,
      String address,
      String lat,
      String lon) async {
    try {
      //if ((selectedOption == 'weekend' || selectedOption == 'extra') &&
      //    startDate == "") {
      //  ScaffoldMessenger.of(context).showSnackBar(
      //      const SnackBar(content: Text('Please select a date')));
      //  return;
      //}
      //if ((selectedOption == 'trip') && (startDate == "" || endDate == "")) {
      //  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      //      content: Text('Please select the start and the end date')));
      //  return;
      //}
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

      print("0");

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      //da togliere
      startDate = '22-03-2024';
      endDate = '';
      Map weather = await fetchWeatherData(startDate, endDate, lat, lon);
      print("1");
      Map document = {
        'title': title,
        'selectedOption': selectedOption,
        'imagePath': imagePath,
        'selectedClass': selectedFormClass,
        'description': description,
        'startDate': startDate,
        'endDate': endDate,
        'address': address,
        'lat': lat,
        'lon': lon,
      };
      print("2");

      print('section: ${widget.section.toLowerCase()}_$selectedOption');

      await firestore
          .collection('${widget.section.toLowerCase()}_$selectedOption')
          .add({
        'title': title,
        'selectedOption': selectedOption,
        'imagePath': imagePath,
        'selectedClass': selectedFormClass,
        'description': description,
        'startDate': startDate,
        'endDate': endDate,
        'address': address,
        'lat': lat,
        'lon': lon,
      });
      Navigator.pop(context);
      List<String> token = [];
      for (String value in selectedFormClass) {
        List<String> items = await fetchToken('club_class', value);
        for (String elem in items) {
          if (!token.contains(elem)) {
            token.add(elem);
          }
        }
      }
      sendNotification(
          token, 'Nuovo programma!', title, 'new_event', document, weather);
    } catch (e) {
      print('Errore durante la creazione dell\'evento: $e');
    }
  }

  _loadItems(counts) {
    for (final pair in counts) {
      var baseQuery = FirebaseFirestore.instance
          .collection(pair[0])
          .where('selectedClass', arrayContainsAny: widget.selectedClass)
          .orderBy('startDate');
      for (var i = 0; i < pair[1]; i++) {
        _listItems.add(ProgramCard(
          query: baseQuery.startAt([i]).limit(1),
          isAdmin: widget.isAdmin,
        ));
        _listKey.currentState?.insertItem(_listItems.length - 1);
      }
    }
  }

  _buildList() {
    return FutureBuilder(
      future: countDocuments(),
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          _loadItems(snapshot.data!);
          if (_listItems.isEmpty) {
            child = Column(
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
                  'Nessun evento disponibile',
                  style: TextStyle(fontSize: 20.0, color: Colors.black54),
                ),
              ],
            );
          } else {
            child = AnimatedList(
              key: _listKey,
              initialItemCount: _listItems.length,
              itemBuilder: (context, index, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: _listItems[index],
                );
              },
            );
          }
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: child,
        );
      },
    );
  }

  _smallLayout() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildList(),
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

  _largeLayout() {
    return Container(
      child: Center(
        child: Text('Large Layout'),
      ),
    );
  }

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      smallLayout: _smallLayout(),
      largeLayout: _largeLayout(),
    );
  }
}
