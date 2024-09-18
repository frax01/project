import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';

class Lunch extends StatefulWidget {
  const Lunch({super.key, required this.isAdmin, required this.name});

  final bool isAdmin;
  final String name;

  @override
  _LunchState createState() => _LunchState();
}

class _LunchState extends State<Lunch> {

  Future<List<Map<String, dynamic>>> _fetchMeals() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('pasti').get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      } else {
        List<Map<String, dynamic>> meals = querySnapshot.docs.map((doc) {
          return {
            'data': doc['data'],
            'orario': doc['orario'],
            'giorno': doc['giorno'],
            'prenotazioni': doc['prenotazioni'],
            'appuntamento': doc['appuntamento'],
            'id': doc.id
          };
        }).toList();
  
        meals.sort((a, b) {
          DateTime dateA = DateFormat('dd-MM-yyyy').parse(a['appuntamento']);
          DateTime dateB = DateFormat('dd-MM-yyyy').parse(b['appuntamento']);
          return dateA.compareTo(dateB);
        });
  
        return meals;
      }
    } catch (e) {
      return [];
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

  Future<String?> _selectDate(BuildContext context) async {

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (picked != null && picked != DateTime.now()) {
      _unfocusAll();
      return DateFormat('dd MMM yyyy', 'it_IT').format(picked).toUpperCase();
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

  @override
  void dispose() {
    _dateFocusNode.dispose();
    _timeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _showAddMealDialog() async {
    _unfocusAll();
    final _formKey = GlobalKey<FormState>();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final dateController = TextEditingController();
        final timeController = TextEditingController();

        return AlertDialog(
          title: const Text('Aggiungi un nuovo pasto'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Data'),
                  readOnly: true,
                  controller: dateController,
                  focusNode: _dateFocusNode,
                  onTap: () async {
                    final String? pickedDate = await _selectDate(context);
                    if (pickedDate != null) {
                      setState(() {
                        dateController.text = pickedDate;
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
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Orario'),
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
              ],
            ),
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
                if (_formKey.currentState!.validate()) {
                  await FirebaseFirestore.instance.collection('pasti').add({
                    'data': DateFormat('dd MMM yyyy', 'it_IT')
                        .format(selectedDate!)
                        .toUpperCase(),
                    'giorno': DateFormat('EEEE', 'it_IT')
                        .format(selectedDate!)
                        .toUpperCase(),
                    'orario': selectedTime!.format(context),
                    'prenotazioni': [],
                    'appuntamento':
                        DateFormat('dd-MM-yyyy').format(selectedDate!),
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
    print("name: ${widget.name}");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Non ci sono pranzi in programma',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(16.0),
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
                                  AutoSizeText(
                                    '${meal['giorno']} ${meal['data'].split(' ')[0]} ${meal['data'].split(' ')[1]} - ${meal['orario']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    minFontSize: 20,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  InkWell(
                                    onTap: () => _toggleReservation(meal),
                                    borderRadius: BorderRadius.circular(50),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 2,
                                            blurRadius: 7,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
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
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ExpansionTile(
                                title: const Text('Prenotazioni'),
                                leading: const Icon(Icons.check_circle_outline),
                                children: meal['prenotazioni'].isNotEmpty
                                    ? meal['prenotazioni']
                                        .map<Widget>((name) => ListTile(
                                              title: Text(name),
                                            ))
                                        .toList()
                                    : [
                                        const ListTile(
                                          title: Text('Nessuna prenotazione'),
                                        ),
                                      ],
                                shape: const RoundedRectangleBorder(
                                  side: BorderSide.none,
                                ),
                              ),
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
              child: const Icon(
                Icons.add,
                color: Colors.black,
              ),
            )
          : null,
    );
  }
}
