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
import 'visibility.dart';
import 'programPage.dart';

class AddEditProgram extends StatefulWidget {
  const AddEditProgram(
      {super.key,
      required this.club,
      this.refreshList,
      this.refreshProgram,
      this.selectedOption,
      this.document,
      required this.name,
      this.selectedDay,
      this.visibility,
      required this.role,
      required this.classes});

  final String club;
  final Function? refreshList;
  final Function? refreshProgram;
  final String? selectedOption;
  final Map<dynamic, dynamic>? document;
  final String name;
  final selectedDay;
  final Map<String, bool>? visibility;
  final String role;
  final List classes;

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

  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  final timeController = TextEditingController();

  bool _isLoadingCreation = false;

  final Map<String, bool> _visibility = {};
  List selected = [];
  List modifiedUsers = [];
  List<String> users = [];
  bool tutor = true;

  String _image = '';
  String _address = '';
  String _latitude = '';
  String _longitude = '';
  final List<String> tiberClassOptions = [
    '4° elem',
    '5° elem',
    '1° media',
    '2° media',
    '3° media',
    '1° liceo',
    '2° liceo',
    '3° liceo',
    '4° liceo',
    '5° liceo',
    '6° liceo'
  ];
  final List<String> deltaClassOptions = [
    '1° liceo',
    '2° liceo',
    '3° liceo',
    '4° liceo',
    '5° liceo',
  ];
  final List<String> rampaClassOptions = [
    '1° liceo',
    '2° liceo',
    '3° liceo',
    '4° liceo',
    '5° liceo',
  ];
  List<String> selectedClasses = [];
  bool modifiedNotification = false;
  String time = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (widget.document != null) {
      _isEditing = true;
      if (widget.selectedOption == 'evento') {
        _programNameController.text = widget.document!['titolo'];
        _programDescriptionController.text = widget.document!['descrizione'];
        _startTimeController.text = widget.document!['inizio'];
        _endTimeController.text = widget.document!['fine'];
        modifiedUsers = widget.document!['utenti'];
        if (Set.from(modifiedUsers).containsAll(users) &&
            Set.from(users).containsAll(modifiedUsers)) {
          tutor = true;
        } else {
          for (var user in modifiedUsers) {
            _visibility[user] = true;
          }
          setState(() {
            tutor = false;
          });
        }
      } else {
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
        reservations =
            widget.document!.containsKey('prenotazioni') ? true : false;
        food = widget.document!.containsKey('pasto') ? true : false;
        timeController.text = widget.document!.containsKey('pasto')
            ? widget.document!['pasto']
            : '';
        _startTimeController.text = widget.document!['inizio'];
        _endTimeController.text = widget.document!['fine'];
      }
    } else {
      final String formattedDate =
          DateFormat('dd-MM-yyyy').format(widget.selectedDay);
      setState(() {
        _startDateController.text = formattedDate;
      });
    }
    await _fetchTutors();
  }

  Future<void> _fetchTutors() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('role', isEqualTo: 'Tutor')
        .where('club', isEqualTo: widget.club)
        .get();

    for (var doc in querySnapshot.docs) {
      final email = doc['email'] as String;
      users.add(email);
    }
  }

  bool _isUploading = false;

  Future<void> _uploadImage(String level, {bool isCreate = false}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isUploading = true;
      });

      final storageRef = FirebaseStorage.instance.ref();
      final imagesRef =
          storageRef.child('$level/${DateTime.now().toIso8601String()}.jpeg');

      final UploadTask uploadTask =
          imagesRef.putData(await image.readAsBytes());
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      final String imageUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _image = imageUrl;
        _isUploading = false;
      });
    }
  }

  Future<String?> _selectDate(BuildContext context, String startDate) async {
    _unfocusAll();
    DateTime initialDate;
    if (startDate.isEmpty) {
      initialDate = DateTime.now();
    } else {
      DateTime startDateDateTime = DateFormat('dd-MM-yyyy').parse(startDate);
      initialDate = startDateDateTime.add(const Duration(days: 1));
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: initialDate,
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (picked != null && picked != initialDate) {
      return DateFormat('dd-MM-yyyy').format(picked);
    } else if (picked != null &&
        picked == initialDate &&
        widget.selectedOption == 'trip') {
      return DateFormat('dd-MM-yyyy').format(picked);
    }
    return null;
  }

  Widget _showDatePickers() {
    _unfocusAll();
    if (widget.selectedOption == 'trip') {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _startDateController,
              focusNode: _startDateFocusNode,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Data inizio',
                icon: Icon(Icons.date_range),
              ),
              onTap: () async {
                final String? startDate = await _selectDate(context, '');
                if (startDate != null) {
                  setState(() {
                    _startDateController.text = startDate;
                  });
                }
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
              focusNode: _endDateFocusNode,
              readOnly: true,
              enabled: _startDateController.text.isNotEmpty,
              decoration: const InputDecoration(
                labelText: 'Data fine',
                icon: Icon(Icons.date_range),
              ),
              onTap: () async {
                final String? date =
                    await _selectDate(context, _startDateController.text);
                if (date != null) {
                  setState(() {
                    _endDateController.text = date;
                  });
                }
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
        focusNode: _startDateFocusNode,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Data',
          icon: Icon(Icons.date_range),
        ),
        onTap: () async {
          final String? date = await _selectDate(context, '');
          if (date != null) {
            setState(() {
              _startDateController.text = date;
            });
          }
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

  Future<String?> _selectTime() async {
    _unfocusAll();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      return DateFormat('HH:mm').format(selectedDateTime);
    }
    return null;
  }

  Widget _showTimePicker() {
    _unfocusAll();
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _startTimeController,
            focusNode: _startTimeFocusNode,
            readOnly: true,
            decoration: InputDecoration(
              icon: const Icon(Icons.schedule),
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.selectedOption=='trip'? const Text('Ora partenza') : const Text('Ora inizio'),
                  const Text(
                    '(facoltativo)',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () async {
              final String? orario = await _selectTime();
              if (orario != null) {
                setState(() {
                  _startTimeController.text = orario;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: TextFormField(
            controller: _endTimeController,
            focusNode: _endTimeFocusNode,
            readOnly: true,
            enabled: _startTimeController.text.isNotEmpty,
            decoration: InputDecoration(
              icon: const Icon(Icons.schedule),
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.selectedOption=='trip'? const Text('Ora arrivo') : const Text('Ora fine'),
                  const Text(
                    '(facoltativo)',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () async {
              final String? orario = await _selectTime();
              if (orario != null) {
                setState(() {
                  _endTimeController.text = orario;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  bool _validate() {
    if (!_formKey.currentState!.validate()) return false;
    if (selectedClasses.isEmpty && widget.selectedOption != 'evento') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona almeno una classe'),
        ),
      );
      return false;
    }
    if (_image.isEmpty && widget.selectedOption != 'evento') {
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
      final String startTimeText = _startTimeController.text;
      final String endTimeText = _endTimeController.text;

      if (startTimeText.isNotEmpty && endTimeText.isNotEmpty) {
        try {
          final now = DateTime.now();

          final DateTime startDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(startTimeText.split(':')[0]),
            int.parse(startTimeText.split(':')[1]),
          );
          final DateTime endDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(endTimeText.split(':')[0]),
            int.parse(endTimeText.split(':')[1]),
          );

          if (startDateTime.isAfter(endDateTime) && widget.selectedOption!='trip') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'L\'orario iniziale non può essere dopo l\'orario finale'),
              ),
            );
            return false;
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Formato orario non valido'),
            ),
          );
          return false;
        }
      } else if (startTimeText.isEmpty && endTimeText.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inserisci l\'ora d\'inizio'),
          ),
        );
        return false;
      } else {
        return true;
      }

    return true;
  }

  Future<void> _handleCreate(context) async {
    if (!_validate()) return;
    setState(() {
      _isLoadingCreation = true;
    });
    if (widget.selectedOption == 'evento') {
      try {
        FirebaseFirestore firestore = FirebaseFirestore.instance;
        Map<String, dynamic> document = {
          'titolo': _programNameController.text,
          'descrizione': _programDescriptionController.text,
          'data': widget.selectedDay,
          'creatore': widget.name,
          'club': widget.club,
          'inizio': _startTimeController.text,
          'fine': _endTimeController.text,
          'utenti': selected.isEmpty ? users : selected,
        };

        await firestore.collection('calendario').add(document);

        setState(() {
          _isLoadingCreation = false;
        });
        widget.refreshList!();
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isLoadingCreation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante la creazione dell\'evento'),
          ),
        );
      }
    } else {
      try {
        if (_address == '') {
          if (widget.club == 'Tiber Club') {
            _address = 'Tiber Club';
            _latitude = '41.91805195';
            _longitude = '12.47788708';
          } else if (widget.club == 'Delta Club') {
            _address = 'Centro Delta';
            _latitude = '45.468245';
            _longitude = '9.164332';
          } else if (widget.club == 'Rampa Club') {
            _address = 'Rampa Club';
            _latitude = '45.5382134';
            _longitude = '9.2352257';
          }
        }

        FirebaseFirestore firestore = FirebaseFirestore.instance;
        Map<String, dynamic> document = {};

        if (reservations) {
          if (food) {
            document = {
              'title': _programNameController.text,
              'selectedOption': widget.selectedOption,
              'imagePath': _image,
              'selectedClass': selectedClasses.sorted((a, b) {
                int getPriority(String item) {
                  if (item.contains('elem')) {
                    return 0;
                  } else if (item.contains('media')) {
                    return 1;
                  } else if (item.contains('liceo')) {
                    return 2;
                  } else {
                    return 3;
                  }
                }

                final int priorityA = getPriority(a);
                final int priorityB = getPriority(b);
                if (priorityA != priorityB) {
                  return priorityA - priorityB;
                }
                return a.compareTo(b);
              }),
              'description': _programDescriptionController.text,
              'startDate': _startDateController.text,
              'endDate': _endDateController.text,
              'address': _address,
              'lat': _latitude,
              'lon': _longitude,
              'creator': widget.name,
              'club': widget.club,
              'prenotazioni': [],
              'assenze': [],
              'pasto': timeController.text,
              'prenotazionePranzo': [],
              'assenzaPranzo': [],
              'inizio': _startTimeController.text,
              'fine': _endTimeController.text,
            };
          } else {
            document = {
              'title': _programNameController.text,
              'selectedOption': widget.selectedOption,
              'imagePath': _image,
              'selectedClass': selectedClasses.sorted((a, b) {
                int getPriority(String item) {
                  if (item.contains('elem')) {
                    return 0;
                  } else if (item.contains('media')) {
                    return 1;
                  } else if (item.contains('liceo')) {
                    return 2;
                  } else {
                    return 3;
                  }
                }

                final int priorityA = getPriority(a);
                final int priorityB = getPriority(b);
                if (priorityA != priorityB) {
                  return priorityA - priorityB;
                }
                return a.compareTo(b);
              }),
              'description': _programDescriptionController.text,
              'startDate': _startDateController.text,
              'endDate': _endDateController.text,
              'address': _address,
              'lat': _latitude,
              'lon': _longitude,
              'creator': widget.name,
              'club': widget.club,
              'prenotazioni': [],
              'assenze': [],
              'inizio': _startTimeController.text,
              'fine': _endTimeController.text,
            };
          }
        } else {
          if (food) {
            document = {
              'title': _programNameController.text,
              'selectedOption': widget.selectedOption,
              'imagePath': _image,
              'selectedClass': selectedClasses.sorted((a, b) {
                int getPriority(String item) {
                  if (item.contains('elem')) {
                    return 0;
                  } else if (item.contains('media')) {
                    return 1;
                  } else if (item.contains('liceo')) {
                    return 2;
                  } else {
                    return 3;
                  }
                }

                final int priorityA = getPriority(a);
                final int priorityB = getPriority(b);
                if (priorityA != priorityB) {
                  return priorityA - priorityB;
                }
                return a.compareTo(b);
              }),
              'description': _programDescriptionController.text,
              'startDate': _startDateController.text,
              'endDate': _endDateController.text,
              'address': _address,
              'lat': _latitude,
              'lon': _longitude,
              'creator': widget.name,
              'club': widget.club,
              'pasto': timeController.text,
              'prenotazionePranzo': [],
              'assenzaPranzo': [],
              'inizio': _startTimeController.text,
              'fine': _endTimeController.text,
            };
          } else {
            document = {
              'title': _programNameController.text,
              'selectedOption': widget.selectedOption,
              'imagePath': _image,
              'selectedClass': selectedClasses.sorted((a, b) {
                int getPriority(String item) {
                  if (item.contains('elem')) {
                    return 0;
                  } else if (item.contains('media')) {
                    return 1;
                  } else if (item.contains('liceo')) {
                    return 2;
                  } else {
                    return 3;
                  }
                }

                final int priorityA = getPriority(a);
                final int priorityB = getPriority(b);
                if (priorityA != priorityB) {
                  return priorityA - priorityB;
                }
                return a.compareTo(b);
              }),
              'description': _programDescriptionController.text,
              'startDate': _startDateController.text,
              'endDate': _endDateController.text,
              'address': _address,
              'lat': _latitude,
              'lon': _longitude,
              'creator': widget.name,
              'club': widget.club,
              'inizio': _startTimeController.text,
              'fine': _endTimeController.text,
            };
          }
        }

        var doc = await firestore
            .collection('club_${widget.selectedOption}')
            .add(document);
        document['id'] = doc.id;

        List<String> token = [];
        for (String value in selectedClasses) {
          List<String> items =
              await fetchToken('club_class', value, widget.club);
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
            docId: doc.id,
            selectedOption: widget.selectedOption,
            role: widget.role);
        widget.refreshList!();
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => ProgramPage(
                  club: widget.club,
                  documentId: doc.id,
                  selectedOption: widget.selectedOption ?? '',
                  isAdmin: true,
                  refreshList: widget.refreshList,
                  name: widget.name,
                  role: widget.role,
                  classes: widget.classes,
                )));
      } catch (e) {
        setState(() {
          _isLoadingCreation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante la creazione dell\'evento'),
          ),
        );
      }
    }
  }

  Future<void> _handleEdit(context) async {
    if (!_validate()) return;
    setState(() {
      _isLoadingModify = true;
    });
    if (widget.selectedOption == 'evento') {
      Map<String, dynamic> newDocument = {
        'titolo': _programNameController.text,
        'descrizione': _programDescriptionController.text,
        'data': widget.selectedDay,
        'creatore': widget.name,
        'club': widget.club,
        'inizio': _startTimeController.text,
        'fine': _endTimeController.text,
        'utenti': selected,
      };

      await FirebaseFirestore.instance
          .collection('calendario')
          .doc(widget.document?['id'])
          .update(newDocument);

      setState(() {
        _isLoadingModify = false;
      });
      widget.refreshProgram!();
    } else {
      Map<Object, Object?> newDocument = {};
      if (reservations) {
        newDocument = {
          'id': widget.document!['id'],
          'title': _programNameController.text,
          'selectedOption': widget.selectedOption,
          'imagePath': _image,
          'selectedClass': selectedClasses.sorted((a, b) {
            int getPriority(String item) {
              if (item.contains('elem')) {
                return 0;
              } else if (item.contains('media')) {
                return 1;
              } else if (item.contains('liceo')) {
                return 2;
              } else {
                return 3;
              }
            }
            final int priorityA = getPriority(a);
            final int priorityB = getPriority(b);
            if (priorityA != priorityB) {
              return priorityA - priorityB;
            }
            return a.compareTo(b);
          }),
          'description': _programDescriptionController.text,
          'startDate': _startDateController.text,
          'endDate': _endDateController.text,
          'address': _address,
          'lat': _latitude,
          'lon': _longitude,
          'creator': widget.name,
          'club': widget.club,
          'prenotazioni': widget.document!.containsKey('prenotazioni')
              ? widget.document!['prenotazioni']
              : [],
          'assenze': widget.document!.containsKey('assenze')
              ? widget.document!['assenze']
              : [],
          'inizio': _startTimeController.text,
          'fine': _endTimeController.text,
        };
      } else {
        if (widget.document!.containsKey('prenotazioni')) {
          newDocument = {
            'id': widget.document!['id'],
            'title': _programNameController.text,
            'selectedOption': widget.selectedOption,
            'imagePath': _image,
            'selectedClass': selectedClasses.sorted((a, b) {
              int getPriority(String item) {
                if (item.contains('elem')) {
                  return 0;
                } else if (item.contains('media')) {
                  return 1;
                } else if (item.contains('liceo')) {
                  return 2;
                } else {
                  return 3;
                }
              }
              final int priorityA = getPriority(a);
              final int priorityB = getPriority(b);
              if (priorityA != priorityB) {
                return priorityA - priorityB;
              }
              return a.compareTo(b);
            }),
            'description': _programDescriptionController.text,
            'startDate': _startDateController.text,
            'endDate': _endDateController.text,
            'address': _address,
            'lat': _latitude,
            'lon': _longitude,
            'creator': widget.name,
            'club': widget.club,
            'prenotazioni': FieldValue.delete(),
            'assenze': FieldValue.delete(),
            'inizio': _startTimeController.text,
            'fine': _endTimeController.text,
          };
        } else {
          newDocument = {
            'id': widget.document!['id'],
            'title': _programNameController.text,
            'selectedOption': widget.selectedOption,
            'imagePath': _image,
            'selectedClass': selectedClasses.sorted((a, b) {
              int getPriority(String item) {
                if (item.contains('elem')) {
                  return 0;
                } else if (item.contains('media')) {
                  return 1;
                } else if (item.contains('liceo')) {
                  return 2;
                } else {
                  return 3;
                }
              }
              final int priorityA = getPriority(a);
              final int priorityB = getPriority(b);
              if (priorityA != priorityB) {
                return priorityA - priorityB;
              }
              return a.compareTo(b);
            }),
            'description': _programDescriptionController.text,
            'startDate': _startDateController.text,
            'endDate': _endDateController.text,
            'address': _address,
            'lat': _latitude,
            'lon': _longitude,
            'creator': widget.name,
            'club': widget.club,
            'inizio': _startTimeController.text,
            'fine': _endTimeController.text,
          };
        }
      }

      if (food) {
        newDocument['pasto'] = timeController.text;
        newDocument['prenotazionePranzo'] =
            widget.document!.containsKey('prenotazionePranzo')
                ? widget.document!['prenotazionePranzo']
                : [];
        newDocument['assenzaPranzo'] =
            widget.document!.containsKey('assenzaPranzo')
                ? widget.document!['assenzaPranzo']
                : [];
      } else {
        if (widget.document!.containsKey('prenotazionePranzo')) {
          newDocument['pasto'] = FieldValue.delete();
          newDocument['prenotazionePranzo'] = FieldValue.delete();
          newDocument['assenzaPranzo'] = FieldValue.delete();
        }
      }

      if (modifiedNotification) {
        List<String> token = [];
        for (String value in selectedClasses) {
          List<String> items =
              await fetchToken('club_class', value, widget.club);
          for (String elem in items) {
            if (!token.contains(elem)) {
              token.add(elem);
            }
          }
        }
        sendNotification(token, 'Programma modificato!',
            newDocument['title'] ?? widget.document!['title'], 'modified_event',
            docId: widget.document!['id'],
            selectedOption: widget.selectedOption,
            role: widget.role);
      }

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
    }
    Navigator.pop(context);
  }

  bool _isLoadingModify = false;

  final FocusNode _programNameFocusNode = FocusNode();
  final FocusNode _programLocationFocusNode = FocusNode();
  final FocusNode _programDescriptionFocusNode = FocusNode();
  final FocusNode _startTimeFocusNode = FocusNode();
  final FocusNode _endTimeFocusNode = FocusNode();
  final FocusNode _startDateFocusNode = FocusNode();
  final FocusNode _endDateFocusNode = FocusNode();

  void _unfocusAll() {
    _programNameFocusNode.unfocus();
    _programLocationFocusNode.unfocus();
    _programDescriptionFocusNode.unfocus();
    _startTimeFocusNode.unfocus();
    _endTimeFocusNode.unfocus();
    _startDateFocusNode.unfocus();
    _endDateFocusNode.unfocus();
    _timeFocusNode.unfocus();
  }

  @override
  void dispose() {
    _programNameFocusNode.dispose();
    _programLocationFocusNode.dispose();
    _programDescriptionFocusNode.dispose();
    _startTimeFocusNode.dispose();
    _endTimeFocusNode.dispose();
    _startDateFocusNode.dispose();
    _endDateFocusNode.dispose();
    _timeFocusNode.dispose();
    super.dispose();
  }

  bool reservations = false;
  bool food = false;

  TimeOfDay? selectedTime;
  final FocusNode _timeFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.selectedOption == 'evento' && _isEditing
            ? const Text('Modifica evento')
            : widget.selectedOption == 'evento'
                ? const Text('Crea evento')
                : widget.selectedOption == 'weekend' && _isEditing
                    ? const Text('Modifica programma')
                    : widget.selectedOption == 'weekend'
                        ? const Text('Crea programma')
                        : _isEditing
                            ? const Text('Modifica convivenza')
                            : const Text('Crea convivenza'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.selectedOption != 'evento') ...[
                  SizedBox(
                    height: 200,
                    child: InkWell(
                      onTap: () async {
                        _unfocusAll();
                        await _uploadImage('programs', isCreate: true);
                      },
                      child: _isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : _image.isNotEmpty
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
                                        Colors.white.withValues(alpha: 0.5),
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
                ],
                TextFormField(
                  controller: _programNameController,
                  focusNode: _programNameFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Titolo',
                    icon: Icon(Icons.short_text),
                  ),
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  maxLength: widget.selectedOption != 'evento' ? 20 : null,
                  validator: (String? value) {
                    if (value!.isEmpty) {
                      return 'Inserisci il nome del programma';
                    }
                    return null;
                  },
                ),
                if (widget.selectedOption == 'evento') ...[
                  const SizedBox(height: 20),
                  _showTimePicker(),
                ],
                if (widget.selectedOption != 'evento') ...[
                  const SizedBox(height: 20),
                  _showDatePickers(),
                  const SizedBox(height: 20),
                  _showTimePicker(),
                  const SizedBox(height: 20),
                  TypeAheadField(
                    controller: _programLocationController,
                    focusNode: _programLocationFocusNode,
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
                          completeAddress =
                              '$address, $number, $city, $country';
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
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _programDescriptionController,
                  focusNode: _programDescriptionFocusNode,
                  keyboardType: TextInputType.multiline,
                  minLines: 4,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione (facoltativo)',
                    icon: Icon(Icons.description),
                  ),
                ),
                if (widget.selectedOption != 'evento') ...[
                  const SizedBox(height: 20),
                  Row(children: [
                    const Icon(Icons.check_circle),
                    const SizedBox(width: 5),
                    Expanded(
                      child: ListTile(
                        title: const Text('Prenotazione',
                            style: TextStyle(fontSize: 20)),
                        trailing: Switch(
                          value: reservations,
                          onChanged: (bool value) {
                            setState(() {
                              reservations = value;
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            reservations = !reservations;
                          });
                        },
                      ),
                    ),
                  ]),
                  if (widget.selectedOption == 'weekend') ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.fastfood),
                      const SizedBox(width: 5),
                      Expanded(
                        child: ListTile(
                          title: const Text('Crea pasto',
                              style: TextStyle(fontSize: 20)),
                          trailing: Switch(
                            value: food,
                            onChanged: (bool value) {
                              setState(() {
                                food = value;
                                if (food == false) {
                                  timeController.text = '';
                                }
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              food = !food;
                            });
                          },
                        ),
                      ),
                    ]),
                  ],
                  if (food) ...[
                    const SizedBox(height: 5),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Ora'),
                      readOnly: true,
                      controller: timeController,
                      focusNode: _timeFocusNode,
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        _unfocusAll();
                        if (pickedTime != null) {
                          setState(() {
                            selectedTime = pickedTime;
                            timeController.text = selectedTime!.format(context);
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Seleziona un orario';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (_isEditing) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.notification_add),
                      const SizedBox(width: 5),
                      Expanded(
                        child: ListTile(
                          title: const Text('Inviare notifica',
                              style: TextStyle(fontSize: 20)),
                          trailing: Switch(
                            value: modifiedNotification,
                            onChanged: (bool value) {
                              setState(() {
                                modifiedNotification = value;
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              modifiedNotification = !modifiedNotification;
                            });
                          },
                        ),
                      ),
                    ]),
                  ],
                ],
                if (widget.selectedOption == 'evento') ...[
                  const SizedBox(height: 20),
                  ListTile(
                      title: const Text('Visibilità'),
                      subtitle: Text(tutor ? 'solo tutor' : 'Personalizzata'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () async {
                        _unfocusAll();
                        selected = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VisibilitySelectionPage(
                                visibility: _visibility, club: widget.club),
                          ),
                        );
                        setState(() {
                          if (Set.from(selected).containsAll(users) &&
                              Set.from(users).containsAll(selected)) {
                            tutor = true;
                          } else {
                            for (var user in selected) {
                              _visibility[user] = true;
                            }
                            tutor = false;
                          }
                        });
                      }),
                ],
                if (widget.selectedOption != 'evento') ...[
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
                      children: widget.club == 'Tiber Club'
                          ? tiberClassOptions.map((e) {
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
                            }).toList()
                          : widget.club == 'Rampa Club' ?
                            rampaClassOptions.map((e) {
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
                            }).toList()
                          : deltaClassOptions.map((e) {
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
                            }).toList()),
                ],
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
                                : const Text('Modifica',
                                    style: TextStyle(color: Colors.white)))
                        : ElevatedButton(
                            onPressed: () {
                              if (_isLoadingModify) {
                                null;
                              } else {
                                _handleCreate(context);
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
                                : const Text('Crea',
                                    style: TextStyle(color: Colors.white))),
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
