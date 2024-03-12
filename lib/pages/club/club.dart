import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:club/pages/main/login.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:club/pages/main/setting.dart';
import 'package:club/pages/club/box.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'torneo.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:club/config.dart';
import 'package:adaptive_layout/adaptive_layout.dart';

class ClubPage extends StatefulWidget {
  const ClubPage({super.key, required this.title, required this.document});

  final Map document;
  final String title;

  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  String section = 'CLUB';
  String bottomLevel = 'home';
  String selectedOption = '';
  bool imageUploaded = false;
  bool startDateUploaded = false;
  bool endDateUploaded = false;
  bool _isSidebarExtended = false;

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();

    await FirebaseAuth.instance.signOut();
    setState(() {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const Login(title: 'Tiber Club')));
    });
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
      startDateUploaded = true;
    }
    return startDate;
  }

  Future<String> _endDate(
      BuildContext context, String startDate, String endDate) async {
    if (startDate == "") {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona prima la data iniziale')));
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
        endDateUploaded = true;
      }
    }
    return endDate;
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

    imageUploaded = true;

    return imageUrl;
  }

  Future<void> sendNotification(
      List fcmToken, String title, String message) async {
    const String serverKey = Config.serverKey;
    const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';
    Uri uri = Uri.parse(fcmUrl);

    for (String token in fcmToken) {
      final Map<String, dynamic> notification = {
        'title': title,
        'body': message,
      };

      final Map<String, dynamic> data = {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'id': '1',
        'status': 'done',
      };

      final Map<String, dynamic> body = {
        'to': token,
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
  }

  Future<List<String>> fetchToken(String targetClass) async {
    List<String> tokens = [];
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('club_class', isEqualTo: targetClass)
          .get();
      for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
        String token = documentSnapshot['token'];
        tokens.add(token);
      }
      return tokens;
    } catch (e) {
      print('Errore durante l\'accesso a Firestore: $e');
      return [];
    }
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

      await firestore
          .collection('${section.toLowerCase()}_$selectedOption')
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
      List<String> token = await fetchToken(selectedClass);
      print(token);
      sendNotification(token, 'Nuovo programma!', title);
    } catch (e) {
      print('Errore durante la creazione dell\'evento: $e');
    }
  }

  Future<List<dynamic>> _getSuggestions(String query) async {
    const String apiUrl = Config.locationIqUrl;
    const String locationiqKey = Config.locationIqKey;

    final response = await http.get(
      Uri.parse('$apiUrl?q=$query&key=$locationiqKey&format=json&limit=5'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load suggestions');
    }
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
                            border: OutlineInputBorder(),
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
                          return await _getSuggestions(pattern);
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
                      items: ['', '1° media', '2° media', '3° media']
                          .map((String option) {
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
                        String imageUrl = await uploadImage(selectedOption);
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
                                startDate =
                                    await _startDate(context, startDate);
                                setState(() {});
                              },
                              child: Text(
                                  startDateUploaded ? '$startDate' : 'Data'),
                            ),
                          ]
                        : (selectedOption == 'trip' ||
                                selectedOption == 'tournament')
                            ? [
                                ElevatedButton(
                                  onPressed: () async {
                                    startDate =
                                        await _startDate(context, startDate);
                                    setState(() {});
                                  },
                                  child: Text(startDateUploaded
                                      ? '$startDate'
                                      : 'Data iniziale'),
                                ),
                                const SizedBox(height: 16.0),
                                ElevatedButton(
                                  onPressed: () async {
                                    endDate = await _endDate(
                                        context, startDate, endDate);
                                    setState(() {});
                                  },
                                  child: Text(endDateUploaded
                                      ? '$endDate'
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

  @override
  void initState() {
    super.initState();
  }

  Widget smallScreen() {
    return Scaffold(
      body: Center(
          child: bottomLevel == "home"
              ? Box(
                  selectedClass: widget.document['club_class'],
                  section: section.toLowerCase(),
                )
              : bottomLevel == "torneo"
                  ? TabScorer(
                      document: widget.document,
                    )
                  : SettingsPage(
                      id: widget.document["id"],
                      document: widget.document,
                    )),
      floatingActionButton:
          widget.document['status'] == 'Admin' && bottomLevel == 'home'
              ? SpeedDial(
                  children: [
                    SpeedDialChild(
                      child: Icon(Icons.calendar_today),
                      onTap: () {
                        _showAddEvent("weekend");
                      },
                    ),
                    SpeedDialChild(
                      child: const Icon(Icons.holiday_village),
                      onTap: () {
                        _showAddEvent("trip");
                      },
                    ),
                    SpeedDialChild(
                      child: const Icon(Icons.plus_one),
                      onTap: () {
                        _showAddEvent("extra");
                      },
                    ),
                  ],
                  child: const Icon(Icons.add),
                )
              : null,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            InkWell(
              onTap: () {
                setState(() {
                  bottomLevel = 'home';
                  imageUploaded = false;
                });
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.home),
                  Text('Home'),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  bottomLevel = 'torneo';
                });
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.sports_soccer),
                  Text('Torneo'),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  bottomLevel = 'account';
                });
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.account_box),
                  Text('Account'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bigScreen() {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: bottomLevel == 'home'
                  ? 0
                  : bottomLevel == 'torneo'
                      ? 1
                      : 2,
              onDestinationSelected: (int index) {
                setState(() {
                  bottomLevel = index == 0
                      ? 'home'
                      : index == 1
                          ? 'torneo'
                          : 'account';
                });
              },
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                  padding: EdgeInsets.only(top: 8.0),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.sports_soccer),
                  selectedIcon: Icon(Icons.sports_soccer),
                  label: Text('Torneo'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_box),
                  selectedIcon: Icon(Icons.account_box),
                  label: Text('Account'),
                ),
              ],
              extended: _isSidebarExtended,
              leading: IconButton(
                icon: Icon(_isSidebarExtended
                    ? Icons.arrow_back
                    : Icons.menu),
                onPressed: () {
                  setState(() {
                    _isSidebarExtended = !_isSidebarExtended;
                  });
                },
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: _logout,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // This is the main content.
            Expanded(
              child: Scaffold(
                body: Center(
                    child: bottomLevel == "home"
                        ? Box(
                            selectedClass: widget.document['club_class'],
                            section: section.toLowerCase(),
                          )
                        : bottomLevel == "torneo"
                            ? TabScorer(
                                document: widget.document,
                              )
                            : SettingsPage(
                                id: widget.document["id"],
                                document: widget.document,
                              )),
                floatingActionButton: widget.document['status'] == 'Admin' &&
                        bottomLevel == 'home'
                    ? SpeedDial(
                        children: [
                          SpeedDialChild(
                            child: Icon(Icons.calendar_today),
                            onTap: () {
                              _showAddEvent("weekend");
                            },
                          ),
                          SpeedDialChild(
                            child: const Icon(Icons.holiday_village),
                            onTap: () {
                              _showAddEvent("trip");
                            },
                          ),
                          SpeedDialChild(
                            child: const Icon(Icons.plus_one),
                            onTap: () {
                              _showAddEvent("extra");
                            },
                          ),
                        ],
                        child: const Icon(Icons.add),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      smallLayout: smallScreen(),
      largeLayout: bigScreen(),
    );
  }
}
