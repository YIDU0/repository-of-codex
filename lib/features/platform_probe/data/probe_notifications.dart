import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Developer-only probe; the daily reminder policy is implemented in phase 6.
class ProbeNotifications {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const notificationId = 9199901;

  Future<String> initialize() async {
    tz_data.initializeTimeZones();
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    return local.identifier;
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        ) ??
        false;
  }

  Future<void> schedule({Duration delay = const Duration(hours: 1)}) async {
    if (delay <= Duration.zero) throw ArgumentError.value(delay, 'delay');
    await _plugin.zonedSchedule(
      id: notificationId,
      title: '工时手账 · 平台验证',
      body: '这是一条开发版测试通知，不是每日工时提醒。',
      scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'platform_probe',
          '开发版平台验证',
          channelDescription: '用于验证本地通知的排程、送达与取消',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<bool> isPending() async =>
      (await _plugin.pendingNotificationRequests()).any(
        (notification) => notification.id == notificationId,
      );

  Future<void> cancel() => _plugin.cancel(id: notificationId);
}
