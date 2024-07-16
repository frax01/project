import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static late RemoteMessage notificationMessage;

  static void initialize(void Function(RemoteMessage) handleMessage) {
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: AndroidInitializationSettings("@mipmap/ic_launcher"));
    _notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (payload) {
      handleMessage(notificationMessage);
    });
  }

  static void showNotificationOnForeground(RemoteMessage message) {
    notificationMessage = message;
    const notificationDetail = NotificationDetails(
        android: AndroidNotificationDetails(
            'default_notification_channel_id', 'My Channel Name',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_stat_t',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/logo')));

    _notificationsPlugin.show(
      DateTime.now().microsecond,
      message.data["notTitle"],
      message.data["notBody"],
      notificationDetail,
      payload: message.data["category"],
    );
  }
}
