import 'package:club/pages/club/club.dart';
import 'package:club/pages/main/signup.dart';
import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'pages/main/login.dart';
import 'pages/main/waiting.dart';
import 'pages/main/acceptance.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'functions.dart';

void main() async {
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
  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

  deleteOldDocuments();
  initializeDateFormatting();

  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  createNotificationChannel();
  showNotification(message);

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
    //  Navigator.pushNamed(
    //    context,
    //    '/acceptance');
    });
}

void createNotificationChannel() {
  const AndroidNotificationChannel androidNotificationChannel =
      AndroidNotificationChannel(
    'default_notification_channel_id',
    'My Channel Name',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidNotificationChannel);
}

void showNotification(RemoteMessage remoteMessage) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'default_notification_channel_id',
    'My Channel Name',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidNotificationDetails);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.show(
    0,
    remoteMessage.notification!.title,
    remoteMessage.notification!.body,
    platformChannelSpecifics,
    payload: 'Default_Sound',
  );
}

void deleteOldDocuments() async {
  final firestore = FirebaseFirestore.instance;
  final today = DateTime.now();

  final oneDateCollections = [
    'club_extra',
    'club_weekend',
  ];
  for (final collection in oneDateCollections) {
    final querySnapshot = await firestore.collection(collection).get();
    for (final document in querySnapshot.docs) {
      final startDateString = document.data()['startDate'] as String;
      final startDate =
          DateTime.parse(startDateString.split('-').reversed.join('-'));
      if (startDate.isBefore(today)) {
        await document.reference.delete();
      }
    }
  }

  final twoDateCollections = [
    'club_summer',
    'club_trip',
  ];
  for (final collection in twoDateCollections) {
    final querySnapshot = await firestore.collection(collection).get();
    for (final document in querySnapshot.docs) {
      final startDateString = document.data()['endDate'] as String;
      final startDate =
          DateTime.parse(startDateString.split('-').reversed.join('-'));
      if (startDate.isBefore(today)) {
        await document.reference.delete();
      }
    }
  }
}

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
      title: 'Club App',
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
      initialRoute: '/homepage',
      routes: {
        '/homepage': (context) => const HomePage(),
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

//
  //  FirebaseMessaging.onMessage.listen(showNotification);
//
  //  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //    print('A new onMessageOpenedApp event was published!');
  //    Navigator.pushNamed(context, '/acceptance');
  //  });
//

//
  //  //primo piano
  //  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //    print('Got a message whilst in the foreground!');
  //    print('Message data: ${message.data}');
//
  //    //if (message.notification != null) {
  //    //  Navigator.pushNamed(context, '/acceptance');
  //    //  print('Message also contained a notification: ${message.notification}');
  //    //}
  //  });
//
  //  //background
  //  print("cioaoooo");
  //  //FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  //}
//
  //void _handleMessage(RemoteMessage message) {
  //  if (message.data["category"] == 'modified_event') {
  //    print("sono qui");
  //    Navigator.pushNamed(context, '/acceptance');
  //  } else {
  //    print("helloooo");
  //  }
  //}

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

  Future<String> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  //String? initialMessage;

  @override
  void initState() {
    super.initState();

    FirebaseMessaging.instance.getInitialMessage().then(
  (value) {
    RemoteMessage? initialMessage = value;
    String x;
    if (initialMessage == null || initialMessage.data.isEmpty) {
      x = 'null';
      sendNotification([
      'f1QP4F2hQ4G8c21NnliqST:APA91bHb5beI32WGr-Olb95hDitqSy06FL0yfhf0VR5Xism6pIcem2tzLEMHOju57sUXcU3S7VYKI5tL1kHOWsjJpEdpv7GkeSu2YnRTXrX-IxlFNkp0D1Iy4S7gVL73ahODo0n0oXpI'
    ], 'questo', 'nessuna categoria', 'prova');
    } else {
      x = 'yesss';
      sendNotification([
      'f1QP4F2hQ4G8c21NnliqST:APA91bHb5beI32WGr-Olb95hDitqSy06FL0yfhf0VR5Xism6pIcem2tzLEMHOju57sUXcU3S7VYKI5tL1kHOWsjJpEdpv7GkeSu2YnRTXrX-IxlFNkp0D1Iy4S7gVL73ahODo0n0oXpI'
    ], 'questo', initialMessage.data['category']?? 'nessun valore', 'prova');
    }
    sendNotification([
      'f1QP4F2hQ4G8c21NnliqST:APA91bHb5beI32WGr-Olb95hDitqSy06FL0yfhf0VR5Xism6pIcem2tzLEMHOju57sUXcU3S7VYKI5tL1kHOWsjJpEdpv7GkeSu2YnRTXrX-IxlFNkp0D1Iy4S7gVL73ahODo0n0oXpI'
    ], 'questo', x, 'prova');
    //Navigator.pushNamed(context, '/acceptance'); //non va perchè poi carica altre pagine
  },
);

//FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//      print('A new onMessageOpenedApp event was published!');
//      Navigator.pushNamed(
//        context,
//        '/acceptance');
//    });


    //FirebaseMessaging.instance.getInitialMessage().then(
    //      (value) => setState(
    //        () {
    //          RemoteMessage? initialMessage = value;
    //          String x;
    //          if (initialMessage == null || initialMessage == '') {
    //            x = 'null';
    //          } 
    //          else {
    //            x = 'yesss';
    //          }
    //          Navigator.pushNamed(context, '/acceptance');
    //          sendNotification([
    //            'f1QP4F2hQ4G8c21NnliqST:APA91bHb5beI32WGr-Olb95hDitqSy06FL0yfhf0VR5Xism6pIcem2tzLEMHOju57sUXcU3S7VYKI5tL1kHOWsjJpEdpv7GkeSu2YnRTXrX-IxlFNkp0D1Iy4S7gVL73ahODo0n0oXpI'
    //          ], 'questo', x, 'prova');
    //        },
    //      ),
    //    );

    //setupInteractedMessage(); //forse non ci manda ad acceptance perchè ci sono le funzioni async
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: loadData(), // Chiamare loadData() direttamente qui
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
                child: Text("Errore durante il recupero dei dati."),
              ),
            );
          } else {
            String email = snapshot.data ?? '';
            if (email == '') {
              //return const ClubPage(title: "Tiber Club", document: {
              //  'name': 'fra',
              //  'surname': 'marti',
              //  'email': 'framarti@gmail.com',
              //  'role': 'Boy',
              //  'club_class': '2° liceo',
              //  'soccer_class': 'intermediate',
              //  'status': 'Admin',
              //  'birthdate': 2024 - 01 - 16,
              //  'id': 'wJu0WDEgg75gYg91Ejl8'
              //});
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
                    } else {
                      Map<String, dynamic> document = snapshot.data ?? {};
                      Future.delayed(Duration.zero, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ClubPage(
                                    title: "Tiber Club", document: document)));
                      });
                      return Container();
                    }
                  });
            }
          }
        });
  }
}
