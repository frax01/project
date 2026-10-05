import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize(
      void Function(RemoteMessage) handleMessageFromBackgroundAndForegroundState) {
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: AndroidInitializationSettings("@mipmap/ic_launcher"),
            iOS: DarwinInitializationSettings());

    _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // The message is rebuilt from the payload of the tapped
          // notification. It used to be a static "last message" variable, so
          // an older notification opened the newest message, and tapping one
          // before any foreground message was received threw
          // LateInitializationError.
          final Map<String, dynamic>? data = decodePayload(response.payload);
          if (data == null) return;
          handleMessageFromBackgroundAndForegroundState(
              RemoteMessage(data: data));
        });
  }

  /// The whole `data` map of the remote message, as the notification payload.
  static String encodePayload(Map<String, dynamic> data) => jsonEncode(data);

  static Map<String, dynamic>? decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(payload);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  static void showNotificationOnForeground(RemoteMessage message) {
    const notificationDetail = NotificationDetails(
        android: AndroidNotificationDetails(
            'default_notification_channel_id', 'My Channel Name',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher')));

    _notificationsPlugin.show(
      // DateTime.now().microsecond is only 0-999 and collided; seconds since
      // the epoch fit in the 32-bit id the platforms require.
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.data["notTitle"],
      body: message.data["notBody"],
      notificationDetails: notificationDetail,
      payload: encodePayload(message.data),
    );
  }
}
