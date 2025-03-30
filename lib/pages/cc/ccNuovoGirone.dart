import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ccNuovoGirone extends StatefulWidget {
  @override
  _ccNuovoGironeState createState() => _ccNuovoGironeState();
}

class _ccNuovoGironeState extends State<ccNuovoGirone> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeGironeController = TextEditingController();
  List<String> squadreDisponibili = [];
  List<String> squadreSelezionate = [];

  Future<void> _getSquadre() async {
    final QuerySnapshot squadreSnapshot = await FirebaseFirestore.instance.collection('ccSquadre').get();
    setState(() {
      squadreDisponibili = [''];
      for (var doc in squadreSnapshot.docs) {
        List<dynamic> squadreList = doc['squadre'];
        for (var squadra in squadreList) {
          squadreDisponibili.add(squadra['squadra']);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getSquadre();
  }

  Map<String, int> _initializeMap(List<String> squadre) {
    return {for (var squadra in squadre) squadra: 0};
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

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo girone'),
      ),
      body: SingleChildScrollView(
              child: Padding( 
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Form(
          key: _formKey,
          child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nomeGironeController,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Obbligatorio';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Girone',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color.fromARGB(255, 25, 84, 132)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Obbligatorio';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'N° squadre',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color.fromARGB(255, 25, 84, 132)),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              final int? numSquadre = int.tryParse(value);
                              if (numSquadre != null) {
                                squadreSelezionate = List.filled(numSquadre, '');
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(squadreSelezionate.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: getInputDecoration('Squadra ${index + 1}'),
                              items: squadreDisponibili
                                  .where((squadra) => !squadreSelezionate.contains(squadra) || squadreSelezionate[index] == squadra)
                                  .map((squadra) {
                                return DropdownMenuItem(
                                  value: squadra,
                                  child: Text(squadra),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  squadreSelezionate[index] = value!;
                                });
                              },
                              value: squadreSelezionate[index].isEmpty ? null : squadreSelezionate[index],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _showLoadingDialog();
                        final Map<String, int> mappa = _initializeMap(squadreSelezionate);
                        await FirebaseFirestore.instance.collection('ccGironi').doc(_nomeGironeController.text).set({
                          'nome': _nomeGironeController.text,
                          'squadre': squadreSelezionate,
                          'punti' : mappa,
                          'goalFatti': mappa,
                          'goalSubiti': mappa,
                          'diffReti': mappa,
                          'partiteG': mappa,
                          'cartGialli': mappa,
                        });
                        Navigator.of(context).pop();
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('Crea'),
                  ),
                ],
              )),),
            ),
    );
  }
}
