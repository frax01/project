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
import 'firebase_options.dart';
import 'functions/dataFunctions.dart';
import 'functions/generalFunctions.dart';
import 'pages/main/acceptance.dart';
import 'pages/main/login.dart';
import 'pages/main/waiting.dart';
import 'services/local_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/pages/club/eventPage.dart';
import 'package:club/pages/club/programCard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String club = prefs.getString('club') ?? '';

  runApp(MyApp(
    club: club,
    ));
}

@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {}

class MyApp extends StatelessWidget {
   MyApp({
    super.key,
    required this.club,
    });

  final String club;
  Widget startWidget = Container();

  Future<void> fetchPage() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
  String club = prefs.getString('club') ?? '';

  if (prefs.getString('email') != null &&
      prefs.getString('email')!.isNotEmpty) {
    QueryDocumentSnapshot value =
        await data('user', 'email', prefs.getString('email'));

    String name = value['name'];
    String surname = value['surname'];
    String email = value['email'];
    List classes = value['club_class'];
    bool status = value['status'] == 'Admin' ? true : false;
    String role = value['role'];
    String id = value.id;

    startWidget =
      ClubPage(
      classes: classes,
      club: club,
      status: status,
      id: id,
      name: name,
      surname: surname,
      email: email,
      role: role,
    );
  } else {
    startWidget = const Login();
  }
  
  }

  //@override
  void initState() {
    fetchPage();
  }

  @override
  Widget build(BuildContext context) {
    var lightTheme;
    var darkTheme;

    switch (club) {
      case 'Tiber Club':
        lightTheme = lightColorSchemeTiber;
        darkTheme = darkColorSchemeTiber;
        break;
      case 'Delta Club':
        lightTheme = lightColorSchemeDelta;
        darkTheme = darkColorSchemeDelta;
        break;
      default:
        lightTheme = lightColorSchemeTiber;
        darkTheme = darkColorSchemeTiber;
        break;
    }

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
      locale: const Locale('it', 'IT'),
      title: 'Club',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      home: startWidget,
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomePage(club: club),
        '/login': (context) => const Login(),
        '/signup': (context) => const SignUp(),
        '/waiting': (context) => const Waiting(),
        '/acceptance': (context) => AcceptancePage(club: club),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.club});

  final String club;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool terminated = false;

  String name = '';
  String surname = '';
  String email = '';
  List classes = [];
  bool status = false;
  String id = '';
  String club = '';
  String role = '';
  List token = [];

  final _listItems = <ProgramCard>[];
  refreshList() {
    setState(() {
      _listItems.clear();
    });
  }

  RemoteMessage? initialMessage;

  Widget buildClubPage(String club, int selectedIndex) {
    return ClubPage(
        club: club,
        classes: classes,
        status: status,
        id: id,
        name: name,
        surname: surname,
        email: email,
        selectedIndex: selectedIndex,
        role: role);
  }

  Future<void> retrieveData() async {
    QueryDocumentSnapshot value = await data('user', 'email', email);

    name = value['name'];
    surname = value['surname'];
    email = value['email'];
    classes = value['club_class'];
    status = value['status'] == 'Admin' ? true : false;
    token = value['token'];
    role = value['role'];
    id = value.id;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    club = prefs.getString('club') ?? '';

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? getToken = await messaging.getToken();
    print("token: $getToken");

    List tokenList = [getToken];

    if (token.isEmpty) {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(id)
          .update({'token': tokenList});
    } else if (token.isNotEmpty && !token.contains(getToken)) {
      token.add(getToken);
      await FirebaseFirestore.instance
          .collection('user')
          .doc(id)
          .update({'token': token});
    }
  }

  Future<void> setupInteractedMessage() async {
    LocalNotificationService.initialize(
        handleMessageFromBackgroundAndForegroundState);

    //terminated
    initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      setState(() {
        terminated = true;
      });
    }

    //background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleMessageFromBackgroundAndForegroundState(message);
    });

    //foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LocalNotificationService.showNotificationOnForeground(message);
    });
  }

  void handleMessageFromBackgroundAndForegroundState(
      RemoteMessage message) async {
    if (message.data['category'] == 'new_user') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AcceptancePage(club: widget.club)));
    } else if (message.data['category'] == 'accepted') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const Login()));
    } else if (message.data['category'] == 'new_event') {
      await retrieveData();
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProgramPage(
                  club: club,
                  documentId: message.data["docId"],
                  selectedOption: message.data["selectedOption"],
                  isAdmin: status,
                  name: '$name $surname',
                  role: message.data['role'],
                  classes: classes)));
    } else if (message.data['category'] == 'modified_event') {
      await retrieveData();
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProgramPage(
                  club: club,
                  documentId: message.data["docId"],
                  selectedOption: message.data["selectedOption"],
                  isAdmin: status,
                  name: '$name $surname',
                  role: message.data['role'],
                  classes: classes)));
    } else if (message.data['category'] == 'birthday') {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => buildClubPage(club, 1)));
    } else if (message.data['category'] == 'evento') {
      DateTime focusedDay;
      focusedDay = DateTime.parse(message.data['focusedDay']);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EventPage(
                  club: club,
                  documentId: message.data['docId'],
                  isAdmin: status,
                  name: name,
                  selectedDay: focusedDay,
                  role: role,
                  classes: classes,)));
    }
  }

  Widget handleMessageFromTerminatedState() {
    if (initialMessage?.data['category'] == 'new_user') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AcceptancePage(club: widget.club)));
    } else if (initialMessage?.data['category'] == 'accepted') {
      return const Login();
    } else if (initialMessage?.data['category'] == 'new_event' ||
        initialMessage?.data['category'] == 'modified_event') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProgramPage(
                  club: club,
                  documentId: initialMessage?.data["docId"],
                  selectedOption: initialMessage?.data["selectedOption"],
                  isAdmin: status,
                  name: '$name $surname',
                  role: initialMessage?.data['role'],
                  classes: classes)));
    } else if (initialMessage?.data['category'] == 'modified_event') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProgramPage(
                  club: club,
                  documentId: initialMessage?.data["docId"],
                  selectedOption: initialMessage?.data["selectedOption"],
                  isAdmin: status,
                  name: '$name $surname',
                  role: initialMessage?.data['role'],
                  classes: classes)));
    } else if (initialMessage?.data['category'] == 'birthday') {
      return buildClubPage(club, 1);
    } else if (initialMessage?.data['category'] == 'evento') {
      DateTime focusedDay;
      focusedDay = DateTime.parse(initialMessage?.data['focusedDay']);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EventPage(
                  club: club,
                  documentId: initialMessage?.data['docId'],
                  isAdmin: status,
                  name: name,
                  selectedDay: focusedDay,
                  role: role,
                  classes: classes,)));
      return buildClubPage(club, 1);
    }
    return buildClubPage(club, 0);
  }

  @override
  void initState() {
    super.initState();
    setupInteractedMessage();
    retrieveData();
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
                  Image.asset('images/clubLogo.png', height: 300.0),
                  const SizedBox(height: 20.0),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          Future.microtask(() => Navigator.pop(context));
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          email = snapshot.data ?? '';
          if (email == '') {
            return const Login();
          } else {
            return FutureBuilder<void>(
              future: retrieveData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Image.asset('images/clubLogo.png', height: 300.0),
                            const SizedBox(height: 20.0),
                            const CircularProgressIndicator(),
                          ]),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text(
                              'Si è verificato un errore nel recupero dei dati'),
                          const SizedBox(height: 20.0),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Login()),
                              );
                            },
                            child: const Text('Torna al Login'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (terminated == false) {
                  return buildClubPage(club, 0);
                } else {
                  return handleMessageFromTerminatedState();
                }
              },
            );
          }
        }
      },
    );
  }
}
