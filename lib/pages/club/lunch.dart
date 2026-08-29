import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class Lunch extends StatefulWidget {
  const Lunch(
      {super.key,
      required this.isAdmin,
      required this.name,
      required this.role,
      required this.club,
      required this.classes});

  final bool isAdmin;
  final String name;
  final String role;
  final String club;
  final List classes;

  @override
  _LunchState createState() => _LunchState();
}

class _LunchState extends State<Lunch> {
  Future<List<Map<String, dynamic>>> _fetchMeals() async {
    try {
      final querySnapshot = widget.isAdmin
          ? await FirebaseFirestore.instance.collection('pasti').get()
          : await FirebaseFirestore.instance
              .collection('pasti')
              .where('classi', arrayContainsAny: widget.classes)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      } else {
        List<Map<String, dynamic>> meals = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'data': doc['data'],
            'orario': doc['orario'],
            'giorno': doc['giorno'],
            'prenotazioni': doc['prenotazioni'],
            'appuntamento': doc['appuntamento'],
            'id': doc.id,
            'default': doc['default'],
            'status': doc['status'],
            'modificato': doc['modificato'],
            'classi': doc['classi'],
            'amici': data.containsKey('amici') ? doc['amici'] : {},
          };
        }).toList();

        for (var meal in meals) {
          await _checkAndUpdateMealStatus(meal);
        }

        meals.sort((a, b) {
          DateTime dateA = DateFormat('dd-MM-yyyy').parse(a['appuntamento']);
          DateTime dateB = DateFormat('dd-MM-yyyy').parse(b['appuntamento']);

          if (dateA.isBefore(dateB)) {
            return -1;
          } else if (dateA.isAfter(dateB)) {
            return 1;
          } else {
            int timeA = _timeToMinutes(a['orario']);
            int timeB = _timeToMinutes(b['orario']);
            return timeA.compareTo(timeB);
          }
        });
        return meals;
      }
    } catch (e) {
      return [];
    }
  }

  int _timeToMinutes(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour * 60 + minute;
  }

  Future<void> _checkAndUpdateMealStatus(Map<String, dynamic> meal) async {
    if (meal['default'] == false &&
        meal['status'] == 'aperto' &&
        meal['modificato'] == false) {
      DateTime now = DateTime.now();
      DateTime mealDate = DateFormat('dd-MM-yyyy').parse(meal['appuntamento']);
      TimeOfDay mealTime = TimeOfDay(
        hour: int.parse(meal['orario'].split(":")[0]),
        minute: int.parse(meal['orario'].split(":")[1]),
      );

      DateTime mealDateTime = DateTime(
        mealDate.year,
        mealDate.month,
        mealDate.day,
        mealTime.hour,
        mealTime.minute,
      );

      bool isToday = mealDate.year == now.year &&
          mealDate.month == now.month &&
          mealDate.day == now.day;

      if (isToday &&
          (mealDateTime.isBefore(now) ||
              mealDateTime.difference(now).inMinutes <= 30)) {
        await FirebaseFirestore.instance
            .collection('pasti')
            .doc(meal['id'])
            .update({'status': 'chiuso'});
        meal['status'] = 'chiuso';
      }
    }
  }

  @override
  void initState() {
    super.initState();
    deleteOldDocuments();
  }

  void deleteOldDocuments() async {
    final firestore = FirebaseFirestore.instance;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    final querySnapshot = await firestore.collection('pasti').get();
    for (final document in querySnapshot.docs) {
      final startDateString = document.data()['appuntamento'] as String;
      final startDate =
          DateTime.parse(startDateString.split('-').reversed.join('-'));
      if (startDate.isBefore(yesterday)) {
        await document.reference.delete();
      }
    }
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (picked != null && picked != DateTime.now()) {
      _unfocusAll();
      return picked;
    }
    _unfocusAll();
    return null;
  }

  final FocusNode _dateFocusNode = FocusNode();
  final FocusNode _timeFocusNode = FocusNode();

  void _unfocusAll() {
    _dateFocusNode.unfocus();
    _timeFocusNode.unfocus();
  }

  // --- Amici (Friends) Management ---

  final Map<String, TextEditingController> _amiciControllers = {};

  TextEditingController _getAmiciController(String mealId) {
    if (!_amiciControllers.containsKey(mealId)) {
      _amiciControllers[mealId] = TextEditingController();
    }
    return _amiciControllers[mealId]!;
  }

  List<String> _getMyAmici(Map<String, dynamic> meal) {
    if (!meal.containsKey('amici') || meal['amici'] == null) return [];
    Map<String, dynamic> amici = meal['amici'];
    if (!amici.containsKey(widget.name)) return [];
    return List<String>.from(amici[widget.name]);
  }

  List<String> _getAllPresenti(Map<String, dynamic> meal) {
    List<String> result = List<String>.from(meal['prenotazioni'] ?? []);
    if (meal.containsKey('amici') && meal['amici'] != null) {
      Map<String, dynamic> amici = meal['amici'];
      amici.forEach((key, value) {
        result.addAll((value as List).cast<String>());
      });
    }
    return result;
  }

  Future<void> _addAmico(Map<String, dynamic> meal, String name) async {
    if (name.trim().isEmpty) return;
    Map<String, dynamic> amici = meal.containsKey('amici') && meal['amici'] != null
        ? Map<String, dynamic>.from(meal['amici'])
        : {};
    List<String> myAmici = amici.containsKey(widget.name)
        ? List<String>.from(amici[widget.name])
        : [];
    myAmici.add(name.trim());
    amici[widget.name] = myAmici;

    await FirebaseFirestore.instance
        .collection('pasti')
        .doc(meal['id'])
        .update({'amici': amici});

    setState(() {
      meal['amici'] = amici;
      _getAmiciController(meal['id']).clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${name.trim()} aggiunto ai presenti')));
  }

  Future<void> _removeAmico(Map<String, dynamic> meal, String name) async {
    Map<String, dynamic> amici = Map<String, dynamic>.from(meal['amici']);
    List<String> myAmici = List<String>.from(amici[widget.name]);
    myAmici.remove(name);
    if (myAmici.isEmpty) {
      amici.remove(widget.name);
    } else {
      amici[widget.name] = myAmici;
    }

    await FirebaseFirestore.instance
        .collection('pasti')
        .doc(meal['id'])
        .update({'amici': amici});

    setState(() {
      meal['amici'] = amici;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name rimosso dai presenti')));
  }

  Future<void> _editAmico(Map<String, dynamic> meal, String oldName, String newName) async {
    if (newName.trim().isEmpty) return;
    Map<String, dynamic> amici = Map<String, dynamic>.from(meal['amici']);
    List<String> myAmici = List<String>.from(amici[widget.name]);
    int index = myAmici.indexOf(oldName);
    if (index != -1) {
      myAmici[index] = newName.trim();
    }
    amici[widget.name] = myAmici;

    await FirebaseFirestore.instance
        .collection('pasti')
        .doc(meal['id'])
        .update({'amici': amici});

    setState(() {
      meal['amici'] = amici;
    });
  }

  void _showEditAmicoDialog(Map<String, dynamic> meal, String name) {
    TextEditingController editController = TextEditingController(text: name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica amico'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: 'Nome amico'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              _editAmico(meal, name, editController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAmicoDialog(Map<String, dynamic> meal, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina amico'),
        content: Text('Vuoi eliminare "$name" dalla lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              _removeAmico(meal, name);
              Navigator.of(context).pop();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  Widget _buildAmiciContainer(Map<String, dynamic> meal) {
    final controller = _getAmiciController(meal['id']);
    final myFriends = _getMyAmici(meal);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add, size: 30, color: Colors.black),
              const SizedBox(width: 10),
              const AutoSizeText(
                'Aggiungi amici',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 1,
                minFontSize: 15,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Nome amico',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (value) => _addAmico(meal, value),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _addAmico(meal, controller.text),
                icon: const Icon(Icons.add_circle,
                    color: Colors.black, size: 35),
              ),
            ],
          ),
          if (myFriends.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(),
            ...myFriends.map<Widget>((name) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: AutoSizeText(
                    name,
                    style: const TextStyle(fontSize: 18),
                    maxLines: 1,
                    minFontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showEditAmicoDialog(meal, name),
                        icon: const Icon(Icons.edit,
                            color: Colors.black, size: 22),
                      ),
                      IconButton(
                        onPressed: () => _showDeleteAmicoDialog(meal, name),
                        icon: const Icon(Icons.delete,
                            color: Colors.black, size: 22),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dateFocusNode.dispose();
    _timeFocusNode.dispose();
    for (var controller in _amiciControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _showAddMealDialog() async {
    _unfocusAll();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final dateController = TextEditingController();
        final timeController = TextEditingController();

        return AlertDialog(
          title: const Text('Aggiungi un pasto'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Data'),
                      readOnly: true,
                      controller: dateController,
                      focusNode: _dateFocusNode,
                      onTap: () async {
                        selectedDate = await _selectDate(context);
                        if (selectedDate != null) {
                          setState(() {
                            dateController.text =
                                DateFormat('dd/MM/yyyy').format(selectedDate!);
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Seleziona una data';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
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
                        if (selectedTime == null) {
                          return 'Seleziona un orario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    buildDropdownClasse(
                        "Classe",
                        widget.club == 'Tiber Club'
                            ? tiberClubClassOptions
                            : deltaClubClassOptions, (value) {
                      setState(() {
                        selectedClubClass = value.toString();
                      });
                    }),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Crea'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await FirebaseFirestore.instance.collection('pasti').add({
                    'data': DateFormat('dd', 'it_IT')
                        .format(selectedDate!)
                        .toUpperCase(),
                    'giorno': DateFormat('EEEE', 'it_IT')
                        .format(selectedDate!)
                        .toUpperCase(),
                    'orario': selectedTime!.format(context),
                    'prenotazioni': [],
                    'appuntamento':
                        DateFormat('dd-MM-yyyy').format(selectedDate!),
                    'default': false,
                    'status': 'aperto',
                    'modificato': false,
                    'classi': classList,
                  });
                  Navigator.of(context).pop();
                  setState(() {});
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleReservation(var meal) async {
    List<dynamic> prenotazioni = meal['prenotazioni'];
    if (prenotazioni.contains(widget.name)) {
      prenotazioni.remove(widget.name);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Presenza cancellata')));
    } else {
      prenotazioni.add(widget.name);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Presenza confermata')));
    }

    await FirebaseFirestore.instance
        .collection('pasti')
        .doc(meal['id'])
        .update({'prenotazioni': prenotazioni});

    setState(() {
      meal['prenotazioni'] = prenotazioni;
    });
  }

  void _confirmDelete(BuildContext context, String mealId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Conferma eliminazione"),
          content: const Text("Sei sicuro?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () {
                _deleteMeal(mealId);
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text("Elimina"),
            ),
          ],
        );
      },
    );
  }

  void _deleteMeal(String mealId) async {
    try {
      await FirebaseFirestore.instance.collection('pasti').doc(mealId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pasto eliminato')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore nell\'eliminazione del pasto')),
      );
    }
  }

  final List<String> tiberClubClassOptions = [
    '4° elem',
    '5° elem',
    '1° media',
    '2° media',
    '3° media',
    "1° liceo",
    "2° liceo",
    "3° liceo",
    "4° liceo",
    "5° liceo",
  ];
  final List<String> deltaClubClassOptions = [
    "1° liceo",
    "2° liceo",
    "3° liceo",
    "4° liceo",
    "5° liceo",
  ];
  List<String> classList = [];
  String selectedClubClass = "";

  Widget buildDropdownClasse(
      String label, List<String> options, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MultiSelectDialogField(
          title: const Text('Seleziona le classi'),
          selectedColor: Theme.of(context).primaryColor,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          items: options
              .map((option) => MultiSelectItem<String>(option, option))
              .toList(),
          buttonText: const Text('Classe'),
          confirmText: const Text('Ok'),
          cancelText: const Text('Annulla'),
          initialValue: classList,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Inserire almeno una classe';
            }
            return null;
          },
          onConfirm: (value) {
            setState(() {
              classList = value;
            });
          },
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchMeals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Errore nel caricamento',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Expanded(
                    child: Center(
                      child: Text(
                        'Non ci sono pranzi in programma',
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                } else {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final meal = snapshot.data![index];
                        return Container(
                          padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom:
                                  BorderSide(color: Colors.grey, width: 1.5),
                            ),
                            color: Colors.white,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      leading:
                                          const Icon(Icons.fastfood, size: 40),
                                      title: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${meal['status'][0].toUpperCase()}${meal['status'].substring(1)}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: meal['status'] == 'chiuso'
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                          ),
                                          AutoSizeText(
                                            '${meal['giorno'][0]}${meal['giorno'][1]}${meal['giorno'][2]} ${meal['data'].split(' ')[0]}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 25,
                                            ),
                                            maxLines: 1,
                                            minFontSize: 18,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '${meal['orario']}',
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (meal['status'] == 'aperto' && widget.role != 'Genitore')
                                        IconButton(
                                          onPressed: () =>
                                              _toggleReservation(meal),
                                          icon: Icon(
                                            meal['prenotazioni']
                                                    .contains(widget.name)
                                                ? Icons.check_circle
                                                : Icons.check_circle_outline,
                                            color: meal['prenotazioni']
                                                    .contains(widget.name)
                                                ? Colors.green
                                                : Colors.black,
                                            size: 30,
                                          ),
                                        ),
                                      if (widget.isAdmin &&
                                          meal['status'] == 'aperto')
                                        IconButton(
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection('pasti')
                                                .doc(meal['id'])
                                                .update({
                                              'status': 'chiuso',
                                              'modificato': true
                                            });
                                            meal['status'] = 'chiuso';
                                            meal['modificato'] = true;
                                            setState(() {});
                                          },
                                          icon:
                                              const Icon(Icons.close, size: 30),
                                        ),
                                      if (widget.isAdmin &&
                                          meal['status'] == 'chiuso')
                                        IconButton(
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection('pasti')
                                                .doc(meal['id'])
                                                .update({
                                              'status': 'aperto',
                                              'modificato': true
                                            });
                                            meal['status'] = 'aperto';
                                            meal['modificato'] = true;
                                            setState(() {});
                                          },
                                          icon: const Icon(Icons.open_in_new,
                                              size: 30),
                                        ),
                                      if (widget.isAdmin)
                                        IconButton(
                                          onPressed: () {
                                            _confirmDelete(context, meal['id']);
                                          },
                                          icon: const Icon(Icons.delete_outline,
                                              size: 30),
                                        ),
                                    ],
                                  )
                                ],
                              ),
                              ListTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Classi:',
                                      style: TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    AutoSizeText(
                                      '${meal['classi'].join(', ')}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                      ),
                                      maxLines: 2,
                                      minFontSize: 18,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (meal.containsKey('prenotazioni'))
                                Column(
                                  children: [
                                    const SizedBox(height: 5),
                                    widget.role!='Genitore'?
                                    ExpansionTile(
                                      title: Text(
                                          'Prenotazioni (${_getAllPresenti(meal).length})',
                                          style: const TextStyle(fontSize: 20)),
                                      children: _getAllPresenti(meal).isNotEmpty
                                          ? _getAllPresenti(meal)
                                              .map<Widget>((name) => ListTile(
                                                      title: Text(
                                                    name,
                                                    style: const TextStyle(
                                                        fontSize: 18),
                                                  )))
                                              .toList()
                                          : [
                                              const ListTile(
                                                  title: Text(
                                                      'Nessuna prenotazione'))
                                            ],
                                      shape: const RoundedRectangleBorder(
                                        side: BorderSide.none,
                                      ),
                                    ) 
                                    : Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(18, 5, 0, 0),
                                          child: AutoSizeText(
                                            'Prenotazioni (${_getAllPresenti(meal).length})',
                                            style: const TextStyle(fontSize: 20),
                                            maxLines: 1,
                                            minFontSize: 15,
                                            overflow: TextOverflow.ellipsis
                                          ),
                                        )
                                      )
                                  ],
                                ),
                              // Amici widget
                              if (meal['status'] == 'aperto' && widget.role != 'Genitore')
                                _buildAmiciContainer(meal),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: _showAddMealDialog,
              shape: const CircleBorder(),
              backgroundColor: Colors.white,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }
}
