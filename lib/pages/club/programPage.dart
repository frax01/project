import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/functions/generalFunctions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../functions/weatherFunctions.dart';
import 'addEditProgram.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class ProgramPage extends StatefulWidget {
  const ProgramPage({
    super.key,
    required this.documentId,
    required this.selectedOption,
    required this.isAdmin,
    required this.name,
    this.refreshList,
  });

  final String documentId;
  final String selectedOption;
  final bool isAdmin;
  final Function? refreshList;
  final String name;

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  Map<String, dynamic> _data = {};
  Map<String, dynamic> _weather = {};

  Future<void> _loadData() async {
    var doc = await FirebaseFirestore.instance
        .collection('club_${widget.selectedOption}')
        .doc(widget.documentId)
        .get();
    _data = {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    print("doc: ${_data['file']}");
    _weather = await fetchWeatherData(
        _data['startDate'], _data['endDate'], _data['lat'], _data['lon']);
  }

  refreshProgram() {
    setState(() {});
  }

  Future<void> _showDeleteDialog(BuildContext context, String id) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Elimina'),
          content: const Text('Sei sicuro di voler eliminare questo programma?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  deleteDocument('club_${_data["selectedOption"]}', id);
                });
                widget.refreshList!();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
  }

  Widget weatherTile(Map weather) {
    if ((weather["check"] == "true" || weather["check"]) &&
        weather["image"] != "") {
      return Row(
        children: [
          Image.network(weather["image"], width: 50, height: 50),
          const SizedBox(width: 10),
          Column(
            children: [
              Text('${weather["t_max"]}ºC',
                  style: const TextStyle(color: Colors.red)),
              Text('${weather["t_min"]}ºC',
                  style: const TextStyle(color: Colors.blue)),
            ],
          ),
        ],
      );
    } else if ((weather["check"] == "true" || weather["check"])) {
      return Row(
        children: [
          Column(
            children: [
              Text('${weather["t_max"]}ºC',
                  style: const TextStyle(color: Colors.red)),
              Text('${weather["t_min"]}ºC',
                  style: const TextStyle(color: Colors.blue)),
            ],
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  //final _titleKey = GlobalKey<FormState>();
  //final _linkKey = GlobalKey<FormState>();
  //final _fileKey = GlobalKey<FormState>();
  final _formKey = GlobalKey<FormState>();

  Future<void> _showAddLinkFileDialog(BuildContext context) {
    String title = '';
    String placeHolder = 'Seleziona File';
    PlatformFile? file;
    bool isLink = false;
    bool isFile = false;
    final TextEditingController _programNameController = TextEditingController();
    final TextEditingController _linkController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Center(
                child: Text('Aggiungi un link o un file'),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _programNameController,
                            decoration: const InputDecoration(
                              labelText: 'Titolo',
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Inserisci il titolo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isLink ? Theme.of(context).primaryColor : Colors.white,
                                  foregroundColor: isLink ? Colors.white : Colors.black,
                                  textStyle: const TextStyle(fontSize: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 5,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isLink = !isLink;
                                    if (isLink) {
                                      isFile = false;
                                    }
                                  });
                                },
                                child: const Text('Link'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFile ? Theme.of(context).primaryColor : Colors.white,
                                  foregroundColor: isFile ? Colors.white : Colors.black,
                                  textStyle: const TextStyle(fontSize: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 5,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isFile = !isFile;
                                    if (isFile) {
                                      isLink = false;
                                    }
                                  });
                                },
                                child: const Text('File'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          if (isLink)
                            TextFormField(
                              controller: _linkController,
                              decoration: const InputDecoration(
                                labelText: 'Link',
                              ),
                              validator: (String? value) {
                                if (value!.isEmpty) {
                                  return 'Inserisci il link al file';
                                }
                                return null;
                              },
                            ),
                          if (isFile)
                            FormField<PlatformFile>(
                              validator: (value) {
                                if (file == null) {
                                  return 'Seleziona un file';
                                }
                                return null;
                              },
                              builder: (formFieldState) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        textStyle: const TextStyle(fontSize: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 5,
                                      ),
                                      onPressed: () async {
                                        FilePickerResult? result = await FilePicker.platform.pickFiles();
                                        if (result != null) {
                                          setState(() {
                                            file = result.files.first;
                                            placeHolder = file!.name;
                                          });
                                          formFieldState.didChange(file);
                                        }
                                      },
                                      child: Text(
                                        placeHolder,
                                        style: const TextStyle(fontSize: 16.0),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (formFieldState.hasError)
                                      Text(
                                        formFieldState.errorText!,
                                        style: TextStyle(color: Theme.of(context).primaryColor),
                                      ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Annulla'),
                ),
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      title = _programNameController.text;
                      if (title.isNotEmpty &&
                          (isLink && _linkController.text.isNotEmpty ||
                              isFile && file != null)) {
                        final dataToSave = {
                          'title': title,
                          'link': isLink ? _linkController.text : '',
                          'path': isFile ? await _uploadFileToFirebase(file!) : null,
                        };

                        await FirebaseFirestore.instance
                            .collection('club_${widget.selectedOption}')
                            .doc(widget.documentId)
                            .update({
                          'file': FieldValue.arrayUnion([dataToSave])
                        });
                        setState(() {});
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _uploadFileToFirebase(PlatformFile file) async {
    print("-1");
    if (file.path == null) {
      print("Percorso del file non disponibile");
      return null;
    }
    print("1");

    try {
      // Leggi i byte del file dal percorso
      final bytes = File(file.path!).readAsBytesSync();

      // Carica i byte del file su Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('uploads/${file.name}');
      final uploadTask = storageRef.putData(bytes);
      final snapshot = await uploadTask.whenComplete(() {});

      print("url: ${snapshot.ref.getDownloadURL()}");

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Errore durante il caricamento del file: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.selectedOption == 'weekend'
            ? const Text('Sabato')
            : widget.selectedOption == 'trip'
                ? const Text('Viaggio')
                : const Text('Extra'),
        actions: [
          IconButton(
            onPressed: () {
              if(widget.selectedOption=='trip') {
                Share.share(
                    '${_data['title']}\n\n'
                    '${_data['address']}\n\n'
                    'Dal ${_data['startDate']} al ${_data['endDate']}\n\n'
                    '${_data['description']}\n');
              } else {
                Share.share(
                    '${_data['title']}\n\n'
                    '${_data['address']}\n\n'
                    '${_data['startDate']}\n\n'
                    '${_data['description']}\n');
              }
            },
            icon: const Icon(
              Icons.share,
            ),
          ),
          widget.isAdmin
              ? PopupMenuButton(itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      child: const Text('Modifica'),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => AddEditProgram(
                                  selectedOption: _data['selectedOption'],
                                  document: _data,
                                  refreshList: widget.refreshList,
                                  refreshProgram: refreshProgram,
                                  name: widget.name,
                                )));
                      },
                    ),
                    PopupMenuItem(
                        child: const Text('Elimina'),
                        onTap: () {
                          _showDeleteDialog(context, _data['id']);
                        }),
                  ];
                })
              : const SizedBox.shrink(),
        ],
      ),
      body: AdaptiveLayout(
        smallLayout: FutureBuilder(
          future: _loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 5,
                            child: SizedBox(
                              height: 175,
                              width: double.infinity,
                              child: Image.network(
                                _data['imagePath'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                              bottom: -25,
                              left: 15,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 7,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 5, 10, 5),
                                  child: Text(
                                    _data['title'],
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ),
                      const SizedBox(height: 30.0),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                      children: List<Widget>.generate(
                                          _data['selectedClass'].length,
                                          (index) {
                                    String classValue = _data['selectedClass']
                                            [index]
                                        .toString();
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 1,
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 5),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(classValue),
                                      ),
                                    );
                                  })),
                                )),
                                const SizedBox(width: 15),
                                Chip(
                                  label: Text(
                                    _data['endDate'].isNotEmpty
                                        ? '${convertDateFormat(_data['startDate'])} ~ ${convertDateFormat(_data['endDate'])}'
                                        : convertDateFormat(_data['startDate']),
                                  ),
                                  labelStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20.0),
                            Card(
                                surfaceTintColor: Colors.white,
                                elevation: 5,
                                margin: const EdgeInsets.all(0),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Dove',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            Text(
                                              _data['address'],
                                              style:
                                                  const TextStyle(fontSize: 15),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ]),
                                      weatherTile(_weather),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 20.0),
                            Card(
                              surfaceTintColor: Colors.white,
                              elevation: 5,
                              margin: const EdgeInsets.all(0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Descrizione',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      _data['description'],
                                      style: const TextStyle(fontSize: 17),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            //_data["file"].forEach((value) {
                            //  if(_data["file"]["link"]!='') {
                            //    TextButton(
                            //      onPressed: () {
                            //        launchUrl(Uri.parse(_data["file"]["path"]));
                            //      },
                            //      child: Row(
                            //        children: [
                            //          const Icon(Icons.link, color: Colors.black),
                            //          const SizedBox(width: 10,),
                            //          Text(_data["file"]["title"],
                            //            style: const TextStyle(fontSize: 16.0),
                            //            maxLines: 1,
                            //            overflow: TextOverflow.ellipsis,),
                            //        ]
                            //      )
                            //    );
                            //  }
                            //}),
                            const SizedBox(height: 20.0),
                            widget.isAdmin
                                ? TextButton(
                              onPressed: () {
                                _showAddLinkFileDialog(context);
                              },
                              style: TextButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                side: const BorderSide(color: Colors.black),
                                overlayColor: Colors.grey[500],
                              ),
                              child: const Icon(Icons.upload, color: Colors.black),
                            ) : const SizedBox.shrink(),
                            const SizedBox(height: 20.0),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Creato da ',
                                    style: TextStyle(fontSize: 17),
                                  ),
                                  Text(
                                    _data['creator'],
                                    style: const TextStyle(fontSize: 17),
                                  ),
                                ]
                              )
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}