import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:club/config.dart';
import 'package:http/http.dart' as http;

Future<void> sendNotification(
    List fcmToken, String notTitle, String message, String category,
    {String? docId, String? selectedOption, String? role}) async {
  //const String serverKey = Config.serverKey;
  const String fcmUrl =
      'https://fcm.googleapis.com/v1/projects/club-60d94/messages:send';
  Uri uri = Uri.parse(fcmUrl);

  for (String token in fcmToken) {
    final Map<String, dynamic> data = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'docId': docId ?? '',
      'selectedOption': selectedOption ?? '',
      'status': 'done',
      'category': category,
      'notTitle': notTitle,
      'notBody': message,
      'role': role,
    };

    final Map<String, dynamic> notification = {
      'title': notTitle,
      'body': message
    };

    final Map<String, dynamic> body = {
      'message': {
        'token': token,
        'notification': notification,
        'data': data,
      }
    };

    final String accessToken = await _generateAccessToken();

    final http.Response response = await http.post(
      uri,
      body: jsonEncode(body),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    if (response.statusCode == 200) {
      print('Notifica inviata con successo!');
    } else {
      print('Errore nell\'invio della notifica: ${response.reasonPhrase}');
    }
  }
}

Future<String> _generateAccessToken() async {
  final response = await http.post(
    Uri.parse(
        'https://us-central1-club-60d94.cloudfunctions.net/generateAccessToken'),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> responseBody = jsonDecode(response.body);
    return responseBody['accessToken'];
  } else {
    throw Exception('Failed to generate access token');
  }
}

Future<List<String>> fetchToken(
    String section, String target, String club) async {
  List<String> tokens = [];
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('club', isEqualTo: club)
        .where(section, arrayContains: target)
        .get();
    for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
      for (var value in documentSnapshot['token']) {
        if (value is String) {
          if (!tokens.contains(value)) {
            tokens.add(value);
          }
        } else if (value is Map) {
          String tokenValue = value.values.first;
          if (!tokens.contains(tokenValue)) {
            tokens.add(tokenValue);
          }
        }
      }
    }
    return tokens;
  } catch (e) {
    print(
        'Errore durante l\'accesso a Firestore per il recupero dei token: $e');
    return [];
  }
}

Future<List<String>> retrieveToken(
    String section, String target, String club) async {
  List<String> tokens = [];
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('club', isEqualTo: club)
        .where(section, isEqualTo: target)
        .get();
    for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
      for (var value in documentSnapshot['token']) {
        if (value is String) {
          if (!tokens.contains(value)) {
            tokens.add(value);
          }
        } else if (value is Map) {
          String tokenValue = value.values.first;
          if (!tokens.contains(tokenValue)) {
            tokens.add(tokenValue);
          }
        }
      }
    }
    return tokens;
  } catch (e) {
    print(
        'Errore durante l\'accesso a Firestore per il recupero dei token: $e');
    return [];
  }
}
