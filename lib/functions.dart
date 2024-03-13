import 'package:club/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendNotification(List fcmToken, String title, String message, String category) async {
    const String serverKey = Config.serverKey;
    const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';
    Uri uri = Uri.parse(fcmUrl);

    for (String token in fcmToken) {
      final Map<String, dynamic> notification = {
        'title': title,
        'body': message,
      };

      final Map<String, dynamic> data = {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'status': 'done',
      };

      final Map<String, dynamic> body = {
        'to': token,
        'notification': notification,
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

  Future<List<dynamic>> getSuggestions(String query) async {
    const String apiUrl = Config.locationIqUrl;
    const String locationiqKey = Config.locationIqKey;

    final response = await http.get(
      Uri.parse('$apiUrl?q=$query&key=$locationiqKey&format=json&limit=5'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load suggestions');
    }
  }