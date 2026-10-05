import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/functions/generalFunctions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../functions/bookingFunctions.dart';
import '../../functions/weatherFunctions.dart';
import 'addEditProgram.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:club/functions/linkFunctions.dart';
import 'package:club/functions/storageFunctions.dart';
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
  @override
  void dispose() {
    _amiciProgrammaController.dispose();
    _amiciPranzoController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    var doc = await FirebaseFirestore.instance
        .collection('club_${widget.selectedOption}')
        .doc(widget.documentId)
        .get();
    _data = {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    if (!_data.containsKey('file')) {
      _data['file'] = [];
    }
    try {
      _weather = await fetchWeatherData(
          _data['startDate'], _data['endDate'], _data['lat'], _data['lon']);
    } catch (e) {
      // The weather is optional: a failing forecast API (or bad coordinates)
      // used to make the whole page fail to build.
      _weather = {};
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

  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _startLoading();
  }

  // The future used to be created inside build(), so every setState (each
  // booking tap, each friend added) refetched the document and the weather and
  // flashed a spinner. It is created once and reloaded explicitly.
  Future<void> _startLoading() =>
      widget.selectedOption != 'evento' ? _loadData() : _loadEvent();

  void _reload() {
    setState(() {
      _loadFuture = _startLoading();
    });
  }

  void refreshProgram() => _reload();

  /// Re-reads the booking fields so that changes made by other people
  /// meanwhile show up, without reloading the whole page and the weather.
  Future<void> _refreshBookings() async {
    final doc = await FirebaseFirestore.instance
        .collection('club_${widget.selectedOption}')
        .doc(widget.documentId)
        .get();
    final fresh = doc.data();
    if (fresh == null || !mounted) return;
    setState(() {
      for (final key in const [
        'prenotazioni',
        'assenze',
        'prenotazionePranzo',
        'assenzaPranzo',
        'amici',
        'amiciPranzo',
      ]) {
        if (fresh.containsKey(key)) _data[key] = fresh[key];
      }
    });
  }

  void _showSaveError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore nel salvataggio, riprova')));
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
                final NavigatorState navigator = Navigator.of(context);
                navigator.pop(); // the dialog
                try {
                  // Awaited: the page used to close (and the list to refresh)
                  // before the document was actually deleted, and a failure
                  // was silent.
                  await deleteDocument(
                      'club_${_data["selectedOption"]}', id, image,
                      files: _data['file'] ?? const []);
                } catch (e) {
                  _showSaveError();
                  return;
                }
                // refreshList is null when the page was opened from a
                // notification: it used to throw there and leave the page open.
                widget.refreshList?.call();
                if (mounted) navigator.pop(); // the page
              },
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
  }

  Widget weatherTile(Map weather) {
    final bool check = weather["check"] == true || weather["check"] == "true";
    if (!check) return Container();
    final String image = (weather["image"] ?? '').toString();
    return Row(
      children: [
        if (image.isNotEmpty) ...[
          Image.network(image, width: 55, height: 55),
          const SizedBox(width: 10),
        ],
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
  }

  final _formKey = GlobalKey<FormState>();

  Future<void> _showAddLinkFileDialog(BuildContext context) {
    String title = '';
    String placeHolder = 'Seleziona File';
    PlatformFile? file;
    bool isLink = false;
    bool isFile = false;
    final TextEditingController programNameController =
        TextEditingController();
    final TextEditingController linkController = TextEditingController();

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
                            controller: programNameController,
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
                              controller: linkController,
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
                    await validation(title, programNameController, isLink,
                        linkController, isFile, file);
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
          FirebaseStorage.instance.ref().child(attachmentStoragePath(
              docId: widget.documentId, fileName: file.name));
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
    TextEditingController programNameController,
    bool isLink,
    TextEditingController linkController,
    bool isFile,
    PlatformFile? file,
  ) async {
    if (_formKey.currentState!.validate()) {
      title = programNameController.text;
      if (title.isNotEmpty &&
          (isLink && linkController.text.isNotEmpty ||
              isFile && file != null)) {
        final String? uploadedPath =
            isFile ? await _uploadFileToFirebase(file!) : null;
        // A failed upload already showed an error: do not save an empty entry.
        if (isFile && uploadedPath == null) return;
        final dataToSave = {
          'title': title,
          'link': isLink ? linkController.text : '',
          'path': uploadedPath,
        };

        await FirebaseFirestore.instance
            .collection('club_${widget.selectedOption}')
            .doc(widget.documentId)
            .update({
          'file': FieldValue.arrayUnion([dataToSave])
        });
        _reload();
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

    final bool opened = await openLink(url);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore nell\'apertura del link')),
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
    if (mounted) _reload();

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

  DocumentReference<Map<String, dynamic>> get _programRef => FirebaseFirestore
      .instance
      .collection('club_${widget.selectedOption}')
      .doc(widget.documentId);

  /// Adds/removes this user in [field] and takes them out of [otherField]
  /// (present <-> absent), changing only this user's entry on the server.
  Future<void> _toggleList({
    required String field,
    required String otherField,
    required String addedMessage,
    required String removedMessage,
  }) async {
    if (!_data.containsKey(field)) return;
    final bool has = (_data[field] as List).contains(widget.name);
    try {
      await setPresence(_programRef,
          name: widget.name,
          field: field,
          otherField: otherField,
          join: !has);
    } catch (e) {
      _showSaveError();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(has ? removedMessage : addedMessage)));
    await _refreshBookings();
  }

  Future<void> _toggleReservation() => _toggleList(
      field: 'prenotazioni',
      otherField: 'assenze',
      addedMessage: 'Presenza confermata',
      removedMessage: 'Presenza cancellata');

  Future<void> _toggleReservationFood() => _toggleList(
      field: 'prenotazionePranzo',
      otherField: 'assenzaPranzo',
      addedMessage: 'Presenza confermata',
      removedMessage: 'Presenza cancellata');

  Future<void> _toggleAbsence() => _toggleList(
      field: 'assenze',
      otherField: 'prenotazioni',
      addedMessage: 'Assenza confermata',
      removedMessage: 'Assenza cancellata');

  Future<void> _toggleAbsenceFood() => _toggleList(
      field: 'assenzaPranzo',
      otherField: 'prenotazionePranzo',
      addedMessage: 'Assenza confermata',
      removedMessage: 'Assenza cancellata');

  // --- Amici (Friends) Management ---

  List<String> get _allPresenti {
    List<String> result = List<String>.from(_data['prenotazioni'] ?? []);
    if (_data.containsKey('amici')) {
      Map<String, dynamic> amici = _data['amici'];
      amici.forEach((key, value) {
        result.addAll((value as List).cast<String>());
      });
    }
    return result;
  }

  List<String> get _allPresentiPranzo {
    List<String> result = List<String>.from(_data['prenotazionePranzo'] ?? []);
    if (_data.containsKey('amiciPranzo')) {
      Map<String, dynamic> amiciPranzo = _data['amiciPranzo'];
      amiciPranzo.forEach((key, value) {
        result.addAll((value as List).cast<String>());
      });
    }
    return result;
  }

  List<String> get _myAmici {
    if (!_data.containsKey('amici')) return [];
    Map<String, dynamic> amici = _data['amici'];
    if (!amici.containsKey(widget.name)) return [];
    return List<String>.from(amici[widget.name]);
  }

  bool _isRestrictedRole() {
    if (_data.isEmpty) return true;
    if (widget.club == 'Delta Club' &&
        _data['selectedOption'] == 'trip' &&
        (widget.role == 'Ragazzo' || newRole == 'Ragazzo') &&
        !_data['selectedClass'].any((className) =>
            ['3° liceo', '4° liceo', '5° liceo'].contains(className)) &&
        _data['selectedClass'].any((className) =>
            ['1° liceo', '2° liceo'].contains(className))) {
      return true;
    }
    if (widget.club == 'Delta Club' &&
        _data['selectedOption'] == 'weekend' &&
        (widget.role == 'Genitore' || newRole == 'Genitore')) {
      return true;
    }
    if (widget.club == 'Tiber Club' &&
        _data['selectedOption'] == 'weekend' &&
        (widget.role == 'Genitore' || newRole == 'Genitore') &&
        !_data['selectedClass'].any((className) =>
            ['4° elem', '5° elem', '1° media', '2° media', '3° media']
                .contains(className))) {
      return true;
    }
    return false;
  }

  Future<void> _saveMyAmici(String field, List<String> myAmici) async {
    await saveFriends(_programRef,
        field: field, userName: widget.name, friends: myAmici);
    await _refreshBookings();
  }

  Future<void> _addAmicoGeneric(
      String field, List<String> current, String name, String message) async {
    if (name.trim().isEmpty) return;
    final List<String> myAmici = List<String>.from(current)..add(name.trim());
    try {
      await _saveMyAmici(field, myAmici);
    } catch (e) {
      _showSaveError();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${name.trim()} $message')));
  }

  Future<void> _removeAmicoGeneric(
      String field, List<String> current, String name, String message) async {
    final List<String> myAmici = List<String>.from(current)..remove(name);
    try {
      await _saveMyAmici(field, myAmici);
    } catch (e) {
      _showSaveError();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$name $message')));
  }

  Future<void> _editAmicoGeneric(String field, List<String> current,
      String oldName, String newName) async {
    if (newName.trim().isEmpty) return;
    final List<String> myAmici = List<String>.from(current);
    final int index = myAmici.indexOf(oldName);
    if (index != -1) {
      myAmici[index] = newName.trim();
    }
    try {
      await _saveMyAmici(field, myAmici);
    } catch (e) {
      _showSaveError();
    }
  }

  Future<void> _removeAmico(String name) => _removeAmicoGeneric(
      'amici', _myAmici, name, 'rimosso dai presenti');

  Future<void> _editAmico(String oldName, String newName) =>
      _editAmicoGeneric('amici', _myAmici, oldName, newName);

  Future<void> _addAmicoProgramma(String name) async {
    await _addAmicoGeneric(
        'amici', _myAmici, name, 'aggiunto ai presenti');
    if (mounted) _amiciProgrammaController.clear();
  }

  Future<void> _addAmicoPranzo(String name) async {
    await _addAmicoGeneric(
        'amiciPranzo', _myAmiciPranzo, name, 'aggiunto ai presenti pranzo');
    if (mounted) _amiciPranzoController.clear();
  }

  Future<void> _removeAmicoPranzo(String name) => _removeAmicoGeneric(
      'amiciPranzo', _myAmiciPranzo, name, 'rimosso dai presenti pranzo');

  Future<void> _editAmicoPranzo(String oldName, String newName) =>
      _editAmicoGeneric('amiciPranzo', _myAmiciPranzo, oldName, newName);

  void _showEditAmiciDialog(String name) {
    TextEditingController editController =
        TextEditingController(text: name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica amico'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            hintText: 'Nome amico',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              _editAmico(name, editController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAmiciDialog(String name) {
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
              _removeAmico(name);
              Navigator.of(context).pop();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  final TextEditingController _amiciProgrammaController = TextEditingController();
  final TextEditingController _amiciPranzoController = TextEditingController();

  List<String> get _myAmiciPranzo {
    if (!_data.containsKey('amiciPranzo')) return [];
    Map<String, dynamic> amiciPranzo = _data['amiciPranzo'];
    if (!amiciPranzo.containsKey(widget.name)) return [];
    return List<String>.from(amiciPranzo[widget.name]);
  }

  void _showEditAmiciPranzoDialog(String name) {
    TextEditingController editController =
        TextEditingController(text: name);
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
              _editAmicoPranzo(name, editController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAmiciPranzoDialog(String name) {
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
              _removeAmicoPranzo(name);
              Navigator.of(context).pop();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  Widget _buildAmiciContainer({required String type}) {
    final bool isPranzo = type == 'pranzo';
    final controller = isPranzo ? _amiciPranzoController : _amiciProgrammaController;
    final myFriends = isPranzo ? _myAmiciPranzo : _myAmici;
    final addFn = isPranzo ? _addAmicoPranzo : _addAmicoProgramma;
    final editFn = isPranzo ? _showEditAmiciPranzoDialog : _showEditAmiciDialog;
    final deleteFn = isPranzo ? _showDeleteAmiciPranzoDialog : _showDeleteAmiciDialog;
    final label = isPranzo ? 'Aggiungi amici pasto' : 'Aggiungi amici';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      margin: const EdgeInsets.fromLTRB(0, 10.0, 0, 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add, size: 30, color: Colors.black),
              const SizedBox(width: 10),
              AutoSizeText(
                label,
                style: const TextStyle(
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
                  onSubmitted: (value) => addFn(value),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => addFn(controller.text),
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
                        onPressed: () => editFn(name),
                        icon: const Icon(Icons.edit,
                            color: Colors.black, size: 22),
                      ),
                      IconButton(
                        onPressed: () => deleteFn(name),
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
                SharePlus.instance.share(ShareParams(text: '${_data['title']}\n\n'
                    '${_data['address']}\n\n'
                    'Dal ${_data['startDate']} al ${_data['endDate']}\n\n'
                    '${_data['description']}\n'));
              } else {
                SharePlus.instance.share(ShareParams(text: '${_data['title']}\n\n'
                    '${_data['address']}\n\n'
                    '${_data['startDate']}\n\n'
                    '${_data['description']}\n'));
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
          future: _loadFuture,
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
                          Icons.calendar_today,
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
                      _data['inizio'].isNotEmpty?
                      ListTile(
                        leading: const Icon(
                          Icons.timelapse,
                          size: 30,
                        ),
                        title: const Text('Orario',
                            style: TextStyle(color: Colors.black54)),
                        subtitle: AutoSizeText(
                          _data['selectedOption']=='weekend' ?
                            _data['fine'].isNotEmpty?
                            'Dalle ${_data['inizio']} alle ${_data['fine']}'
                            : '${_data['inizio']}'
                          : _data['fine'].isNotEmpty?
                            'Partenza: ${_data['inizio']} - Rientro: ${_data['fine']}'
                            : 'Partenza: ${_data['inizio']}',
                          style: const TextStyle(fontSize: 20.0),
                          maxLines: 2,
                          minFontSize: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ) : Container(),
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
                                    'Presenti (${_allPresenti.length})',
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
                                        'Presenti (${_allPresenti.length})',
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
                                                  'Presenti (${_allPresenti.length}) - Assenti (${_data['assenze'].length})',
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
                                                  if (_allPresenti.isNotEmpty)
                                                    ..._allPresenti
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
                                                  'Prenotazioni (${_allPresenti.length})',
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
                      // Amici programma
                      if (_data.containsKey('prenotazioni') &&
                          _data.containsKey('assenze') &&
                          !_isRestrictedRole())
                        _buildAmiciContainer(type: 'programma'),
                      //pranzo
                      if (_data.containsKey('pasto') && (widget.role != 'Genitore' || (newRole != '' && newRole != 'Genitore')))
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
                                    (widget.role != 'Genitore' || (newRole != '' && newRole != 'Genitore')))
                                  Column(
                                    children: [
                                      ExpansionTile(
                                        title: AutoSizeText(
                                            'Presenti (${_allPresentiPranzo.length}) - Assenti (${_data['assenzaPranzo'].length})',
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
                                          if (_allPresentiPranzo.isNotEmpty)
                                            ..._allPresentiPranzo
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
                                    (widget.role == 'Genitore' || (newRole != '' && newRole == 'Genitore')))
                                  Column(
                                    children: [
                                      const SizedBox(height: 20.0),
                                      AutoSizeText(
                                          'Prenotazioni (${_allPresentiPranzo.length})',
                                          style: const TextStyle(fontSize: 20),
                                          maxLines: 1,
                                          minFontSize: 15,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 20.0),
                                    ],
                                  ),
                              ])
                            ])),
                      // Amici pranzo
                      if (_data.containsKey('pasto') &&
                          (widget.role != 'Genitore' || (newRole != '' && newRole != 'Genitore')))
                        _buildAmiciContainer(type: 'pranzo'),
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
                      const SizedBox(height: 80),
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
