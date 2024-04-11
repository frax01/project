import 'dart:convert';

import 'package:club/config.dart';
import 'package:http/http.dart' as http;

Future<List<dynamic>> getSuggestions(String query) async {
  const String apiUrl = Config.locationIqUrl;
  const String locationiqKey = Config.locationIqKey;

  final response = await http.get(
    Uri.parse(
        '$apiUrl/autocomplete?q=$query&key=$locationiqKey&format=json&limit=5'),
  );
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data;
  } else {
    throw Exception('Failed to load suggestions');
  }
}
