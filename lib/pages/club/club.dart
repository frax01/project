import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:club/pages/main/login.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:club/pages/club/settingsPage.dart';
import 'package:club/pages/club/homePage.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:club/pages/club/torneoPage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:club/functions/notificationFunctions.dart';
import 'package:club/functions/geoFunctions.dart';
import 'package:club/functions/weatherFunctions.dart';

class ClubPage extends StatefulWidget {
  const ClubPage({super.key, required this.title, required this.document});

  final Map document;
  final String title;

  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  static const String section = 'CLUB';
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  bool _isSidebarExtended = false;

  bool imageUploaded = false;
  bool startDateUploaded = false;
  bool endDateUploaded = false;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomePage(
        selectedClass: widget.document['club_class'],
        section: section.toLowerCase(),
      ),
      TabScorer(
        document: widget.document,
      ),
      SettingsPage(
        id: widget.document["id"],
        document: widget.document,
      ),
    ];
  }

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
      if (imagePath == "") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an image')));
        return;
      }
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
      List<String> token = await fetchToken('club_class', selectedClass);
      sendNotification(
          token, 'Nuovo programma!', title, 'new_event', document, weather);
    } catch (e) {
      print('Errore durante la creazione dell\'evento: $e');
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
                              child:
                                  Text(startDateUploaded ? startDate : 'Data'),
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
                                      ? startDate
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

  Future<void> _refresh() async {
    setState(() {});
  }

  Widget smallScreen() {
    return Scaffold(
      body: PageTransitionSwitcher(
        transitionBuilder: (Widget child, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      floatingActionButton:
          widget.document['status'] == 'Admin' && _selectedIndex == 0
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer),
            selectedIcon: Icon(Icons.sports_soccer),
            label: '11 ideale',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Utente',
          ),
        ],
      ),
    );
  }

  Widget bigScreen() {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
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
                  label: Text('11 ideale'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_box),
                  selectedIcon: Icon(Icons.account_box),
                  label: Text('Account'),
                ),
              ],
              extended: _isSidebarExtended,
              leading: IconButton(
                icon: Icon(_isSidebarExtended ? Icons.arrow_back : Icons.menu),
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
                body: PageTransitionSwitcher(
                  transitionBuilder: (Widget child, Animation<double> animation,
                      Animation<double> secondaryAnimation) {
                    return FadeThroughTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      child: child,
                    );
                  },
                  child: _widgetOptions.elementAt(_selectedIndex),
                ),
                floatingActionButton:
                    widget.document['status'] == 'Admin' && _selectedIndex == 0
                        ? SpeedDial(
                            children: [
                              SpeedDialChild(
                                child: const Icon(Icons.calendar_today),
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
    return RefreshIndicator(
      onRefresh: _refresh,
      child: PopScope(
        canPop: false,
        child: AdaptiveLayout(
          smallLayout: smallScreen(),
          largeLayout: bigScreen(),
        ),
      ),
    );
  }
}
