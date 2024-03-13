import 'package:flutter/material.dart';

class ProgramScreen extends StatelessWidget {
  const ProgramScreen({
    Key? key,
    required this.document,
    required this.weather,
  }) : super(key: key);

  final Map document;
  final Map weather;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          document['title'],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Titolo: ${document['title']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Data iniziale: ${document['startDate']}'),
              Text('Classe: ${document['selectedClass']}'),
              Text('Categoria: ${document['selectedOption']}'),
              if (document['endDate'].isNotEmpty)
                Text('Data finale: ${document['endDate']}'),
              Image.network(document['imagePath'], height: 100, width: 100),
              Text('Descrizione: ${document['description']}'),
              Text('Dove: ${document['address']}'),
              if (weather["check"]) Text('Temp min: ${weather["t_min"]}'),
              if (weather["check"]) Text('Temp max: ${weather["t_max"]}'),
              if (weather["image"] != null && weather["image"]!.isNotEmpty)
                Image.network(weather["image"], height: 30, width: 30),
            ],
          ),
        ),
      ),
    );
  }
}
