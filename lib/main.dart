import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:club/pages/club/club.dart';
import 'package:club/pages/club/programPage.dart';
import 'package:club/pages/main/signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'color_schemes.dart';
import 'config.dart';
import 'functions/dataFunctions.dart';
import 'functions/generalFunctions.dart';
import 'functions/notificationFunctions.dart';
import 'pages/main/acceptance.dart';
import 'pages/main/login.dart';
import 'pages/main/waiting.dart';

void main() async {
  //timeDilation = 2.0;
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: Config.apiKey,
      authDomain: Config.authDomain,
      projectId: Config.projectId,
      storageBucket: Config.storageBucket,
      messagingSenderId: Config.messagingSenderId,
      appId: Config.appId,
    ),
  );

  FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  createNotificationChannel();
  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

  deleteOldDocuments();
  initializeDateFormatting();

  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  print("sono in background");
  showNotification(message);
}

//Future<void> _onForegroundMessageHandler(RemoteMessage message) async {
//  print("sono in foreground");
//  showNotification(message);
//}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      supportedLocales: const [
        Locale('it', 'IT'),
      ],
      title: 'Tiber Club',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
      ),
      themeMode: ThemeMode.light,
      home: const Login(
        title: 'Tiber Club',
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const Login(title: 'Tiber Club'),
        '/signup': (context) => const SignUp(title: 'Tiber Club'),
        '/waiting': (context) => const Waiting(title: 'Tiber Club'),
        '/acceptance': (context) => const AcceptancePage(title: 'Tiber Club'),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? email;
  bool terminated = false;

  Future<Map<String, dynamic>> retrieveData() async {
    CollectionReference user = FirebaseFirestore.instance.collection('user');
    QuerySnapshot querySnapshot1 =
        await user.where('email', isEqualTo: email).get();

    Map<String, dynamic> document = {
      'name': querySnapshot1.docs.first['name'],
      'surname': querySnapshot1.docs.first['surname'],
      'email': querySnapshot1.docs.first['email'],
      'role': querySnapshot1.docs.first['role'],
      'club_class': querySnapshot1.docs.first['club_class'],
      'soccer_class': querySnapshot1.docs.first['soccer_class'],
      'status': querySnapshot1.docs.first['status'],
      'birthdate': querySnapshot1.docs.first['birthdate'],
      'id': querySnapshot1.docs.first.id,
    };

    return document;
  }

  RemoteMessage? initialMessage;

  Future<void> setupInteractedMessage() async {
    //terminated: funziona
    initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print("sono sopra");
      setState(() {
        terminated = true;
      });
    }

    //background: funziona
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("sono qui");
      _handleMessage(message);
    });

    //foreground: non funziona
    //FirebaseMessaging.onMessage.listen(_onForegroundMessageHandler);

    //questo fa vedere la notifica a discesa
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      showNotification(message);

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  //Future<void> _onForegroundMessageHandler(RemoteMessage message) async {
  //  print("sono in foreground");
  //  showNotification(message);
  //}

  void _handleMessage(RemoteMessage message) {
    Map document = {
      'title': message.data["title"],
      'imagePath': message.data["imagePath"],
      'selectedClass': message.data["selectedClass"],
      'selectedOption': message.data["selectedOption"],
      'description': message.data["description"],
      'startDate': message.data["startDate"],
      'endDate': message.data["endDate"],
      'address': message.data["address"],
    };
    Map weather = {
      't_min': message.data["t_min"],
      't_max': message.data["t_max"],
      'w_code': message.data["w_code"],
      'image': message.data["image"],
      'check': message.data["check"],
    };
    print('Messaggio aperto mentre l\'app è in background: $message');
    if (message.data['category'] == 'new_user') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const AcceptancePage(title: 'Tiber Club')));
    } else if (message.data['category'] == 'accepted') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const Login(title: 'Tiber Club')));
    } else if (message.data['category'] == 'new_event') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProgramPage(
                    document: document,
                    weather: weather,
                    isAdmin: document['status'] == 'Admin',
                  )));
    } else if (message.data['category'] == 'modified_event') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProgramPage(
                    document: document,
                    weather: weather,
                    isAdmin: document['status'] == 'Admin',
                  )));
    }
  }

  @override
  void initState() {
    super.initState();
    setupInteractedMessage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset('images/logo.png'),
                  const SizedBox(height: 20.0),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text("Errore durante il recupero dei dati"),
            ),
          );
        } else {
          email = snapshot.data ?? '';
          if (email == '') {
            return const Login(title: "Asd Tiber Club");
          } else {
            return FutureBuilder<Map<String, dynamic>>(
              future: retrieveData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Image.asset('images/logo.png'),
                            const SizedBox(height: 20.0),
                            const CircularProgressIndicator(),
                          ]),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Scaffold(
                    body: Center(
                      child: Text("Errore durante il recupero dei dati."),
                    ),
                  );
                } else if (terminated == false) {
                  Map<String, dynamic> document = snapshot.data ?? {};
                  return ClubPage(title: "Tiber Club", document: document);
                  //Future.delayed(Duration.zero, () {
                  //  Navigator.push(
                  //      context,
                  //      MaterialPageRoute(
                  //          builder: (context) => ClubPage(
                  //              title: "Tiber Club", document: document)));
                  //});
                  //return Container();
                } else {
                  Map<String, dynamic> document = snapshot.data ?? {};
                  Map notificationDocument = {
                    'title': initialMessage?.data["title"],
                    'imagePath': initialMessage?.data["imagePath"],
                    'selectedClass': initialMessage?.data["selectedClass"],
                    'selectedOption': initialMessage?.data["selectedOption"],
                    'description': initialMessage?.data["description"],
                    'startDate': initialMessage?.data["startDate"],
                    'endDate': initialMessage?.data["endDate"],
                    'address': initialMessage?.data["address"],
                  };
                  Map weather = {
                    't_min': initialMessage?.data["t_min"],
                    't_max': initialMessage?.data["t_max"],
                    'w_code': initialMessage?.data["w_code"],
                    'image': initialMessage?.data["image"],
                    'check': initialMessage?.data["check"],
                  };
                  if (initialMessage?.data['category'] == 'new_user') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const AcceptancePage(title: 'Tiber Club')));
                    return ClubPage(title: "Tiber Club", document: document);
                  } else if (initialMessage?.data['category'] == 'accepted') {
                    return const Login(title: 'Tiber Club');
                  } else if (initialMessage?.data['category'] == 'new_event') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProgramPage(
                                  document: notificationDocument,
                                  weather: weather,
                                  isAdmin: document['status'] == 'Admin',
                                )));
                    return ClubPage(title: "Tiber Club", document: document);
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProgramPage(
                                  document: notificationDocument,
                                  weather: weather,
                                  isAdmin: document['status'] == 'Admin',
                                )));
                    return ClubPage(title: "Tiber Club", document: document);
                  }
                  //Navigator.push(
                  //  context,
                  //  MaterialPageRoute(
                  //    builder: (context) => ProgramScreen(
                  //        document: notificationDocument, weather: weather),
                  //  ),
                  //);
                  //return ClubPage(title: "Tiber Club", document: document);
                }
              },
            );
          }
        }
      },
    );
  }
}
