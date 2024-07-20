import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_size_text/auto_size_text.dart';

class Info extends StatefulWidget {
  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  @override
  Widget build(BuildContext context) {
    const TextStyle textStyle = TextStyle(
      fontSize: 20.0,
      color: Colors.black,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.normal,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi siamo'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  'images/logo.png',
                  width: 150,
                ),
              ),
              const SizedBox(height: 20),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'Il Tiber Club è un\'associazione familiare che si rivolge a ragazzi di medie e liceo, '
                      'con lo scopo di promuovere la loro crescita attraverso '
                      'attività formative, sportive e culturali\n\n',
                  style: textStyle.copyWith(fontWeight: FontWeight.normal),
                  children: const <TextSpan>[
                    TextSpan(
                      text: 'La gioventù non è un tempo morto, ma quello dei più grandi ideali!',
                      style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Martedì e giovedì',
                        textAlign: TextAlign.left,
                        style: textStyle.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.sports_soccer),
                          const SizedBox(width: 10),
                          Text(
                            '15:30',
                            style: textStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Expanded(
                            child: Text(
                              ' - Scuola Calcio',
                              style: textStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.fastfood),
                          const SizedBox(width: 10),
                          Text(
                            '17:30',
                            style: textStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Expanded(
                            child: Text(
                              ' - Merenda',
                              style: textStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.book),
                          const SizedBox(width: 10),
                          Text(
                            '17:45',
                            style: textStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Expanded(
                            child: Text(
                              ' - Studio',
                              style: textStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.flag),
                          const SizedBox(width: 10),
                          Text(
                            '19:00',
                            style: textStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Expanded(
                            child: Text(
                              ' - Fine',
                              style: textStyle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sabato',
                        textAlign: TextAlign.left,
                        style: textStyle.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.sports_soccer),
                          const SizedBox(width: 10),
                          Text(
                            '15:00',
                            style: textStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Expanded(
                            child: Text(
                              ' - Calcio',
                              style: textStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.fastfood),
                          const SizedBox(width: 10),
                          Text(
                            '17:00',
                            style: textStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Expanded(
                            child: Text(
                              ' - Merenda',
                              style: textStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.favorite),
                          const SizedBox(width: 10),
                          Text(
                            '17:30',
                            style: textStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Expanded(
                            child: Text(
                              ' - Meditazione',
                              style: textStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.event_note),
                          const SizedBox(width: 10),
                          Text(
                            '18:00',
                            style: textStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Expanded(
                            child: Text(
                              ' - Programma',
                              style: textStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.flag),
                          const SizedBox(width: 10),
                          Text(
                            '19:00',
                            style: textStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Expanded(
                            child: Text(
                              ' - Fine',
                              style: textStyle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ListView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: ListTile.divideTiles(
                  context: context,
                  tiles: [
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const AutoSizeText(
                        'Via di Villa Giulia, 27, RM',
                        style: TextStyle(fontSize: 18.0),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                      onTap: () {
                        MapsLauncher.launchCoordinates(41.918306, 12.474556);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.policy),
                      title: const AutoSizeText(
                        'Privacy e policy',
                        style: TextStyle(fontSize: 18.0),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                      onTap: () {
                        launchUrl(Uri.parse('https://www.iubenda.com/privacy-policy/73232344'));
                      },
                    ),
                  ]
                ).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



