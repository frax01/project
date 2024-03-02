import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class Box extends StatefulWidget {
  const Box({
    super.key,
    required this.level,
    required this.clubClass,
    required this.section,
  });

  final String level;
  final String clubClass;
  final String section;

  @override
  State<Box> createState() => _BoxState();
}

class _BoxState extends State<Box> {
  List<Map<String, dynamic>> allDocuments = [];
  String? title;
  String? startDate;
  String? imagePath;
  String? description;
  bool imageUploaded = true;

  Future<List<Map<String, dynamic>>> _fetchData() async {
    allDocuments = [];
    List<String> clubCollections = ['club_weekend', 'club_trip', 'club_extra'];

    for (String collectionName in clubCollections) {
      CollectionReference collection =
          FirebaseFirestore.instance.collection(collectionName);

      QuerySnapshot querySnapshot = await collection
          .where('selectedClass', isEqualTo: widget.clubClass)
          .get();

      print("dati da $collectionName: ${querySnapshot.docs}");

      if (querySnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> documents = querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();

        allDocuments.addAll(documents);
      }
    }

    print(allDocuments);

    return allDocuments;
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

  Future<Map> loadBoxData(String id) async {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('${widget.section}_${widget.level}')
        .doc(id)
        .get();

    Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
    Map<String, dynamic> editData = {};
    setState(() {
      editData = {
        'id': documentSnapshot.id,
        'title': data['title'],
        'imagePath': data['imagePath'],
        'selectedLevel': widget.level,
        'selectedClass': data['selectedClass'],
        'description': data['description'],
        'startDate': data['startDate'] ?? '',
        'endDate': data['endDate'] ?? '',
      };
    });
    return editData;
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> deleteDocument(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  Future<String> deleteImage(String imagePath) async {
    final Reference ref = FirebaseStorage.instance.ref().child(
        imagePath); //il problema è che l'immagine che eliminiamo (images/...) non esiste nel firebase, va prima caricata correttamente
    await ref.delete();
    setState(() {
      imageUploaded = false;
      imagePath = '';
    });
    return imagePath;
  }

  Future<void> _showEditDialog(String level, Map<dynamic, dynamic> data) async {
    print(data);
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String newTitle = data['title'];
    String imagePath = data['imagePath'];
    String selectedClass = data['selectedClass'];
    String description = data['description'];
    String startDate = data['startDate'] ?? '';
    String endDate = data['endDate'] ?? '';
    print('1');

    titleController.text = data['title'];
    descriptionController.text = data['description'];
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(level),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: titleController,
                    onChanged: (value) {
                      newTitle = value;
                    },
                    decoration: const InputDecoration(labelText: 'Titolo'),
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    value: data['selectedClass'],
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value!;
                      });
                    },
                    items: ['', '1° media', '2° media', '3° media']
                        .map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    hint: const Text('Seleziona un\'opzione'),
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
                  //  if (imageUploaded) ...[
                  //ElevatedButton(
                  //  onPressed: () async {
                  //    // Mostra un dialogo di conferma prima di eliminare l'immagine
                  //    bool? confirm = await showDialog<bool>(
                  //      context: context,
                  //      builder: (BuildContext context) {
                  //        return AlertDialog(
                  //          title: Text('Conferma'),
                  //          content: Text(
                  //              'Sei sicuro di voler eliminare l\'immagine?'),
                  //          actions: <Widget>[
                  //            TextButton(
                  //              child: Text('Annulla'),
                  //              onPressed: () {
                  //                setState(() {
                  //                  Navigator.of(context).pop(false);
                  //                });
                  //              },
                  //            ),
                  //            TextButton(
                  //              child: Text('Elimina'),
                  //              onPressed: () {
                  //                setState(() {
                  //                  imageUploaded = false;
                  //                });
                  //                Navigator.of(context).pop(true);
                  //              },
                  //            ),
                  //          ],
                  //        );
                  //      },
                  //    );
                  //    if (confirm == true) {
                  //      await deleteImage(imagePath);
                  //      //print(level);
                  //    }
                  //  },
                  //  child: Text('Elimina Immagine'),
                  //),
                  const SizedBox(height: 16.0),
                  ...(level == 'weekend' || level == 'extra')
                      ? [
                          ElevatedButton(
                            onPressed: () async {
                              String newDate = startDate =
                                  await _startDate(context, data['startDate']);
                              setState(() {
                                startDate = newDate;
                              });
                            },
                            child: Text(startDate),
                          ),
                        ]
                      : (level == 'trip' || level == 'tournament')
                          ? [
                              ElevatedButton(
                                onPressed: () async {
                                  String newDate = await _startDate(
                                      context, data['startDate']);
                                  setState(() {
                                    startDate = newDate;
                                  });
                                },
                                child: Text(startDate),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  String newDate = await _endDate(context,
                                      data['startDate'], data['endDate']);
                                  setState(() {
                                    endDate = newDate;
                                  });
                                },
                                child: Text(endDate),
                              ),
                            ]
                          : [],
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: descriptionController,
                    onChanged: (value) {
                      description = value;
                    },
                    decoration: const InputDecoration(labelText: 'Testo'),
                    maxLines: null,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () async {
                      await updateClubDetails(data['id'], newTitle, imagePath,
                          selectedClass, startDate, endDate, description);
                    },
                    child: const Text('Crea'),
                  ),
                ] //]
                    ),
              );
            },
          );
        });
  }

  Future<void> updateClubDetails(
      String id,
      String newTitle,
      String imagePath,
      String selectedClass,
      String startDate,
      String endDate,
      String description) async {
    try {
      if (title == "") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a title')));
        return;
      }
      if (selectedClass == "") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a class')));
        return;
      }

      await FirebaseFirestore.instance
          .collection('${widget.section}_${widget.level}')
          .doc(id)
          .delete();
      await FirebaseFirestore.instance
          .collection('${widget.section}_${widget.level}')
          .add({
        'title': newTitle,
        'imagePath': imagePath,
        'selectedClass': selectedClass,
        'selectedOption': widget.level,
        'description': description,
        'startDate': startDate,
        'endDate': endDate,
      });
      Navigator.pop(context);
    } catch (e) {
      print('Error updating user details: $e');
    }
  }

  Future<String> uploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      throw Exception('No image selected');
    }

    final Reference ref = FirebaseStorage.instance
        .ref()
        .child('users/${DateTime.now().toIso8601String()}');
    //.child('${section}_image/${DateTime.now().toIso8601String()}');

    final UploadTask uploadTask = ref.putData(await image.readAsBytes());

    final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

    final String imageUrl = await snapshot.ref.getDownloadURL();

    print(imageUrl);

    setState(() {
      imageUploaded = true;
    });

    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchData(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if ((snapshot.data as List<Map<String, dynamic>>).isEmpty) {
          return const Center(
              child: Text("Non ci sono programmi",
                  style: TextStyle(fontSize: 18.0)));
        } else {
          allDocuments.sort((a, b) =>
              (a['startDate'] as String).compareTo(b['startDate'] as String));
          return ListView.builder(
            itemCount: allDocuments.length,
            itemBuilder: (context, index) {
              var document = allDocuments[index];
              var id = document['id'];
              var title = document['title'];
              var level = document['selectedOption'];
              var startDate = document['startDate'];
              //var imagePath = document['imagePath'];
              var description = document['description'];
              return Container(
                margin: const EdgeInsets.all(10.0),
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Title: $title',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text('StartDate: $startDate'),
                          Text('Club Class: ${widget.clubClass}'),
                          if (document['endDate'] != '')
                            Text('EndDate: ${document['endDate']}'),
                          Image(
                            image: NetworkImage(
                                'images/$level/default.jpg'), //dovrebbe essere '${document['imagePath']}', ma non carica bene...
                            height: 100,
                            width: 100,
                          ),
                          Text('Description: $description'),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            Map<dynamic, dynamic> data = {};
                            data = await loadBoxData(id);
                            _showEditDialog(widget.level, data);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            bool? shouldDelete = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm'),
                                  content: const Text(
                                      'Are you sure you want to delete this item?'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('Delete'),
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                            if (shouldDelete == true) {
                              setState(() {
                                deleteDocument(
                                    '${widget.section}_${widget.level}', id);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }
}
