import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../functions/geoFunctions.dart';
import '../../functions/notificationFunctions.dart';
import '../../functions/weatherFunctions.dart';

class AddEditProgram extends StatefulWidget {
  const AddEditProgram({super.key, this.selectedOption, this.document});

  final String? selectedOption;
  final Map<dynamic, dynamic>? document;

  @override
  _AddEditProgramState createState() => _AddEditProgramState();
}

class _AddEditProgramState extends State<AddEditProgram> {
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _programNameController = TextEditingController();
  final TextEditingController _programDescriptionController =
      TextEditingController();
  final TextEditingController _programLocationController =
      TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  String _image = '';
  String _address = '';
  String _latitude = '';
  String _longitude = '';
  final List<String> classOptions = [
    '1º media',
    '2º media',
    '3º media',
    '1° liceo',
    '2° liceo',
    '3° liceo',
    '4° liceo',
    '5° liceo'
  ];
  List<String> selectedClasses = [];

  @override
  void initState() {
    super.initState();
    if (widget.document != null) {
      _isEditing = true;
      _programNameController.text = widget.document!['title'];
      _programDescriptionController.text = widget.document!['description'];
      _programLocationController.text = widget.document!['address'];
      _startDateController.text = widget.document!['startDate'];
      _endDateController.text = widget.document!['endDate'];
      _image = widget.document!['imagePath'];
      _address = widget.document!['address'];
      _latitude = widget.document!['lat'];
      _longitude = widget.document!['lon'];
      selectedClasses = List<String>.from(widget.document!['selectedClass']);
    }
  }

  _uploadImage(String level, {bool isCreate = false}) async {
    final storageRef = FirebaseStorage.instance.ref();
    final imagesRef =
        storageRef.child('$level/${DateTime.now().toIso8601String()}.jpeg');

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    final UploadTask uploadTask = imagesRef.putData(await image!.readAsBytes());
    final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
    final String imageUrl = await snapshot.ref.getDownloadURL();

    setState(() {
      this._image = imageUrl;
    });
  }

