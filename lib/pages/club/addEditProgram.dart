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

class AddEditProgram extends StatefulWidget {
  const AddEditProgram(
      {super.key,
      this.refreshList,
      this.refreshProgram,
      this.selectedOption,
      this.document,
      required this.name});

  final Function? refreshList;
  final Function? refreshProgram;
  final String? selectedOption;
  final Map<dynamic, dynamic>? document;
  final String name;

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
    '1° media',
    '2° media',
    '3° media',
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
      _image = imageUrl;
    });
  }

  Future<String> _selectDate(BuildContext context, String startDate) async {
    if (startDate == '') {
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
    } else {
      DateTime startDateDateTime = DateFormat('dd-MM-yyyy').parse(startDate);
      startDateDateTime = startDateDateTime.add(const Duration(days: 1));
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: startDateDateTime,
        firstDate: startDateDateTime,
        lastDate: DateTime(DateTime.now().year + 1),
      );
      if (picked != null && picked != DateTime.now()) {
        return DateFormat('dd-MM-yyyy').format(picked);
      }
      return '';
    }
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
                final String startDate = await _selectDate(context, '');
                setState(() {
                  _startDateController.text = startDate;
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
              enabled: _startDateController.text.isNotEmpty,
              decoration: const InputDecoration(
                labelText: 'Data fine',
                icon: Icon(Icons.date_range),
              ),
              onTap: () async {
                final String date =
                    await _selectDate(context, _startDateController.text);
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
          final String date = await _selectDate(context, '');
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
    setState(() {
        _isLoadingCreation = true;
      });
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
        'selectedClass': selectedClasses.sorted((a, b) {
          if (a.contains('media') && b.contains('liceo')) {
            return -1;
          } else if (a.contains('liceo') && b.contains('media')) {
            return 1;
          } else {
            return a.compareTo(b);
          }
        }),
        'description': _programDescriptionController.text,
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'address': _address,
        'lat': _latitude,
        'lon': _longitude,
        'creator': widget.name
      };

      var doc = await firestore
          .collection('club_${widget.selectedOption}')
          .add(document);
      document['id'] = doc.id;

      List<String> token = [];
      for (String value in selectedClasses) {
        List<String> items = await fetchToken('club_class', value);
        for (String elem in items) {
          if (!token.contains(elem)) {
            token.add(elem);
          }
        }
      }
      setState(() {
          _isLoadingCreation = false;
        });
      sendNotification(
          token, 'Nuovo programma!', document['title'], 'new_event',
          docId: doc.id, selectedOption: widget.selectedOption);
      widget.refreshList!();
      Navigator.pop(context);
    } catch (e) {
      setState(() {
          _isLoadingCreation = false;
        });
      print('Errore durante la creazione dell\'evento: $e');
    }
  }

  Future<void> _handleEdit(context) async {
    if (!_validate()) return;
    setState(() {
      _isLoadingModify = true;
    });
    Map<Object, Object?> newDocument = {
      'id': widget.document!['id'],
      'title': _programNameController.text,
      'selectedOption': widget.selectedOption,
      'imagePath': _image,
      'selectedClass': selectedClasses.sorted((a, b) {
        if (a.contains('media') && b.contains('liceo')) {
          return -1;
        } else if (a.contains('liceo') && b.contains('media')) {
          return 1;
        } else {
          return a.compareTo(b);
        }
      }),
      'description': _programDescriptionController.text,
      'startDate': _startDateController.text,
      'endDate': _endDateController.text,
      'address': _address,
      'lat': _latitude,
      'lon': _longitude,
      'creator': widget.name
    };

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
      docId: widget.document!['id'],
      selectedOption: widget.selectedOption,
    );

    for (var key in widget.document!.keys) {
      if (newDocument[key] == widget.document![key]) {
        newDocument.remove(key);
      }
    }

    await FirebaseFirestore.instance
        .collection('club_${widget.selectedOption}')
        .doc(widget.document?['id'])
        .update(newDocument);

    setState(() {
      _isLoadingModify = false;
    });

    widget.refreshProgram!();
    widget.refreshList!();
    Navigator.pop(context);
  }

  bool _isLoadingCreation = false;
  bool _isLoadingModify = false;

  @override
  Widget build(BuildContext context) {
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
                  autoFlipDirection: true,
                  hideOnEmpty: true,
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
                  decorationBuilder: (context, child) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(left: 40, top: 5, bottom: 5),
                      child: Material(
                        type: MaterialType.card,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: child,
                      ),
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
                      if (country != 'Italy') {
                        completeAddress = '$address, $number, $city, $country';
                      } else {
                        completeAddress = '$address, $number, $city';
                      }
                    } else {
                      if (country != 'Italy') {
                        completeAddress = '$address, $country';
                      } else {
                        completeAddress = address;
                      }
                    }

                    setState(() {
                      _latitude = lat;
                      _longitude = lon;
                      _address = completeAddress;
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
                              if (_isLoadingModify) {
                                null;
                              } else {
                                _handleEdit(context);
                              }
                            },
                            child: _isLoadingModify
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Modifica programma',
                                    style: TextStyle(color: Colors.white)),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              if (_isLoadingCreation) {
                                null;
                              } else {
                                _handleCreate(context);
                              }
                            },
                            child: _isLoadingCreation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Crea programma',
                                    style: TextStyle(color: Colors.white)),
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
}
