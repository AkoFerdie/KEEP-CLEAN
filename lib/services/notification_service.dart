import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (kIsWeb || _initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> showPatrolNotification({
    required String location,
    required String date,
    required String time,
  }) async {
    final title = '🚛 New Patrol Scheduled!';
    final body = '$location — $date at $time';

    if (kIsWeb) {
      try {
        js.context.callMethod('showPatrolNotification', [title, body]);
      } catch (_) {}
      return;
    }

    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'patrol_channel',
      'Patrol Schedules',
      channelDescription: 'Notifications for new patrol schedules',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}
