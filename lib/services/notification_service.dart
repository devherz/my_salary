import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<void> requestPermissions() async {
    try {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('requestPermissions error: $e');
    }
  }

  Future<void> scheduleMonthly28thReminder() async {
    try {
      await requestPermissions();

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'monthly_salary_reminder',
        'Rappel du 28 du mois',
        channelDescription: 'Rappel mensuel pour l\'épargne et la gestion du salaire',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      final tz.TZDateTime scheduledDate = _nextInstanceOf28thAt9AM();

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        101, // Notification ID
        '⏰ Rappel Épargne & Salaire GRIMM',
        'C\'est le 28 du mois ! N\'oubliez pas d\'alimenter vos objectifs d\'épargne et de vérifier vos comptes.',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (e) {
      debugPrint('scheduleMonthly28thReminder error: $e');
    }
  }

  tz.TZDateTime _nextInstanceOf28thAt9AM() {
    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(tz.local, now.year, now.month, 28, 9, 0);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = tz.TZDateTime(tz.local, now.year, now.month + 1, 28, 9, 0);
      }
      return scheduledDate;
    } catch (e) {
      final now = DateTime.now();
      var scheduled = DateTime(now.year, now.month, 28, 9, 0);
      if (scheduled.isBefore(now)) {
        scheduled = DateTime(now.year, now.month + 1, 28, 9, 0);
      }
      return tz.TZDateTime.from(scheduled, tz.UTC);
    }
  }

  Future<void> cancelReminder() async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(101);
    } catch (e) {
      debugPrint('cancelReminder error: $e');
    }
  }

  Future<void> showTestNotification() async {
    try {
      await requestPermissions();

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'monthly_salary_reminder',
        'Rappel du 28 du mois',
        channelDescription: 'Rappel mensuel pour l\'épargne et la gestion du salaire',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        999,
        '🔔 Test Rappel 28 du Mois (GRIMM)',
        'Le rappel mensuel du 28 à 09:00 est activé et fonctionnel !',
        details,
      );
    } catch (e) {
      debugPrint('showTestNotification error: $e');
    }
  }
}
