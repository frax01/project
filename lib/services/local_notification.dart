import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static late RemoteMessage notificationMessage;

  static void initialize(void Function(RemoteMessage) handleMessageFromBackgroundAndForegroundState) {
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: AndroidInitializationSettings("@mipmap/ic_launcher"), iOS: DarwinInitializationSettings());

    _notificationsPlugin.initialize(settings: initializationSettings,
        onDidReceiveNotificationResponse: (payload) {
          handleMessageFromBackgroundAndForegroundState(notificationMessage);
    });
  }

  static void showNotificationOnForeground(RemoteMessage message) {
    notificationMessage = message;
    const notificationDetail = NotificationDetails(
        android: AndroidNotificationDetails(
            'default_notification_channel_id', 'My Channel Name',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher')));

    _notificationsPlugin.show(
      id: DateTime.now().microsecond,
      title: message.data["notTitle"],
      body: message.data["notBody"],
      notificationDetails: notificationDetail,
      payload: message.data["category"],
    );
  }
}
