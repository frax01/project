import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class CCNuovoProgramma extends StatefulWidget {
  final String? programmaId;
  final String? data;
  final String? orario;
  final String? titolo;
  final List<dynamic>? squadre;
  final List<dynamic>? incarico;
  final String? altro;
  final String? codice;
  final String? categoria;

  const CCNuovoProgramma({
    super.key,
    this.programmaId,
    this.data,
    this.orario,
    this.titolo,
    this.squadre,
    this.incarico,
    this.altro,
    this.codice,
    this.categoria,
  });

  @override
  State<CCNuovoProgramma> createState() => _CCNuovoProgrammaState();
}

class _CCNuovoProgrammaState extends State<CCNuovoProgramma> {
  final _formKey = GlobalKey<FormState>();
  final _dataController = TextEditingController();
  final _orarioController = TextEditingController();
  final _titoloController = TextEditingController();
  final _altroController = TextEditingController();
  final _codiceController = TextEditingController();
  final _categoriaController = TextEditingController();

  List<dynamic> _selectedSquadre = [];
  List<dynamic> _selectedIncarico = [];
  List<String> _squadreOptions = [];
  List<String> _incaricoOptions = [];

  @override
  void initState() {
    super.initState();
    if (widget.data != null) _dataController.text = widget.data!;
    if (widget.orario != null) _orarioController.text = widget.orario!;
    if (widget.titolo != null) _titoloController.text = widget.titolo!;
    if (widget.squadre != null) _selectedSquadre = widget.squadre!;
    if (widget.incarico != null) _selectedIncarico = widget.incarico!;
    if (widget.altro != null) _altroController.text = widget.altro!;
    if (widget.codice != null) _codiceController.text = widget.codice!;
    if (widget.categoria != null) _categoriaController.text = widget.categoria!;
    _loadSquadreOptions();
    _loadIncaricoOptions();
  }

  Future<void> _loadSquadreOptions() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('ccIscrizioniSquadre').get();
    setState(() {
      _squadreOptions = querySnapshot.docs.map((doc) => doc['nomeSquadra'] as String).toList();
    });
  }

  Future<void> _loadIncaricoOptions() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('ccIscrizioniSquadre').get();
    setState(() {
      _incaricoOptions = querySnapshot.docs.map((doc) => doc['nomeSquadra'] as String).toList();
    });
  }

  @override
  void dispose() {
    _dataController.dispose();
    _orarioController.dispose();
    _titoloController.dispose();
    _altroController.dispose();
    _codiceController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  Future<void> _saveProgramma() async {
    if (_formKey.currentState!.validate()) {
      final data = _dataController.text;
      final orario = _orarioController.text;
      final titolo = _titoloController.text;
      final altro = _altroController.text;
      final codice = _codiceController.text;
      final categoria = _categoriaController.text;

      final programma = {
        'data': data,
        'orario': orario,
        'titolo': titolo,
        'squadre': _selectedSquadre,
        'incarico': _selectedIncarico,
        'altro': altro,
        'codice': codice,
        'categoria': categoria,
      };

      if (widget.programmaId == null) {
        await FirebaseFirestore.instance.collection('ccProgramma').add(programma);
      } else {
        await FirebaseFirestore.instance.collection('ccProgramma').doc(widget.programmaId).update(programma);
      }

      Navigator.pop(context);
    }
  }

  Future<String?> _selectTime() async {
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

  InputDecoration getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black54),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black54),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 25, 84, 132)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Programma'),
      ),
      body: SingleChildScrollView(
            child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _dataController.text.isEmpty ? null : _dataController.text,
                decoration: const InputDecoration(labelText: 'Data'),
                items: const [
                  DropdownMenuItem(value: '24/04/2025', child: Text('24/04/2025')),
                  DropdownMenuItem(value: '25/04/2025', child: Text('25/04/2025')),
                  DropdownMenuItem(value: '26/04/2025', child: Text('26/04/2025')),
                  DropdownMenuItem(value: '27/04/2025', child: Text('27/04/2025')),
                ],
                onChanged: (value) {
                  _dataController.text = value!;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La data è obbligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final String? orario = await _selectTime();
                  if (orario != null) {
                    setState(() {
                      _orarioController.text = orario;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _orarioController,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) {
                      setState(() {
                        _orarioController.text = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'L\'orario è obbligatorio';
                      }
                      return null;
                    },
                    decoration: getInputDecoration('Orario'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titoloController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Titolo'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Il titolo è obbligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              MultiSelectDialogField(
                title: const Text('Squadre'),
                selectedColor: Theme.of(context).primaryColor,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                items: _squadreOptions
                    .map((option) => MultiSelectItem<String>(option, option))
                    .toList(),
                buttonText: const Text('Squadre'),
                confirmText: const Text('Ok'),
                cancelText: const Text('Annulla'),
                initialValue: _selectedSquadre,
                onConfirm: (value) {
                  setState(() {
                    _selectedSquadre = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              MultiSelectDialogField(
                title: const Text('Incarico'),
                selectedColor: Theme.of(context).primaryColor,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                items: _incaricoOptions
                    .map((option) => MultiSelectItem<String>(option, option))
                    .toList(),
                buttonText: const Text('Incarico'),
                confirmText: const Text('Ok'),
                cancelText: const Text('Annulla'),
                initialValue: _selectedIncarico,
                onConfirm: (value) {
                  setState(() {
                    _selectedIncarico = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _altroController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Altro'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoriaController.text.isEmpty ? null : _categoriaController.text,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: const [
                  DropdownMenuItem(value: 'pasto', child: Text('Pasto')),
                  DropdownMenuItem(value: 'partita', child: Text('Partita')),
                  DropdownMenuItem(value: 'show', child: Text('Show')),
                  DropdownMenuItem(value: 'altro', child: Text('Altro')),
                ],
                onChanged: (value) {
                  _categoriaController.text = value!;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La categoria è obbligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codiceController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Codice'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveProgramma,
                child: const Text('Salva'),
              ),
              if (widget.programmaId != null)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    bool confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Conferma eliminazione'),
                        content: const Text('Sei sicuro di voler eliminare questo programma?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Sì'),
                          ),
                        ],
                      ),
                    );
                    if (confirm) {
                      await FirebaseFirestore.instance.collection('ccProgramma').doc(widget.programmaId).delete();
                      Navigator.pop(context);
                    }
                  },
                ),
            ],
          ),
        ),
      ),)
    );
  }
}

//programma['categoria'] == 'pasto'
                                      //    ? Colors.amber[100]
                                      //    : programma['categoria'] == 'partita'
                                      //        ? Colors.green[100]
                                      //        : programma['categoria'] == 'show'
                                      //            ? Colors.blue[100]
                                      //            : programma['categoria'] == 'altro'
                                      //                ? Colors.grey[100]
                                      //                : 
                                      //Colors.white,