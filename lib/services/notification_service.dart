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
    tz.initializeTimeZones();

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
  }

  Future<void> requestPermissions() async {
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> scheduleMonthly28thReminder() async {
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
  }

  tz.TZDateTime _nextInstanceOf28thAt9AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, 28, 9, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(tz.local, now.year, now.month + 1, 28, 9, 0);
    }
    return scheduledDate;
  }

  Future<void> cancelReminder() async {
    await _flutterLocalNotificationsPlugin.cancel(101);
  }

  Future<void> showTestNotification() async {
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
  }
}
