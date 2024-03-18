import 'package:club/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> sendNotification(List fcmToken, String notTitle, String message,
    String category, Map? document, Map? weather) async {
  const String serverKey = Config.serverKey;
  const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';
  Uri uri = Uri.parse(fcmUrl);

  for (String token in fcmToken) {
    //final Map<String, dynamic> notification = {
    //  //'title': title,
    //  //'body': message,
    //};

    final Map<String, dynamic> data = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'status': 'done',
      'category': category,
      'notTitle': notTitle,
      'notBody': message,
      'title': document?["title"],
      'imagePath': document?["imagePath"],
      'selectedClass': document?["selectedClass"],
      'selectedOption': document?["selectedOption"],
      'description': document?["description"],
      'startDate': document?["startDate"],
      'endDate': document?["endDate"],
      'address': document?["address"],
      't_min': weather?["t_min"],
      't_max': weather?["t_max"],
      'w_code': weather?["w_code"],
      'image': weather?["image"],
      'check': weather?['check'],
    };

    final Map<String, dynamic> body = {
      'to': token,
      //'notification': notification,
      'data': data,
    };

    final http.Response response = await http.post(
      uri,
      body: jsonEncode(body),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
    );

    if (response.statusCode == 200) {
      print('Notifica inviata con successo!');
    } else {
      print('Errore nell\'invio della notifica: ${response.reasonPhrase}');
    }
  }
}

Future<List<String>> fetchToken(String section, String target) async {
  List<String> tokens = [];
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where(section, isEqualTo: target)
        .get();
    for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
      String token = documentSnapshot['token'];
      tokens.add(token);
    }
    return tokens;
  } catch (e) {
    print('Errore durante l\'accesso a Firestore: $e');
    return [];
  }
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
    //icon: '@mipmap/logo',
    //largeIcon: DrawableResourceAndroidBitmap('@mipmap/logo')
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidNotificationDetails);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.show(
    0,
    remoteMessage.data["notTitle"],
    remoteMessage.data["notBody"],
    platformChannelSpecifics,
    payload: 'Default_Sound',
  );
}
