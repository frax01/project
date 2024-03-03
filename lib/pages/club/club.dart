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
        setState(() {
          endDate = DateFormat('dd-MM-yyyy').format(picked);
        });
      }
    }
    return endDate;
  }

  Future<String> deleteImage(String imagePath) async {
    final Reference ref = FirebaseStorage.instance.ref().child(imagePath);
    await ref.delete();
    setState(() {
      imageUploaded = false;
      imagePath = '';
    });
    return imagePath;
  }

  Future<String> uploadImage(String level) async {
    final storageRef = FirebaseStorage.instance.ref();

    final imagesRef = storageRef.child('$level/${DateTime.now().toIso8601String()}.jpeg');

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    final UploadTask uploadTask = imagesRef.putData(await image!.readAsBytes());
    final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
    final String imageUrl = await snapshot.ref.getDownloadURL();

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
      if (imagePath == "") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an image')));
        return;
      }

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
                            String imageUrl = await uploadImage(level);
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
                                  child: const Text('No'),
                                  onPressed: () {
                                    setState(() {
                                      Navigator.of(context).pop(false);
                                    });
                                  },
                                ),
                                TextButton(
                                  child: const Text('Si'),
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
                      child: const Text('Elimina immagine'),
                    ),
                  ],
                  const SizedBox(height: 16.0),
                  ...(level == 'weekend' || level == 'extra')
                      ? [
                          ElevatedButton(
                            onPressed: () async {
                              startDate = await _startDate(context, startDate);
                            },
                            child: const Text('Data'),
                          ),
                        ]
                      : (level == 'trip' || level == 'tournament')
                          ? [
                              ElevatedButton(
                                onPressed: () async {
                                  startDate =
                                      await _startDate(context, startDate);
                                },
                                child: const Text('Data iniziale'),
                              ),
                              const SizedBox(height: 16.0),
                              ElevatedButton(
                                onPressed: () async {
                                  endDate = await _endDate(
                                      context, startDate, endDate);
                                },
                                child: const Text('Data finale'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 130, 16, 8),
        centerTitle: true,
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
      floatingActionButton:
          widget.document['status'] == 'Admin' && _selectedLevel == 'home'
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
                      child: const Icon(Icons.holiday_village),
                      backgroundColor: Colors.grey,
                      onTap: () {
                        _showAddEvent("trip");
                      },
                    ),
                    SpeedDialChild(
                      child: const Icon(Icons.plus_one),
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
