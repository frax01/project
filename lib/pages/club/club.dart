import 'dart:html';
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
import 'tabScorer.dart';

class ClubPage extends StatefulWidget {
  const ClubPage({super.key, required this.title, required this.document});

  final Map document;
  final String title;

  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  String section = 'CLUB';
  String _selectedLevel = 'home';
  bool imageUploaded = false;

  _saveLastPage(String page) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('lastPage', page);
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();

    Map<String, dynamic> allPrefs = prefs.getKeys().fold<Map<String, dynamic>>(
      {},
      (Map<String, dynamic> acc, String key) {
        acc[key] = prefs.get(key);
        return acc;
      },
    );

    print("SharedPreferences: $allPrefs");

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
      setState(() {
        startDate = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
    return startDate;
  }

  Future<String> _endDate(
      BuildContext context, String startDate, String endDate) async {
    if (startDate == "") {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select the startDate first')));
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

  Future<String> deleteImage(String imagePath) async {
    // Ottieni il riferimento all'immagine
    final Reference ref = FirebaseStorage.instance.ref().child(imagePath);
    // Elimina l'immagine
    await ref.delete();
    // Imposta imageUploaded a false e imagePath a stringa vuota
    setState(() {
      imageUploaded = false;
      imagePath = '';
    });
    return imagePath;
  }

  Future<String> uploadImage() async {
    final ImagePicker picker = ImagePicker();
    // Seleziona un'immagine dalla galleria
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      throw Exception('No image selected');
    }

    // Crea un riferimento a Firebase Storage
    final Reference ref = FirebaseStorage.instance
        .ref()
        .child('users/${DateTime.now().toIso8601String()}');
    //.child('${section}_image/${DateTime.now().toIso8601String()}');

    // Carica l'immagine su Firebase Storage
    final UploadTask uploadTask = ref.putData(await image.readAsBytes());

    // Attendi il completamento del caricamento
    final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

    // Ottieni l'URL dell'immagine caricata
    final String imageUrl = await snapshot.ref.getDownloadURL();

    print(imageUrl);

    setState(() {
      imageUploaded = true;
    });

    return imageUrl;
  }

  Future<void> createEvent(
      String event,
      String imagePath,
      String clubClass,
      String startDate,
      String endDate,
      String description,
      String level) async {
    try {
      if (event == "") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a title')));
        return;
      }
      if (clubClass == "") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a class')));
        return;
      }
      if ((level == 'weekend' || level == 'extra') && startDate == "") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a date')));
        return;
      }
      if ((level == 'trip') && (startDate == "" || endDate == "")) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select the start and the end date')));
        return;
      }
      if (description == "") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a description')));
        return;
      }
      if (imagePath == '') {
        imagePath = 'images/$level/default.jpg';
      }
      print("section: ${section.toLowerCase()}");

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('${section.toLowerCase()}_$level').add({
        'title': event,
        'selectedOption': level,
        'imagePath': imagePath,
        'selectedClass': clubClass,
        'description': description,
        'startDate': startDate,
        'endDate': endDate,
      });
      print('Evento creato con successo!');
      Navigator.pop(context);
    } catch (e) {
      print('Errore durante la creazione dell\'evento: $e');
    }
  }

  Future<void> _showAddEvent(String level) async {
    String event = '';
    String imagePath = '';
    String clubClass = '';
    //String soccer_class = '';
    String startDate = '';
    String endDate = '';
    String description = '';
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(level),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Titolo'),
                    onChanged: (value) {
                      setState(() {
                        event = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    value: clubClass,
                    onChanged: (value) {
                      setState(() {
                        clubClass = value!;
                      });
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
                    onPressed: imageUploaded
                        ? null
                        : () async {
                            String imageUrl = await uploadImage();
                            setState(() {
                              imagePath = imageUrl;
                            });
                          },
                    child: Text(imageUploaded
                        ? 'Immagine caricata'
                        : 'Carica Immagine'),
                  ),
                  const SizedBox(height: 16.0),
                  if (imageUploaded) ...[
                    ElevatedButton(
                      onPressed: () async {
                        // Mostra un dialogo di conferma prima di eliminare l'immagine
                        bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Conferma'),
                              content: const Text(
                                  'Sei sicuro di voler eliminare l\'immagine?'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Annulla'),
                                  onPressed: () {
                                    setState(() {
                                      Navigator.of(context).pop(false);
                                    });
                                  },
                                ),
                                TextButton(
                                  child: const Text('Elimina'),
                                  onPressed: () {
                                    setState(() {
                                      imageUploaded = false;
                                      Navigator.of(context).pop(true);
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        );
                        if (confirm == true) {
                          await deleteImage(imagePath);
                        }
                      },
                      child: const Text('Elimina Immagine'),
                    ),
                  ],
                  const SizedBox(height: 16.0),
                  ...(level == 'weekend' || level == 'extra')
                      ? [
                          ElevatedButton(
                            onPressed: () async {
                              startDate = await _startDate(context, startDate);
                            },
                            child: const Text('Date'),
                          ),
                        ]
                      : (level == 'trip' || level == 'tournament')
                          ? [
                              ElevatedButton(
                                onPressed: () async {
                                  startDate =
                                      await _startDate(context, startDate);
                                },
                                child: const Text('Start date'),
                              ),
                              const SizedBox(height: 16.0),
                              ElevatedButton(
                                onPressed: () async {
                                  endDate = await _endDate(
                                      context, startDate, endDate);
                                },
                                child: const Text('End date'),
                              ),
                            ]
                          : [],
                  const SizedBox(height: 16.0),
                  TextFormField(
                    onChanged: (value) {
                      description = value;
                    },
                    decoration: const InputDecoration(labelText: 'Descrizione'),
                    maxLines: null,
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Annulla'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await createEvent(event, imagePath, clubClass,
                              startDate, endDate, description, level);
                        },
                        child: const Text('Crea'),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var height = size.height;
    var width = size.width;
    print("title: ${widget.title}");
    print("document: ${widget.document}");
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 130, 16, 8),
        centerTitle: true,
        //iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: Center(
          child: _selectedLevel == "home"
              ? Box(
                  level: _selectedLevel,
                  clubClass: widget.document['club_class'],
                  section: section.toLowerCase(),
                )
              : _selectedLevel == "torneo"
                  ? TabScorer(
                      email: widget.document["email"],
                      status: widget.document["status"],
                    )
                  : SettingsPage(
                      id: widget.document["id"],
                      document: widget.document,
                    )),
      //drawer: Drawer(
      //  width: width > 700
      //      ? width / 3
      //      : width > 400
      //          ? width / 2
      //          : width / 1.5,
      //  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      //  child: ListView(
      //    children: [
      //      Padding(
      //        padding: const EdgeInsets.all(8.0),
      //        child: Image(
      //          image: const AssetImage('images/logo.png'),
      //          width: width > 700 ? width / 4 : width / 8,
      //          height: height / 4,
      //        ),
      //      ),
      //      Padding(
      //        padding: const EdgeInsets.all(8.0),
      //        child: Row(
      //          mainAxisAlignment: MainAxisAlignment.center,
      //          children: [
      //            Text('${widget.document['name']} ',
      //                style: TextStyle(fontSize: width > 300 ? 18 : 14)),
      //            Text('${widget.document['surname']}',
      //                style: TextStyle(fontSize: width > 300 ? 18 : 14))
      //          ],
      //        ),
      //      ),
      //      Padding(
      //          padding:
      //              const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      //          child: Text('${widget.document['club_class']}',
      //              textAlign: TextAlign.center,
      //              style: TextStyle(
      //                  fontSize: width > 500
      //                      ? 14
      //                      : width > 300
      //                          ? 10
      //                          : 8))),
      //      Padding(
      //          padding:
      //              const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      //          child: Text('${widget.document['email']}',
      //              textAlign: TextAlign.center,
      //              style: TextStyle(
      //                  fontSize: width > 500
      //                      ? 14
      //                      : width > 300
      //                          ? 10
      //                          : 8))),
      //      DropdownButton(
      //        value: section,
      //        onChanged: (value) {
      //          if (widget.document['soccer_class'] != '') {
      //            setState(() {
      //              section = value.toString();
      //              if (section == 'FOOTBALL') {
      //                _saveLastPage('FootballPage');
      //                Navigator.push(
      //                    context,
      //                    MaterialPageRoute(
      //                        builder: (context) => FootballPage(
      //                              title: 'Tiber Club',
      //                              document: widget.document,
      //                            )));
      //              }
      //            });
      //          } else {
      //            Navigator.pop(context);
      //            ScaffoldMessenger.of(context).showSnackBar(
      //              const SnackBar(
      //                  content: Text('Non fai ancora parte di una squadra')),
      //            );
      //          }
      //        },
      //        alignment: AlignmentDirectional.center,
      //        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      //        underline: Container(
      //          height: 0.5,
      //          color: Colors.black,
      //        ),
      //        items: const [
      //          DropdownMenuItem(
      //            value: 'CLUB',
      //            child: Text('CLUB'),
      //          ),
      //          DropdownMenuItem(
      //            value: 'FOOTBALL',
      //            child: Text('FOOTBALL'),
      //          ),
      //        ],
      //      ),
      //      ListTile(
      //        leading: const Icon(
      //          Icons.settings,
      //        ),
      //        title: const Text('Settings'),
      //        subtitle: Text('Account management',
      //            style: TextStyle(
      //                fontSize: width > 700
      //                    ? 12
      //                    : width > 500
      //                        ? 14
      //                        : width > 400
      //                            ? 11
      //                            : width > 330
      //                                ? 12
      //                                : 10)),
      //        onTap: () {
      //          Navigator.push(
      //              context,
      //              MaterialPageRoute(
      //                  builder: (context) => SettingsPage(
      //                        id: widget.document['id'],
      //                        document: widget.document,
      //                      )));
      //        },
      //      ),
      //      widget.document['status'] == 'Admin'
      //          ? ListTile(
      //              leading: const Icon(
      //                Icons.code,
      //              ),
      //              title: const Text('Incoming requests'),
      //              subtitle: Text('Accept new users',
      //                  style: TextStyle(
      //                      fontSize: width > 700
      //                          ? 12
      //                          : width > 500
      //                              ? 14
      //                              : width > 400
      //                                  ? 11
      //                                  : width > 330
      //                                      ? 12
      //                                      : 10)),
      //              onTap: () {
      //                Navigator.pushNamed(context, '/acceptance');
      //              },
      //            )
      //          : Container(),
      //      ListTile(
      //        leading: const Icon(
      //          Icons.logout,
      //        ),
      //        title: const Text('Logout'),
      //        subtitle: Text('We will miss you...',
      //            style: TextStyle(
      //                fontSize: width > 700
      //                    ? 12
      //                    : width > 500
      //                        ? 14
      //                        : width > 400
      //                            ? 11
      //                            : width > 330
      //                                ? 12
      //                                : 10)),
      //        onTap: () {
      //          showDialog(
      //            context: context,
      //            builder: (BuildContext context) {
      //              return AlertDialog(
      //                title: const Text('Logout'),
      //                content: const Text('Are you sure you want to logout?'),
      //                actions: <Widget>[
      //                  TextButton(
      //                    child: const Text('Cancel'),
      //                    onPressed: () {
      //                      Navigator.of(context).pop();
      //                    },
      //                  ),
      //                  TextButton(
      //                    child: const Text('Yes'),
      //                    onPressed: () async {
      //                      await _logout();
      //                    },
      //                  ),
      //                ],
      //              );
      //            },
      //          );
      //        },
      //      ),
      //    ],
      //  ),
      //),
      floatingActionButton:
          widget.document['status'] == 'Admin' && _selectedLevel == 'home'
              //? FloatingActionButton(
              //    onPressed: () {
              //      _showAddEvent(_selectedLevel);
              //    },
              //    child: const Icon(Icons.add),
              //  )
              //: null,
              ? SpeedDial(
                  child: Icon(Icons.add),
                  children: [
                    SpeedDialChild(
                      child: Icon(Icons.calendar_today),
                      backgroundColor: Colors.grey,
                      onTap: () {
                        _showAddEvent("weekend");
                      },
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.holiday_village),
                      backgroundColor: Colors.grey,
                      onTap: () {
                        _showAddEvent("trip");
                      },
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.plus_one),
                      backgroundColor: Colors.grey,
                      onTap: () {
                        _showAddEvent("extra");
                      },
                    ),
                  ],
                )
              : null,
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 130, 16, 8),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            InkWell(
              onTap: () {
                setState(() {
                  _selectedLevel = 'home';
                });
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.home, color: Colors.white),
                  Text('Home', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _selectedLevel = 'torneo';
                });
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.sports_soccer, color: Colors.white),
                  Text('Torneo', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _selectedLevel = 'account';
                });
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.account_box, color: Colors.white),
                  Text('Account', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
