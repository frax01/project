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
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgramPage extends StatefulWidget {
  const ProgramPage({
    super.key,
    required this.club,
    required this.documentId,
    required this.selectedOption,
    required this.isAdmin,
    required this.name,
    required this.role,
    this.refreshList,
    required this.classes,
  });

  final String club;
  final String documentId;
  final String selectedOption;
  final bool isAdmin;
  final Function? refreshList;
  final String name;
  final String role;
  final List classes;

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  Map<String, dynamic> _data = {};
  Map<String, dynamic> _weather = {};
  Map<String, dynamic> _event = {};
  String newRole = '';

  Future<void> _loadData() async {
    var doc = await FirebaseFirestore.instance
        .collection('club_${widget.selectedOption}')
        .doc(widget.documentId)
        .get();
    _data = {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    _weather = await fetchWeatherData(
        _data['startDate'], _data['endDate'], _data['lat'], _data['lon']);
    if (!_data.containsKey('file')) {
      _data['file'] = [];
    }

    if (widget.role == '') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String email = prefs.getString('email') ?? '';
      var docUser = await FirebaseFirestore.instance
          .collection('user')
          .where('email', isEqualTo: email)
          .get();
      var userDoc = docUser.docs.isNotEmpty ? docUser.docs.first : null;
      if (userDoc != null) {
        newRole = userDoc.data()['role'];
      } else {
        print("Nessun utente trovato con l'email: $email");
      }
    }
  }

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

  Future<void> _showDeleteDialog(
      BuildContext context, String id, String image) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Elimina'),
          content:
              const Text('Sei sicuro di voler eliminare questo programma?'),
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
                  deleteDocument('club_${_data["selectedOption"]}', id, image);
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
          Image.network(weather["image"], width: 55, height: 55),
          const SizedBox(width: 10),
          Column(
            children: [
              Text('${weather["t_max"]}ºC',
                  style: const TextStyle(color: Colors.red, fontSize: 17)),
              Text('${weather["t_min"]}ºC',
                  style: const TextStyle(color: Colors.blue, fontSize: 17)),
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
                  style: const TextStyle(color: Colors.red, fontSize: 17)),
              Text('${weather["t_min"]}ºC',
                  style: const TextStyle(color: Colors.blue, fontSize: 17)),
            ],
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  final _formKey = GlobalKey<FormState>();

  Future<void> _showAddLinkFileDialog(BuildContext context) {
    String title = '';
    String placeHolder = 'Seleziona File';
    PlatformFile? file;
    bool isLink = false;
    bool isFile = false;
    final TextEditingController _programNameController =
        TextEditingController();
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
                                  backgroundColor: isLink
                                      ? Theme.of(context).primaryColor
                                      : Colors.white,
                                  foregroundColor:
                                      isLink ? Colors.white : Colors.black,
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
                                  backgroundColor: isFile
                                      ? Theme.of(context).primaryColor
                                      : Colors.white,
                                  foregroundColor:
                                      isFile ? Colors.white : Colors.black,
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
                                        textStyle:
                                            const TextStyle(fontSize: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        elevation: 5,
                                      ),
                                      onPressed: () async {
                                        FilePickerResult? result =
                                            await FilePicker.platform
                                                .pickFiles();
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
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor),
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
                    await validation(title, _programNameController, isLink,
                        _linkController, isFile, file);
                    Navigator.of(context).pop();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Percorso del file non disponibile'),
        ),
      );
      return null;
    }

    try {
      final bytes = File(file.path!).readAsBytesSync();
      final storageRef =
          FirebaseStorage.instance.ref().child('uploads/${file.name}');
      final uploadTask = storageRef.putData(bytes);
      final snapshot = await uploadTask.whenComplete(() {});

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante il caricamento del file'),
        ),
      );
      return null;
    }
  }

  Future<void> validation(
    String title,
    TextEditingController _programNameController,
    bool isLink,
    TextEditingController _linkController,
    bool isFile,
    PlatformFile? file,
  ) async {
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
                //overlayColor: Colors.grey[500],
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.black),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fileData['title'],
                      style:
                          const TextStyle(fontSize: 16.0, color: Colors.black),
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
            )
          : fileData['path'] != null && fileData['path'].isNotEmpty
              ? TextButton(
                  onPressed: () => _openFileOrLink(fileData['path']),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Colors.black),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.file_copy, color: Colors.black),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileData['title'],
                          style: const TextStyle(
                              fontSize: 16.0, color: Colors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.black),
                        highlightColor: Colors.grey[300],
                        onPressed: () =>
                            _showDeleteConfirmationDialog(fileData),
                      ),
                    ],
                  ),
                )
              : Container(),
    );
  }

  Future<void> _openFileOrLink(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }

    try {
      await FlutterWebBrowser.openWebPage(url: url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore nell\'aperatura del link')),
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
        .collection('club_${widget.selectedOption}')
        .doc(widget.documentId)
        .update({
      'file': FieldValue.arrayRemove([fileData])
    });

    if (fileData['path'] != null && fileData['path'].isNotEmpty) {
      try {
        final storageRef =
            FirebaseStorage.instance.refFromURL(fileData['path']);
        await storageRef.delete();
      } catch (e) {
        print("Errore durante l'eliminazione del file da Firebase Storage: $e");
      }
    }
  }

  Future<void> _toggleReservation() async {
    if (_data.containsKey('prenotazioni')) {
      List<dynamic> prenotazioni = _data['prenotazioni'];
      List<dynamic> assenze = _data['assenze'];
      if (prenotazioni.contains(widget.name)) {
        prenotazioni.remove(widget.name);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Presenza cancellata')));
      } else {
        if (assenze.contains(widget.name)) {
          prenotazioni.add(widget.name);
          assenze.remove(widget.name);
        } else {
          prenotazioni.add(widget.name);
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Presenza confermata')));
      }

      await FirebaseFirestore.instance
          .collection('club_${widget.selectedOption}')
          .doc(widget.documentId)
          .update({'prenotazioni': prenotazioni, 'assenze': assenze});

      setState(() {
        _data['prenotazioni'] = prenotazioni;
        _data['assenze'] = assenze;
      });
    }
  }

  Future<void> _toggleReservationFood() async {
    if (_data.containsKey('prenotazionePranzo')) {
      List<dynamic> prenotazioni = _data['prenotazionePranzo'];
      List<dynamic> assenze = _data['assenzaPranzo'];
      if (prenotazioni.contains(widget.name)) {
        prenotazioni.remove(widget.name);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Presenza cancellata')));
      } else {
        if (assenze.contains(widget.name)) {
          prenotazioni.add(widget.name);
          assenze.remove(widget.name);
        } else {
          prenotazioni.add(widget.name);
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Presenza confermata')));
      }

      await FirebaseFirestore.instance
          .collection('club_${widget.selectedOption}')
          .doc(widget.documentId)
          .update(
              {'prenotazionePranzo': prenotazioni, 'assenzaPranzo': assenze});

      setState(() {
        _data['prenotazionePranzo'] = prenotazioni;
        _data['assenzaPranzo'] = assenze;
      });
    }
  }

  Future<void> _toggleAbsence() async {
    if (_data.containsKey('assenze')) {
      List<dynamic> assenze = _data['assenze'];
      List<dynamic> prenotazioni = _data['prenotazioni'];
      if (assenze.contains(widget.name)) {
        assenze.remove(widget.name);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Assenza cancellata')));
      } else {
        if (prenotazioni.contains(widget.name)) {
          assenze.add(widget.name);
          prenotazioni.remove(widget.name);
        } else {
          assenze.add(widget.name);
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Assenza confermata')));
      }

      await FirebaseFirestore.instance
          .collection('club_${widget.selectedOption}')
          .doc(widget.documentId)
          .update({'prenotazioni': prenotazioni, 'assenze': assenze});

      setState(() {
        _data['prenotazioni'] = prenotazioni;
        _data['assenze'] = assenze;
      });
    }
  }

  Future<void> _toggleAbsenceFood() async {
    if (_data.containsKey('assenzaPranzo')) {
      List<dynamic> assenze = _data['assenzaPranzo'];
      List<dynamic> prenotazioni = _data['prenotazionePranzo'];
      if (assenze.contains(widget.name)) {
        assenze.remove(widget.name);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Assenza cancellata')));
      } else {
        if (prenotazioni.contains(widget.name)) {
          assenze.add(widget.name);
          prenotazioni.remove(widget.name);
        } else {
          assenze.add(widget.name);
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Assenza confermata')));
      }

      await FirebaseFirestore.instance
          .collection('club_${widget.selectedOption}')
          .doc(widget.documentId)
          .update(
              {'prenotazionePranzo': prenotazioni, 'assenzaPranzo': assenze});

      setState(() {
        _data['prenotazionePranzo'] = prenotazioni;
        _data['assenzaPranzo'] = assenze;
      });
    }
  }

  //bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.selectedOption == 'weekend'
            ? const Text('Programma')
            : const Text('Convivenza'),
        actions: [
          IconButton(
            onPressed: () {
              if (widget.selectedOption == 'trip') {
                Share.share('${_data['title']}\n\n'
                    '${_data['address']}\n\n'
                    'Dal ${_data['startDate']} al ${_data['endDate']}\n\n'
                    '${_data['description']}\n');
              } else {
                Share.share('${_data['title']}\n\n'
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
              ? IconButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AddEditProgram(
                              club: widget.club,
                              selectedOption: _data['selectedOption'],
                              document: _data,
                              refreshList: widget.refreshList,
                              refreshProgram: refreshProgram,
                              name: widget.name,
                              role: widget.role,
                              classes: widget.classes,
                            )));
                  },
                  icon: const Icon(
                    Icons.edit,
                  ),
                )
              : const SizedBox.shrink(),
          widget.isAdmin
              ? IconButton(
                  onPressed: () {
                    _showDeleteDialog(context, _data['id'], _data['imagePath']);
                  },
                  icon: const Icon(
                    Icons.delete,
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: AdaptiveLayout(
        smallLayout: FutureBuilder(
          future:
              widget.selectedOption != 'evento' ? _loadData() : _loadEvent(),
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
                      Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 10,
                        child: SizedBox(
                          height: 175,
                          width: double.infinity,
                          child: Image.network(
                            _data['imagePath'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      ListTile(
                        title: AutoSizeText(
                          _data['title'],
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          minFontSize: 18,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: AutoSizeText(
                                _data['selectedClass'].join(', '),
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                                maxLines: 2,
                                minFontSize: 15,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                size: 30,
                              ),
                              title: const Text('Dove',
                                  style: TextStyle(color: Colors.black54)),
                              subtitle: AutoSizeText(
                                _data['address'],
                                style: const TextStyle(fontSize: 20.0),
                                maxLines: 2,
                                minFontSize: 10,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: weatherTile(_weather),
                          ),
                        ],
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.timelapse,
                          size: 30,
                        ),
                        title: const Text('Quando',
                            style: TextStyle(color: Colors.black54)),
                        subtitle: AutoSizeText(
                          _data['endDate'].isNotEmpty
                              ? '${convertDateFormat(_data['startDate'])} - ${convertDateFormat(_data['endDate'])}'
                              : convertDateFormat(_data['startDate']),
                          style: const TextStyle(fontSize: 20.0),
                          maxLines: 2,
                          minFontSize: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _data['description'] != ''
                          ? ListTile(
                              title: const Text('Descrizione',
                                  style: TextStyle(color: Colors.black54)),
                              subtitle: Text(
                                _data['description'],
                                style: const TextStyle(fontSize: 20.0),
                              ),
                            )
                          : Container(),
                      //programma
                      if (_data.containsKey('prenotazioni') &&
                          _data.containsKey('assenze'))
                        ((widget.club == 'Delta Club' &&
                                    (_data['selectedOption'] == 'trip' &&
                                        (widget.role == 'Ragazzo' || newRole == 'Ragazzo') &&
                                        !_data['selectedClass'].any((className) => [
                                              '3° liceo',
                                              '4° liceo',
                                              '5° liceo'
                                            ].contains(className)) &&
                                        _data['selectedClass'].any((className) => [
                                              '1° liceo',
                                              '2° liceo'
                                            ].contains(className)))) ||
                                ((widget.club == 'Delta Club' &&
                                    _data['selectedOption'] == 'weekend' &&
                                    (widget.role == 'Genitore' || newRole == 'Genitore'))))
                            ? Column(
                              children: [
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.center,
                                  child: AutoSizeText(
                                    'Presenti (${_data['prenotazioni'].length})',
                                    style: const TextStyle(
                                        fontSize: 20),
                                    maxLines: 1,
                                    minFontSize: 15,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ))
                              ])
                            : (widget.club == 'Tiber Club' &&
                                    _data['selectedOption'] == 'weekend' &&
                                    (widget.role == 'Genitore' || newRole == 'Genitore') &&
                                    !_data['selectedClass'].any((className) => [
                                          '4° elem',
                                          '5° elem',
                                          '1° media',
                                          '2° media',
                                          '3° media'
                                        ].contains(className)))
                                ? Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.center,
                                      child: AutoSizeText(
                                        'Presenti (${_data['prenotazioni'].length})',
                                        style: const TextStyle(
                                            fontSize: 20),
                                        maxLines: 1,
                                        minFontSize: 15,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ))
                                  ])
                                : Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                                    margin: const EdgeInsets.fromLTRB(0, 20.0, 0, 10.0),
                                    child: Column(
                                      children: [
                                        Column(children: [
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                    child: ListTile(
                                                  leading: const Icon(
                                                      Icons
                                                          .calendar_month_outlined,
                                                      size: 35),
                                                  title: const AutoSizeText(
                                                    "Conferma",
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        color: Colors.black54),
                                                    maxLines: 1,
                                                    minFontSize: 13,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  subtitle: AutoSizeText(
                                                    widget.selectedOption ==
                                                            'weekend'
                                                        ? 'Programma'
                                                        : 'Convivenza',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 25,
                                                    ),
                                                    maxLines: 1,
                                                    minFontSize: 18,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                )),
                                                Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      IconButton(
                                                        onPressed:
                                                            _toggleReservation,
                                                        icon: Icon(
                                                          _data['prenotazioni']
                                                                  .contains(
                                                                      widget
                                                                          .name)
                                                              ? Icons
                                                                  .check_circle
                                                              : Icons
                                                                  .check_circle_outline,
                                                          color: _data[
                                                                      'prenotazioni']
                                                                  .contains(
                                                                      widget
                                                                          .name)
                                                              ? Colors.green
                                                              : Colors.black,
                                                          size: 30,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed:
                                                            _toggleAbsence,
                                                        icon: Icon(
                                                          _data['assenze']
                                                                  .contains(
                                                                      widget
                                                                          .name)
                                                              ? Icons.close
                                                              : Icons
                                                                  .close_outlined,
                                                          color: _data[
                                                                      'assenze']
                                                                  .contains(
                                                                      widget
                                                                          .name)
                                                              ? Colors.red
                                                              : Colors.black,
                                                          size: 30,
                                                        ),
                                                      ),
                                                    ]),
                                              ])
                                        ]),
                                        //prenotazioni programma
                                        if (_data.containsKey('prenotazioni') &&
                                            (widget.role != 'Genitore' || (newRole != '' && newRole != 'Genitore')))
                                          Column(
                                            children: [
                                              ExpansionTile(
                                                title: AutoSizeText(
                                                  'Presenti (${_data['prenotazioni'].length}) - Assenti (${_data['assenze'].length})',
                                                  style: const TextStyle(
                                                      fontSize: 20),
                                                  maxLines: 1,
                                                  minFontSize: 15,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                children: [
                                                  const ListTile(
                                                    title: AutoSizeText(
                                                      'Presenti',
                                                      style: TextStyle(
                                                          fontSize: 23,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      maxLines: 1,
                                                      minFontSize: 15,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (_data['prenotazioni']
                                                      .isNotEmpty)
                                                    ..._data['prenotazioni']
                                                        .map<Widget>((name) =>
                                                            ListTile(
                                                              title: AutoSizeText(
                                                                  name,
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          20),
                                                                  maxLines: 1,
                                                                  minFontSize:
                                                                      15,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis),
                                                            ))
                                                        .toList()
                                                  else
                                                    const ListTile(
                                                      title: AutoSizeText(
                                                          'Nessuna prenotazione',
                                                          style: TextStyle(
                                                              fontSize: 20),
                                                          maxLines: 1,
                                                          minFontSize: 15,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                  const Divider(),
                                                  const ListTile(
                                                    title: AutoSizeText(
                                                      'Assenti',
                                                      style: TextStyle(
                                                          fontSize: 23,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      maxLines: 1,
                                                      minFontSize: 15,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (_data['assenze']
                                                      .isNotEmpty)
                                                    ..._data['assenze']
                                                        .map<Widget>((name) =>
                                                            ListTile(
                                                              title: AutoSizeText(
                                                                  name,
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          20),
                                                                  maxLines: 1,
                                                                  minFontSize:
                                                                      15,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis),
                                                            ))
                                                        .toList()
                                                  else
                                                    const ListTile(
                                                      title: AutoSizeText(
                                                          'Nessuna assenza',
                                                          style: TextStyle(
                                                              fontSize: 20),
                                                          maxLines: 1,
                                                          minFontSize: 15,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        if (_data.containsKey('prenotazioni') &&
                                            (widget.role == 'Genitore' || (newRole != '' && newRole == 'Genitore')))
                                          Column(
                                            children: [
                                              const SizedBox(height: 20.0),
                                              AutoSizeText(
                                                  'Prenotazioni (${_data['prenotazioni'].length})',
                                                  style: const TextStyle(
                                                      fontSize: 20),
                                                  maxLines: 1,
                                                  minFontSize: 15,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                              const SizedBox(height: 20.0),
                                            ],
                                          ),
                                      ],
                                    )),
                      //pranzo
                      if (_data.containsKey('pasto'))
                        Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                            margin: const EdgeInsets.fromLTRB(0, 10.0, 0, 10.0),
                            child: Column(children: [
                              Column(children: [
                                Column(children: [
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                            child: ListTile(
                                          leading: const Icon(Icons.fastfood,
                                              size: 35),
                                          title: const AutoSizeText(
                                            "Pranzo/Cena",
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.black54),
                                            maxLines: 1,
                                            minFontSize: 13,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: AutoSizeText(
                                            _data['pasto'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 25,
                                            ),
                                            maxLines: 1,
                                            minFontSize: 18,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                onPressed:
                                                    _toggleReservationFood,
                                                icon: Icon(
                                                  _data['prenotazionePranzo']
                                                          .contains(widget.name)
                                                      ? Icons.check_circle
                                                      : Icons
                                                          .check_circle_outline,
                                                  color:
                                                      _data['prenotazionePranzo']
                                                              .contains(
                                                                  widget.name)
                                                          ? Colors.green
                                                          : Colors.black,
                                                  size: 30,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: _toggleAbsenceFood,
                                                icon: Icon(
                                                  _data['assenzaPranzo']
                                                          .contains(widget.name)
                                                      ? Icons.close
                                                      : Icons.close_outlined,
                                                  color: _data['assenzaPranzo']
                                                          .contains(widget.name)
                                                      ? Colors.red
                                                      : Colors.black,
                                                  size: 30,
                                                ),
                                              ),
                                            ])
                                      ])
                                ]),
                                //prenotazioni pranzo
                                if (_data.containsKey('prenotazionePranzo') &&
                                    (widget.role != 'Genitore' || newRole != 'Genitore'))
                                  Column(
                                    children: [
                                      ExpansionTile(
                                        title: AutoSizeText(
                                            'Presenti (${_data['prenotazionePranzo'].length}) - Assenti (${_data['assenzaPranzo'].length})',
                                            style:
                                                const TextStyle(fontSize: 20),
                                            maxLines: 1,
                                            minFontSize: 15,
                                            overflow: TextOverflow.ellipsis),
                                        children: [
                                          const ListTile(
                                            title: AutoSizeText('Presenti',
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                maxLines: 1,
                                                minFontSize: 15,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                          if (_data['prenotazionePranzo']
                                              .isNotEmpty)
                                            ..._data['prenotazionePranzo']
                                                .map<Widget>((name) => ListTile(
                                                      title: AutoSizeText(name,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 20),
                                                          maxLines: 1,
                                                          minFontSize: 15,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ))
                                                .toList()
                                          else
                                            const ListTile(
                                              title: AutoSizeText(
                                                  'Nessuna prenotazione',
                                                  style:
                                                      TextStyle(fontSize: 20),
                                                  maxLines: 1,
                                                  minFontSize: 15,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                          const Divider(),
                                          const ListTile(
                                            title: AutoSizeText('Assenti',
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                maxLines: 1,
                                                minFontSize: 15,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                          if (_data['assenzaPranzo'].isNotEmpty)
                                            ..._data['assenzaPranzo']
                                                .map<Widget>((name) => ListTile(
                                                      title: AutoSizeText(name,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 20),
                                                          maxLines: 1,
                                                          minFontSize: 15,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ))
                                                .toList()
                                          else
                                            const ListTile(
                                              title: AutoSizeText(
                                                  'Nessuna assenza',
                                                  style:
                                                      TextStyle(fontSize: 20),
                                                  maxLines: 1,
                                                  minFontSize: 15,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                if (_data.containsKey('prenotazionePranzo') &&
                                    (widget.role == 'Genitore' || newRole == 'Genitore'))
                                  Column(
                                    children: [
                                      const SizedBox(height: 20.0),
                                      AutoSizeText(
                                          'Prenotazioni (${_data['prenotazionePranzo'].length})',
                                          style: const TextStyle(fontSize: 20),
                                          maxLines: 1,
                                          minFontSize: 15,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 20.0),
                                    ],
                                  ),
                              ])
                            ])),
                      if (_data.containsKey('file'))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10.0),
                            for (var fileData in _data['file'])
                              buildFileLinkButton(fileData),
                            const SizedBox(height: 10.0),
                          ],
                        ),
                      Center(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Text(
                              'Creato da ${_data['creator']}',
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.black54),
                            ),
                          ])),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                _showAddLinkFileDialog(context);
              },
              shape: const CircleBorder(),
              backgroundColor: Colors.white,
              child: const Icon(Icons.upload, color: Colors.black),
            )
          : null,
    );
  }
}
