import 'package:adaptive_layout/adaptive_layout.dart';
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
    if (weather["check"] == "true" || weather["check"]) {
      return Row(
        children: [
          Image.network(weather["image"], width: 50, height: 50),
          const SizedBox(width: 10),
          Column(
            children: [
              Text('${weather["t_max"]}ºC'),
              Text('${weather["t_min"]}ºC'),
            ],
          ),
        ],
      );
    } else {
      return const ListTile(
        title:
            Text('Nessuna informazione\nmeteo', style: TextStyle(fontSize: 15)),
      );
    }
  }

  Widget details(document, weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Chip(
              label: Text(document['selectedOption'].toString().toUpperCase()),
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
            ),
            const SizedBox(width: 10),
            Chip(
              label: Text(document['selectedClass'].toString().toUpperCase()),
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
            ),
            const SizedBox(width: 10),
            Chip(
              label: Text(
                document['endDate'].isNotEmpty
                    ? '${document['startDate']} ~ ${document['endDate']}'
                    : document['startDate'],
              ),
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
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
            child: SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      document['address'],
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  weatherTile(weather),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20.0),
        Card(
          surfaceTintColor: Colors.white,
          elevation: 5,
          margin: const EdgeInsets.all(0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
                const SizedBox(width: 15),
                Text(
                  document['description'],
                  style: const TextStyle(fontSize: 17),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget smallScreen() {
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
                child: details(document, weather),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget bigScreen() {
    return Scaffold(
      appBar: AppBar(),
      body: Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: double.infinity,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 5,
                        child: Image.network(
                          document['imagePath'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 30,
                      right: -15,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              spreadRadius: 2,
                              blurRadius: 15,
                              offset:
                                  Offset(0, 3), // changes position of shadow
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: Text(
                            document['title'],
                            style: const TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                // flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(60, 20, 20, 20),
                  child: details(document, weather),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      smallLayout: smallScreen(),
      largeLayout: bigScreen(),
    );
  }
}