  Future<String> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != DateTime.now()) {
      return DateFormat('dd-MM-yyyy').format(picked);
    }
    return '';
  }

  Widget _showDatePickers() {
    if (widget.selectedOption == 'trip') {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _startDateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Data inizio',
                icon: Icon(Icons.date_range),
              ),
              onTap: () async {
                final String date = await _selectDate(context);
                setState(() {
                  _startDateController.text = date;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserire una data';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: TextFormField(
              controller: _endDateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Data fine',
                icon: Icon(Icons.date_range),
              ),
              onTap: () async {
                final String date = await _selectDate(context);
                setState(() {
                  _endDateController.text = date;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserire una data';
                }
                return null;
              },
            ),
          ),
        ],
      );
    } else {
      return TextFormField(
        controller: _startDateController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Data',
          icon: Icon(Icons.date_range),
        ),
        onTap: () async {
          final String date = await _selectDate(context);
          setState(() {
            _startDateController.text = date;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Inserire una data';
          }
          return null;
        },
      );
    }
  }

  bool _validate() {
    if (!_formKey.currentState!.validate()) return false;
    if (selectedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona almeno una classe'),
        ),
      );
      return false;
    }
    if (_image.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona un\'immagine'),
        ),
      );
      return false;
    }
    if (widget.selectedOption == 'trip') {
      DateTime start =
          DateFormat('dd-MM-yyyy').parse(_startDateController.text);
      DateTime end = DateFormat('dd-MM-yyyy').parse(_endDateController.text);
      if (start.isAfter(end)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'La data di inizio non può essere successiva a quella di fine'),
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _handleCreate(context) async {
    if (!_validate()) return;

    try {
      if (_address == '') {
        _address = 'Tiber Club';
        _latitude = '41.91805195';
        _longitude = '12.47788708';
      }

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      Map<String, dynamic> document = {
        'title': _programNameController.text,
        'selectedOption': widget.selectedOption,
        'imagePath': _image,
        'selectedClass': selectedClasses.sorted(),
        'description': _programDescriptionController.text,
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'address': _address,
        'lat': _latitude,
        'lon': _longitude,
      };
      Map weather = await fetchWeatherData(document['startDate'],
          document['endDate'], document['lat'], document['lon']);

      await firestore.collection('club_${widget.selectedOption}').add(document);

      List<String> token = [];
      for (String value in selectedClasses) {
        List<String> items = await fetchToken('club_class', value);
        for (String elem in items) {
          if (!token.contains(elem)) {
            token.add(elem);
          }
        }
      }
      sendNotification(token, 'Nuovo programma!', document['title'],
          'new_event', document, weather);
      Navigator.pop(context);
    } catch (e) {
      print('Errore durante la creazione dell\'evento: $e');
    }
  }

  Future<void> _handleEdit(context) async {
    if (!_validate()) return;

    Map<Object, Object?> newDocument = {
      'title': _programNameController.text,
      'selectedOption': widget.selectedOption,
      'imagePath': _image,
      'selectedClass': selectedClasses.sorted(),
      'description': _programDescriptionController.text,
      'startDate': _startDateController.text,
      'endDate': _endDateController.text,
      'address': _address,
      'lat': _latitude,
      'lon': _longitude,
    };
    print(newDocument);

    Map weather = await fetchWeatherData(newDocument['startDate'],
        newDocument['endDate'], newDocument['lat'], newDocument['lon']);

    for (var key in widget.document!.keys) {
      if (newDocument[key] == widget.document![key]) {
        newDocument.remove(key);
      }
    }

    await FirebaseFirestore.instance
        .collection('club_${widget.selectedOption}')
        .doc(widget.document?['id'])
        .update(newDocument);
    List<String> token = [];
    for (String value in selectedClasses) {
      List<String> items = await fetchToken('club_class', value);
      for (String elem in items) {
        if (!token.contains(elem)) {
          token.add(elem);
        }
      }
    }
    sendNotification(
      token,
      'Programma modificato!',
      newDocument['title'] ?? widget.document!['title'],
      'modified_event',
      newDocument,
      weather,
    );
    Navigator.pop(context);
  }

  Widget _smallLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? const Text('Modifica programma')
            : const Text('Crea programma'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200,
                  child: InkWell(
                    onTap: () async {
                      await _uploadImage('programs', isCreate: true);
                    },
                    child: _image.isNotEmpty
                        ? Container(
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[200]!,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: NetworkImage(_image),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.white.withOpacity(0.5),
                                  BlendMode.lighten,
                                ),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.edit,
                                size: 50,
                              ),
                            ),
                          )
                        : Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_a_photo,
                                size: 50,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _programNameController,
                  decoration: const InputDecoration(
                    labelText: 'Titolo',
                    icon: Icon(Icons.short_text),
                  ),
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  maxLength: 20,
                  validator: (String? value) {
                    if (value!.isEmpty) {
                      return 'Inserisci il nome del programma';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _programDescriptionController,
                  keyboardType: TextInputType.multiline,
                  minLines: 4,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione',
                    icon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 20),
                TypeAheadField(
                  controller: _programLocationController,
                  builder: (context, controller, focusNode) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: false,
                      decoration: InputDecoration(
                        labelText: (widget.selectedOption == 'trip')
                            ? 'Luogo'
                            : 'Luogo (facoltativo)',
                        icon: const Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (widget.selectedOption == 'trip' &&
                            (value == null || value.isEmpty)) {
                          return 'Inserire un indirizzo';
                        }
                        return null;
                      },
                    );
                  },
                  suggestionsCallback: (pattern) async {
                    return pattern == '' ? [] : await getSuggestions(pattern);
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      title: Text(suggestion["display_name"]),
                    );
                  },
                  onSelected: (suggestion) {
                    var address = suggestion["address"]["name"];
                    var number = suggestion["address"]["house_number"] ?? '';
                    var city = suggestion["address"]["city"] ?? '';
                    var country = suggestion["address"]["country"];
                    var lat = suggestion["lat"];
                    var lon = suggestion["lon"];

                    var completeAddress = '';
                    if (city != '' && number != '') {
                      if (country != 'Italia') {
                        completeAddress = '$address, $number, $city, $country';
                      } else {
                        completeAddress = '$address, $number, $city';
                      }
                    } else {
                      if (country != 'Italia') {
                        completeAddress = '$address, $country';
                      } else {
                        completeAddress = address;
                      }
                    }

                    setState(() {
                      this._latitude = lat;
                      this._longitude = lon;
                      this._address = completeAddress;
                      _programLocationController.text = completeAddress;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _showDatePickers(),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.class_rounded, color: Colors.black),
                    SizedBox(width: 25),
                    Text('Classi',
                        style: TextStyle(fontSize: 18, color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 10,
                  children: classOptions.map((e) {
                    return ChoiceChip(
                      label: Text(e),
                      selected: selectedClasses.contains(e),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedClasses.add(e);
                          } else {
                            selectedClasses.remove(e);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isEditing
                        ? ElevatedButton(
                            onPressed: () {
                              _handleEdit(context);
                            },
                            child: const Text('Modifica programma'),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              _handleCreate(context);
                            },
                            child: const Text('Crea programma'),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _largeLayout() {
    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? const Text('Modifica programma')
            : const Text('Crea programma'),
      ),
      body: const Center(
        child: Text('Large Layout'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      smallLayout: _smallLayout(context),
      largeLayout: _largeLayout(),
    );
  }
}
