import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

Future<Map<String, dynamic>> fetchWeatherData(
    startDate, endDate, lat, lon) async {
  Map<String, dynamic> weather = {};
  int weatherCode = 0;
  int temperatureMin = 0;
  int temperatureMax = 0;

  DateFormat inputFormat = DateFormat("dd-MM-yyyy");
  DateFormat outputFormat = DateFormat("yyyy-MM-dd");

  DateTime startInputDate = inputFormat.parse(startDate);
  String startOutputDate = outputFormat.format(startInputDate);

  DateTime today = DateTime.now();
  String todayOutputFormat = outputFormat.format(today);

  Duration startDifference = startInputDate.difference(today);
  int startDaysDifference = startDifference.inDays;

  if (startDaysDifference >= 16) {
    return {
      "t_min": '',
      "t_max": '',
      "w_code": '',
      "image": '',
      "check": false,
    };
  } else if (endDate != '' && (startInputDate.isBefore(today) || startInputDate == today)) {
    final response = await http.get(
      Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Europe%2FRome&start_date=$todayOutputFormat&end_date=$todayOutputFormat'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      weatherCode = data['daily']['weather_code'][0];
      temperatureMin = (data['daily']['temperature_2m_min'][0] < 0)
          ? data['daily']['temperature_2m_min'][0].ceil()
          : data['daily']['temperature_2m_min'][0].floor();
      temperatureMax = (data['daily']['temperature_2m_max'][0] < 0)
          ? data['daily']['temperature_2m_max'][0].ceil()
          : data['daily']['temperature_2m_max'][0].floor();
    } else {
      throw Exception('Failed to fetch weather data');
    }
    Reference ref =
        FirebaseStorage.instance.ref().child('Weather/$weatherCode.png');
    String weatherImageUrl = await ref.getDownloadURL();
    weather = {
      "t_min": temperatureMin,
      "t_max": temperatureMax,
      "w_code": weatherCode,
      "image": weatherImageUrl,
      "check": true,
    };
    return weather;
  } else if (endDate != '') {
    List tMin = [];
    List tMax = [];

    DateTime endInputDate = inputFormat.parse(endDate);
    Duration endDifference = endInputDate.difference(today);
    int endDaysDifference = endDifference.inDays;
    String endOutputDate = '';

    if (endDaysDifference >= 16) {
      DateTime endInputDate = today.add(const Duration(days: 15));
      endOutputDate = outputFormat.format(endInputDate);
    } else {
      DateTime endInputdDate = inputFormat.parse(endDate);
      endOutputDate = outputFormat.format(endInputdDate);
    }
    final response = await http.get(
      Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Europe%2FRome&start_date=$startOutputDate&end_date=$endOutputDate'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      tMin = data['daily']['temperature_2m_min'];
      tMax = data['daily']['temperature_2m_max'];

      double sum = 0;
      for (double value in tMin) {
        sum += value;
      }
      temperatureMin = ((sum / tMin.length) < 0)
          ? (sum / tMin.length).ceil()
          : (sum / tMin.length).floor();

      sum = 0;
      for (double value in tMax) {
        sum += value;
      }
      temperatureMax = ((sum / tMax.length) < 0)
          ? (sum / tMax.length).ceil()
          : (sum / tMax.length).floor();
    } else {
      throw Exception('Failed to fetch weather data');
    }
    weather = {
      "t_min": temperatureMin,
      "t_max": temperatureMax,
      "w_code": '',
      "image": '',
      "check": true,
    };
    return weather;
  } else {
    final response = await http.get(
      Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Europe%2FRome&start_date=$startOutputDate&end_date=$startOutputDate'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      weatherCode = data['daily']['weather_code'][0];
      temperatureMin = (data['daily']['temperature_2m_min'][0] < 0)
          ? data['daily']['temperature_2m_min'][0].ceil()
          : data['daily']['temperature_2m_min'][0].floor();
      temperatureMax = (data['daily']['temperature_2m_max'][0] < 0)
          ? data['daily']['temperature_2m_max'][0].ceil()
          : data['daily']['temperature_2m_max'][0].floor();
    } else {
      throw Exception('Failed to fetch weather data');
    }
    Reference ref =
        FirebaseStorage.instance.ref().child('Weather/$weatherCode.png');
    String weatherImageUrl = await ref.getDownloadURL();
    weather = {
      "t_min": temperatureMin,
      "t_max": temperatureMax,
      "w_code": weatherCode,
      "image": weatherImageUrl,
      "check": true,
    };
    return weather;
  }
}
