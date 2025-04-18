import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';

class Tiber extends StatelessWidget {
  const Tiber({super.key, required this.club});

  final String club;

  @override
  Widget build(BuildContext context) {
    final FirebaseStorage storage = FirebaseStorage.instance;

    Future<void> openFileOrLink(String? url) async {
      if (url == null || url.isEmpty) {
        return;
      }
      FlutterWebBrowser.openWebPage(url: url);
    }

    const TextStyle textStyle = TextStyle(
      fontSize: 20.0,
      color: Colors.black,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.topCenter,
              child: Image.asset(
                'images/tiberlogo.png',
                width: 150,
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text:
                    'Il $club è un\'associazione familiare che si rivolge a ragazzi di medie e liceo, '
                    'con lo scopo di promuovere la loro crescita attraverso '
                    'attività formative, sportive e culturali\n\n',
                style: textStyle.copyWith(fontWeight: FontWeight.normal),
                children: const <TextSpan>[
                  TextSpan(
                    text:
                        'La gioventù non è un tempo morto, ma quello dei più grandi ideali!',
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold),
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
                          '15:30 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Scuola Calcio',
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
                          '17:30 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Merenda',
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
                          '17:45 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Studio',
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
                          '19:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Fine',
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
                          '15:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Calcio',
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
                          '17:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Merenda',
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
                          '17:30 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Meditazione',
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
                          '18:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Programma',
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
                          '19:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Fine',
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
            Material(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: ListTile.divideTiles(context: context, tiles: [
                  ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: const AutoSizeText(
                        'Orario e iscrizione',
                        style: TextStyle(fontSize: 18.0),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                      onTap: () async {
                        final ref = storage
                            .ref()
                            .child('Orari/IscrizioneTiber2024-25.pdf');
                        final url = await ref.getDownloadURL();
                        openFileOrLink(url);
                      }),
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
                      FlutterWebBrowser.openWebPage(
                          url:
                              'https://www.google.com/maps/search/?api=1&query=41.918306,12.474556');
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
                      FlutterWebBrowser.openWebPage(
                          url:
                              'https://www.iubenda.com/privacy-policy/69534588');
                    },
                  ),
                ]).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class Delta extends StatefulWidget {
  const Delta({super.key, required this.club, required this.role, required this.isAdmin});

  final String club;
  final String role;
  final bool isAdmin;

  @override
  State<Delta> createState() => _DeltaState();
}

class _DeltaState extends State<Delta> {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _openFileOrLink(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }
    FlutterWebBrowser.openWebPage(url: url);
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle textStyle = TextStyle(
      fontSize: 20.0,
      color: Colors.black,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.topCenter,
              child: Image.asset(
                'images/deltalogo.jpg',
                width: 150,
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text:
                    'Il Centro Delta è un luogo d\'incontro per ragazzi delle superiori, '
                    'con lo scopo di promuovere la loro crescita attraverso '
                    'attività formative, sportive e culturali\n\n',
                style: textStyle.copyWith(fontWeight: FontWeight.normal),
                children: const <TextSpan>[
                  TextSpan(
                    text:
                        'La gioventù non è un tempo morto, ma quello dei più grandi ideali!',
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold),
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
                      'Lunedì, mercoledì e venerdì',
                      textAlign: TextAlign.left,
                      style: textStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.book),
                        const SizedBox(width: 10),
                        Text(
                          '15:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Studio',
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
                          '17:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Merenda',
                            style: textStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.local_activity),
                        const SizedBox(width: 10),
                        Text(
                          '17:30 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Attività varie',
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
                          '19:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Fine',
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
                      'Sabato (2 al mese)',
                      textAlign: TextAlign.left,
                      style: textStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.local_activity),
                        const SizedBox(width: 10),
                        Text(
                          '15:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Sport, gite, giochi...',
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
                          '19:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Fine',
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
            Material(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: ListTile.divideTiles(context: context, tiles: [
                  widget.role == 'Genitore' || widget.isAdmin
                      ? ListTile(
                          leading: const Icon(Icons.create),
                          title: const AutoSizeText(
                            'Modulo d\'iscrizione',
                            style: TextStyle(fontSize: 18.0),
                            maxLines: 1,
                            minFontSize: 10,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 20),
                          onTap: () {
                            FlutterWebBrowser.openWebPage(
                                url:
                                    'https://docs.google.com/forms/d/e/1FAIpQLScJXN1-8E4ICh7-LdoToH82lWQMljiFW4p2jnmEDpuYU5bFqQ/viewform?usp=sf_link');
                          })
                      : Container(),
                  ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const AutoSizeText(
                        'Programma dettagliato',
                        style: TextStyle(fontSize: 18.0),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                      onTap: () async {
                        final ref =
                            _storage.ref().child('Orari/OrarioDelta.pdf');
                        final url = await ref.getDownloadURL();
                        _openFileOrLink(url);
                      }),
                  ListTile(
                    leading: const Icon(Icons.web),
                    title: const AutoSizeText(
                      'Sito web',
                      style: TextStyle(fontSize: 18.0),
                      maxLines: 1,
                      minFontSize: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                    onTap: () {
                      FlutterWebBrowser.openWebPage(
                          url: 'https://bit.ly/m/centrodelta');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const AutoSizeText(
                      'Via Alberto da Giussano, 6, MI',
                      style: TextStyle(fontSize: 18.0),
                      maxLines: 1,
                      minFontSize: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                    onTap: () {
                      FlutterWebBrowser.openWebPage(
                          url:
                              'https://www.google.com/maps/search/?api=1&query=45.468245,9.164332');
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
                      FlutterWebBrowser.openWebPage(
                          url:
                              'https://www.iubenda.com/privacy-policy/69534588');
                    },
                  ),
                ]).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class Rampa extends StatefulWidget {
  const Rampa({super.key, required this.club, required this.role, required this.isAdmin});

  final String club;
  final String role;
  final bool isAdmin;

  @override
  State<Rampa> createState() => _RampaState();
}

class _RampaState extends State<Rampa> {

  @override
  Widget build(BuildContext context) {
    const TextStyle textStyle = TextStyle(
      fontSize: 20.0,
      color: Colors.black,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.topCenter,
              child: Image.asset(
                'images/rampalogo.jpg',
                width: 150,
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text:
                    'Il Rampa Club è un luogo d\'incontro per ragazzi delle superiori, '
                    'con lo scopo di promuovere la loro crescita attraverso '
                    'attività formative, sportive e culturali\n\n',
                style: textStyle.copyWith(fontWeight: FontWeight.normal),
                children: const <TextSpan>[
                  TextSpan(
                    text:
                        'La gioventù non è un tempo morto, ma quello dei più grandi ideali!',
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold),
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
                      'Martedì',
                      textAlign: TextAlign.left,
                      style: textStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.food_bank),
                        const SizedBox(width: 10),
                        Text(
                          '13:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Pranzo',
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
                          '14:30 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Studio',
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
                          '17:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Conversazione',
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
                          '17:30 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Merenda',
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
                          '18:30 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Fine',
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
                        const Icon(Icons.local_activity),
                        const SizedBox(width: 10),
                        Text(
                          '15:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Sport, gite, giochi...',
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
                          '17:00 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Merenda',
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
                          '17:30 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Meditazione',
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
                          '18:30 - ',
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Expanded(
                          child: Text(
                            'Fine',
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
            Material(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: ListTile.divideTiles(context: context, tiles: [
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const AutoSizeText(
                      'Via Antonio Gramsci, 154, SSG',
                      style: TextStyle(fontSize: 18.0),
                      maxLines: 1,
                      minFontSize: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                    onTap: () {
                      FlutterWebBrowser.openWebPage(
                          url:
                              'https://www.google.com/maps/place/Associazione+Idea+Sestopiu/@45.5382134,9.2352257,19.75z/data=!4m6!3m5!1s0x4786b899be7ec9b9:0xfa3ed9ca3dc476e4!8m2!3d45.5383815!4d9.2354612!16s%2Fg%2F11clygy1bz?entry=ttu&g_ep=EgoyMDI1MDMyNS4xIKXMDSoASAFQAw%3D%3D');
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
                      FlutterWebBrowser.openWebPage(
                          url:
                              'https://www.iubenda.com/privacy-policy/69534588');
                    },
                  ),
                ]).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
