import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:club/config.dart';
import 'package:http/http.dart' as http;
import 'tokenFunctions.dart';

Future<void> sendNotification(
    List fcmToken, String notTitle, String message, String category,
    {String? docId, String? selectedOption, String? role}) async {
  //const String serverKey = Config.serverKey;
  const String fcmUrl =
      'https://fcm.googleapis.com/v1/projects/club-60d94/messages:send';
  Uri uri = Uri.parse(fcmUrl);

  if (fcmToken.isEmpty) return;
  // One access token for the whole batch (it used to be requested per token).
  final String accessToken = await _generateAccessToken();

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
  return _collectTokens(FirebaseFirestore.instance
      .collection('user')
      .where('club', isEqualTo: club)
      .where(section, arrayContains: target)
      .get());
}

Future<List<String>> retrieveToken(
    String section, String target, String club) async {
  return _collectTokens(FirebaseFirestore.instance
      .collection('user')
      .where('club', isEqualTo: club)
      .where(section, isEqualTo: target)
      .get());
}

/// Tokens of all the users in [query]. A user with a missing or null token no
/// longer makes the whole lookup fail (it used to return [] for everybody).
Future<List<String>> _collectTokens(Future<QuerySnapshot> query) async {
  final List<String> tokens = [];
  try {
    final QuerySnapshot querySnapshot = await query;
    for (final QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
      final data = documentSnapshot.data() as Map<String, dynamic>;
      for (final String token in tokensFromField(data['token'])) {
        if (!tokens.contains(token)) tokens.add(token);
      }
    }
  } catch (e) {
    print(
        'Errore durante l\'accesso a Firestore per il recupero dei token: $e');
  }
  return tokens;
}
