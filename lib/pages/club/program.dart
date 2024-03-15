import 'package:flutter/material.dart';

class ProgramScreen extends StatelessWidget {
  const ProgramScreen({
    Key? key,
    required this.document,
    required this.weather,
  }) : super(key: key);

  final Map document;
  final Map weather;

  Widget weatherTile(Map weather) {
    if (weather["check"]) {
      return ListTile(
        leading: Image.network(weather["image"], width: 50, height: 50),
        title: Text('${weather["t_max"]}ºC'),
        subtitle: Text('${weather["t_min"]}ºC'),
      );
    } else {
      return const ListTile(
        title: Text('Nessuna informazione meteo'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
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
                    child: Image.network(
                      document['imagePath'],
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
                              offset: const Offset(
                                  0, 3), // changes position of shadow
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: Text(
                            document['title'],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          avatar: document['selectedOption'] == 'weekend'
                              ? const Icon(Icons.calendar_today)
                              : document['selectedOption'] == 'trip'
                                  ? const Icon(Icons.holiday_village)
                                  : const Icon(Icons.star),
                          label: Text(document['selectedOption'].toString().toUpperCase()),
                          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Chip(
                          label: Text(document['selectedClass'].toString().toUpperCase()),
                          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      'Descrizione',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      document['description'],
                      style: const TextStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      'Quando',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      document['endDate'].isNotEmpty
                          ? '${document['startDate']} ~ ${document['endDate']}'
                          : document['startDate'],
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      'Dove',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      document['address'],
                      style: const TextStyle(fontSize: 15),
                    ),
                    weatherTile(weather),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}