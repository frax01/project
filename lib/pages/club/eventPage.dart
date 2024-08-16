import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'addEditProgram.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';

class EventPage extends StatefulWidget {
  const EventPage({
    super.key,
    required this.club,
    required this.documentId,
    required this.isAdmin,
    required this.name,
    required this.focusedDay,
  });

  final String club;
  final String documentId;
  final bool isAdmin;
  final String name;
  final DateTime focusedDay;

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  Map<String, dynamic> _event = {};

  Future<void> _loadEvent() async {
    var doc = await FirebaseFirestore.instance
        .collection('calendario')
        .doc(widget.documentId)
        .get();
    _event = {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    if (!_event.containsKey('file')) {
      _event['file'] = [];
    }
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
          content: const Text('Sei sicuro di voler eliminare questo evento?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                final FirebaseFirestore firestore = FirebaseFirestore.instance;
                await firestore.collection('calendario').doc(id).delete();
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
                                  backgroundColor: isLink ? Theme
                                      .of(context)
                                      .primaryColor : Colors.white,
                                  foregroundColor: isLink
                                      ? Colors.white
                                      : Colors.black,
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
                                  backgroundColor: isFile ? Theme
                                      .of(context)
                                      .primaryColor : Colors.white,
                                  foregroundColor: isFile
                                      ? Colors.white
                                      : Colors.black,
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
                                        textStyle: const TextStyle(
                                            fontSize: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              10),
                                        ),
                                        elevation: 5,
                                      ),
                                      onPressed: () async {
                                        FilePickerResult? result = await FilePicker
                                            .platform.pickFiles();
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
                                        style: TextStyle(color: Theme
                                            .of(context)
                                            .primaryColor),
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
                    validation(
                        title,
                        _programNameController,
                        isLink,
                        _linkController,
                        isFile,
                        file
                    );
                    setState(() {});
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
    if (file.path == null) {
      print("Percorso del file non disponibile");
      return null;
    }

    try {
      final bytes = File(file.path!).readAsBytesSync();
      final storageRef = FirebaseStorage.instance.ref().child(
          'uploads/${file.name}');
      final uploadTask = storageRef.putData(bytes);
      final snapshot = await uploadTask.whenComplete(() {});

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Errore durante il caricamento del file: $e");
      return null;
    }
  }

  void validation(String title,
      TextEditingController _programNameController,
      bool isLink,
      TextEditingController _linkController,
      bool isFile,
      PlatformFile? file,) async {
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
            .collection('calendario')
            .doc(widget.documentId)
            .update({
          'file': FieldValue.arrayUnion([dataToSave])
        });
        Navigator.of(context).pop();
        setState(() {});
      }
    }
  }

  Widget buildFileLinkButton(Map<String, dynamic> fileData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
      child: fileData['link'] != null && fileData['link'].isNotEmpty
          ? TextButton(
        onPressed: () => _openFileOrLink(fileData['link']),
        style: TextButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: const BorderSide(color: Colors.black),
          overlayColor: Colors.grey[500],
        ),
        child: Row(
          children: [
            const Icon(Icons.link, color: Colors.black),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileData['title'],
                style: const TextStyle(fontSize: 16.0, color: Colors.black),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              highlightColor: Colors.grey[300],
              onPressed: () => _showDeleteConfirmationDialog(fileData),
            ),
          ],
        ),
      ) : fileData['path'] != null && fileData['path'].isNotEmpty ? TextButton(
        onPressed: () => _openFileOrLink(fileData['path']),
        style: TextButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: const BorderSide(color: Colors.black),
          overlayColor: Colors.grey[500],
        ),
        child: Row(
          children: [
            const Icon(Icons.file_copy, color: Colors.black),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileData['title'],
                style: const TextStyle(fontSize: 16.0, color: Colors.black),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              highlightColor: Colors.grey[300],
              onPressed: () => _showDeleteConfirmationDialog(fileData),
            ),
          ],
        ),
      ) : Container(),
    );
  }

  Future<void> _openFileOrLink(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link non valido'),
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> fileData) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma'),
          content: const Text('Sei sicuro di voler eliminare il file/link?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                _deleteFileOrLink(fileData);
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
  }

  void _deleteFileOrLink(Map<String, dynamic> fileData) async {
    await FirebaseFirestore.instance
        .collection('calendario')
        .doc(widget.documentId)
        .update({
      'file': FieldValue.arrayRemove([fileData])
    });

    if (fileData['path'] != null && fileData['path'].isNotEmpty) {
      try {
        final storageRef = FirebaseStorage.instance.refFromURL(
            fileData['path']);
        await storageRef.delete();
      } catch (e) {
        print("Errore durante l'eliminazione del file da Firebase Storage: $e");
      }
    }
  }

  String _formatTimestampToDate(dynamic timestamp) {
    if (timestamp == null) {
      return 'Data non disponibile';
    }
    try {
      int seconds;
      if (timestamp is Timestamp) {
        seconds = timestamp.seconds;
      } else {
        seconds = int.parse(timestamp.toString());
      }
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return 'Data non valida';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evento'),
        actions: [
          IconButton(
            onPressed: () {
              if(_event['fine']!='') {
                Share.share(
                    '${_event['titolo']}\n\n'
                        '${_event['data']}\n\n'
                        'Dalle ${_event['inizio']} alle ${_event['fine']}\n\n'
                        '${_event['description']}\n');
              } else {
                if(_event['inizio']!='') {
                  Share.share(
                      '${_event['titolo']}\n\n'
                          '${_event['data']}\n\n'
                          'Dalle ${_event['inizio']}\n\n'
                          '${_event['description']}\n');
                } else {
                  Share.share(
                      '${_event['titolo']}\n\n'
                          '${_event['data']}\n\n'
                          '${_event['description']}\n');
                }
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
                        club: widget.club,
                        selectedOption: 'evento',
                        document: _event,
                        refreshProgram: refreshProgram,
                        name: widget.name,
                        focusedDay: widget.focusedDay,
                      )));
                },
              ),
              PopupMenuItem(
                  child: const Text('Elimina'),
                  onTap: () {
                    _showDeleteDialog(context, _event['id']);
                  }),
            ];
          })
              : const SizedBox.shrink(),
        ],
      ),
      body: AdaptiveLayout(
        smallLayout: FutureBuilder(
          future: _loadEvent(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                    'Errore nel caricamento dell\'evento: ${snapshot.error}'),
              );
            } else {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          _event['titolo'],
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event, size: 35,),
                                const SizedBox(width: 10),
                                Text(
                                  _formatTimestampToDate(_event['data']),
                                  style: const TextStyle(
                                    fontSize: 24,
                                  ),
                                ),
                              ]
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 35),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AutoSizeText(
                                    _event['fine'].isNotEmpty
                                        ? 'Dalle ${_event['inizio']} alle ${_event['fine']}'
                                        : _event['inizio'].isNotEmpty
                                        ? 'Dalle ${_event['inizio']}'
                                        : 'Orario non specificato',
                                    style: const TextStyle(fontSize: 24.0),
                                    maxLines: 4,
                                    minFontSize: 15,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Descrizione:',
                                  style: const TextStyle(fontSize: 17, color: Colors.grey),
                                ),
                                Text(
                                  _event['descrizione']?.isNotEmpty
                                      ? _event['descrizione']!
                                      : 'Non ci sono informazioni per questo evento',
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20.0),
                            if (_event.containsKey('file'))
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var fileData in _event['file'])
                                    buildFileLinkButton(fileData),
                                ],
                              ),
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
                              child: const Icon(
                                  Icons.upload, color: Colors.black),
                            ) : const SizedBox.shrink(),
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
