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
  });

  final String club;
  final String documentId;
  final String selectedOption;
  final bool isAdmin;
  final Function? refreshList;
  final String name;
  final String role;

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  Map<String, dynamic> _data = {};
  Map<String, dynamic> _weather = {};
  Map<String, dynamic> _event = {};

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

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    //return PopScope(
    //canPop: false,
    //child: 
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
                            role: widget.role)));
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
                      Stack(
                        clipBehavior: Clip.none,
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
                          if (_data.containsKey('prenotazioni') &&
                              _data.containsKey('assenze'))
                            SizedBox(
                              height: 175,
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 10,
                                    right: 80,
                                    child: InkWell(
                                      onTap: _toggleReservation,
                                      borderRadius: BorderRadius.circular(50),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 2,
                                              blurRadius: 7,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _data['prenotazioni']
                                                  .contains(widget.name)
                                              ? Icons.check
                                              : Icons.check_outlined,
                                          color: _data['prenotazioni']
                                                  .contains(widget.name)
                                              ? Colors.green
                                              : Colors.black,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: InkWell(
                                      onTap: _toggleAbsence,
                                      borderRadius: BorderRadius.circular(50),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 2,
                                              blurRadius: 7,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _data['assenze'].contains(widget.name)
                                              ? Icons.close
                                              : Icons.close_outlined,
                                          color: _data['assenze']
                                                  .contains(widget.name)
                                              ? Colors.red
                                              : Colors.black,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Positioned(
                            bottom: -25,
                            left: 15,
                            right: 15,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width - 30,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: Center(
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
                                        padding: const EdgeInsets.fromLTRB(
                                            10, 5, 10, 5),
                                        child: AutoSizeText(
                                          _data['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 30,
                                          ),
                                          maxFontSize: 30,
                                          minFontSize: 20,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),
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
                                      Expanded(
                                          child: Column(
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
                                          ])),
                                      const SizedBox(width: 10),
                                      weatherTile(_weather),
                                    ],
                                  ),
                                )),
                            _data['description'] != ''
                                ? Column(children: [
                                    const SizedBox(height: 20.0),
                                    Card(
                                      surfaceTintColor: Colors.white,
                                      elevation: 5,
                                      margin: const EdgeInsets.all(0),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              style:
                                                  const TextStyle(fontSize: 17),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ])
                                : Container(),
                            if (_data.containsKey('prenotazioni') &&
                                widget.role != 'Genitore')
                              Column(
                                children: [
                                  const SizedBox(height: 20.0),
                                  ExpansionTile(
                                    title: Text(
                                        'Prenotati (${_data['prenotazioni'].length})'),
                                    leading:
                                        const Icon(Icons.check_circle_outline),
                                    children: _data['prenotazioni'].isNotEmpty
                                        ? _data['prenotazioni']
                                            .map<Widget>((name) => ListTile(
                                                  title: Text(name),
                                                ))
                                            .toList()
                                        : [
                                            const ListTile(
                                              title:
                                                  Text('Nessuna prenotazione'),
                                            ),
                                          ],
                                  ),
                                  const SizedBox(height: 15.0),
                                  ExpansionTile(
                                    title: Text(
                                        'Assenti (${_data['assenze'].length})'),
                                    leading:
                                        const Icon(Icons.check_circle_outline),
                                    children: _data['assenze'].isNotEmpty
                                        ? _data['assenze']
                                            .map<Widget>((name) => ListTile(
                                                  title: Text(name),
                                                ))
                                            .toList()
                                        : [
                                            const ListTile(
                                              title: Text('Nessuna assenza'),
                                            ),
                                          ],
                                  ),
                                ],
                              ),
                            if (_data.containsKey('prenotazioni') &&
                                widget.role == 'Genitore')
                              Column(
                                children: [
                                  const SizedBox(height: 20.0),
                                  Text(
                                      'Prenotazioni (${_data['prenotazioni'].length})',
                                      style: const TextStyle(fontSize: 20)),
                                ],
                              ),
                            if (_data.containsKey('file'))
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20.0),
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
                                ])
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
