import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Lunch extends StatefulWidget {
  const Lunch({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  _LunchState createState() => _LunchState();
}

class _LunchState extends State<Lunch> {
  // Future che recupera i pasti da Firebase
  Future<List<Map<String, dynamic>>> _fetchMeals() async {
    try {
      // Recupera i pasti da Firebase
      final querySnapshot = await FirebaseFirestore.instance.collection('pasti').get();

      if (querySnapshot.docs.isEmpty) {
        return []; // Nessun pasto presente
      } else {
        return querySnapshot.docs
            .map((doc) => {
                  'data': doc['data'],
                  'orario': doc['orario'],
                })
            .toList();
      }
    } catch (e) {
      // Gestione dell'errore, ad esempio se la collezione non esiste
      return []; // Restituisci una lista vuota in caso di errore
    }
  }

  Future<void> _showAddMealDialog() async {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      // Controller per gestire la visualizzazione del testo
      final dateController = TextEditingController();
      final timeController = TextEditingController();

      return AlertDialog(
        title: const Text('Aggiungi un nuovo pasto'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Selezione data
              TextFormField(
                decoration: const InputDecoration(labelText: 'Data'),
                readOnly: true,
                controller: dateController,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(), // Solo date future o odierne
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                      dateController.text = DateFormat('dd MMM yyyy', 'it_IT').format(selectedDate!).toUpperCase();
                    });
                  }
                },
                validator: (value) {
                  if (selectedDate == null) {
                    return 'Seleziona una data';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Selezione orario
              TextFormField(
                decoration: const InputDecoration(labelText: 'Orario'),
                readOnly: true,
                controller: timeController,
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
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
                // Salva il pasto nel database
                await FirebaseFirestore.instance.collection('pasti').add({
                  'data': DateFormat('dd MMM yyyy', 'it_IT').format(selectedDate!).toUpperCase(),
                  'orario': selectedTime!.format(context),
                });
                Navigator.of(context).pop();
                setState(() {}); // Forza il rebuild per ricaricare i pasti
              }
            },
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Usare FutureBuilder per gestire i pasti
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchMeals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  ); // Mostra un indicatore di caricamento
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Errore nel caricamento dei dati',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ); // Gestisce eventuali errori
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
                  ); // Mostra il messaggio se non ci sono pasti
                } else {
                  // Se ci sono pasti, mostrarli
                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final meal = snapshot.data![index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.white,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        meal['data'].split(' ')[0], // Giorno
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        meal['data'].split(' ')[1], // Mese
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        meal['data'].split(' ')[2], // Anno
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        meal['orario'], // Orario
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
