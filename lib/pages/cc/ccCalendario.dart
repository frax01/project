import 'package:flutter/material.dart';
import 'ccNuovaPartitaGironi.dart';

class CCCalendario extends StatefulWidget {
  const CCCalendario({
    super.key,
  });

  @override
  State<CCCalendario> createState() => _CCCalendarioState();
}

class _CCCalendarioState extends State<CCCalendario> {
  String _selectedSegment = 'Gironi';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
              child: Column(children: [
            SegmentedButton<String>(
              selectedIcon: const Icon(Icons.check),
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'Gironi',
                  label: Text('Gir', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment<String>(
                  value: 'Ottavi',
                  label: Text('Ott', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment<String>(
                  value: 'Quarti',
                  label: Text('Qua', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment<String>(
                  value: 'Semifinali',
                  label: Text('Sem', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment<String>(
                  value: 'Finali',
                  label: Text('Fin', style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: <String>{_selectedSegment},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedSegment = newSelection.first;
                });
              },
            ),
            //SIzedBox
            //Partite
          ]))),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CCnuovaPartitaGironi()),
          );
        },
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}
