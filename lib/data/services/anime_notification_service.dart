import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';
import 'dart:io';

class AnimeNotificationService {
  static final AnimeNotificationService _instance = AnimeNotificationService._internal();
  factory AnimeNotificationService() => _instance;
  AnimeNotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  final String prefsKey = 'scheduled_notifications';

  Future<void> init() async {
    debugPrint('Inicializando servicio de notificaciones');
    tz.initializeTimeZones();
    final local = tz.getLocation('Europe/Madrid'); // o la zona horaria que corresponda
    tz.setLocalLocation(local);

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'anime_notification',
          options: {
            DarwinNotificationCategoryOption.allowAnnouncement,
          },
        ),
      ],
    );

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) async {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    debugPrint('Servicio de notificaciones inicializado: $initialized');
  }

  Future<bool> requestPermissions() async {
    debugPrint('Solicitando permisos de notificaciones');
    if (Platform.isAndroid) {
      final androidImplementation = notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      debugPrint('Permisos Android: $granted');
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation = notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      final bool? granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Permisos iOS: $granted');
      return granted ?? false;
    }
    return false;
  }

  Future<void> scheduleAnimeNotification({
    required dynamic id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String animeId,
    String? imageUrl,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint('Fecha programada es anterior a la actual: $scheduledDate');
      return;
    }

    // Crear TZDateTime para ambas notificaciones
    final now = DateTime.now();
    final exactTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      scheduledDate.hour,
      scheduledDate.minute,
    );

    final reminderTime = exactTime.subtract(const Duration(minutes: 5));

    debugPrint('Programando notificaciones para ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}');
    debugPrint('Recordatorio: $reminderTime');
    debugPrint('Hora exacta: $exactTime');

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      interruptionLevel: InterruptionLevel.active,
      categoryIdentifier: 'anime_notification',
    );

    final androidDetails = AndroidNotificationDetails(
      'anime_schedule_channel',
      'Anime Schedule Notifications',
      channelDescription: 'Notifications for scheduled anime episodes',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: const DefaultStyleInformation(true, true),
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Programar notificación 5 minutos antes
      await notificationsPlugin.zonedSchedule(
        (id.hashCode * 2),  // ID único para la notificación de recordatorio
        "¡$title en 5 minutos!",
        "El nuevo episodio comenzará pronto",
        reminderTime,
        details,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: json.encode({
          'animeId': animeId,
          'episodeTime': scheduledDate.toIso8601String(),
          'imageUrl': imageUrl,
          'type': 'reminder'
        }),
      );

      // Programar notificación a la hora exacta
      await notificationsPlugin.zonedSchedule(
        (id.hashCode * 2) + 1,  // ID único para la notificación principal
        "¡$title ya está disponible!",
        "El nuevo episodio ha comenzado",
        exactTime,
        details,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: json.encode({
          'animeId': animeId,
          'episodeTime': scheduledDate.toIso8601String(),
          'imageUrl': imageUrl,
          'type': 'exact'
        }),
      );

      debugPrint('Notificaciones programadas exitosamente para $title');
      await _saveScheduledNotification({
        'id': id,
        'animeId': animeId,
        'title': title,
        'scheduledDate': scheduledDate.toIso8601String(),
        'imageUrl': imageUrl,
        'hasReminder': true
      });
    } catch (e) {
      debugPrint('Error al programar notificaciones: $e');
      rethrow;
    }
  }

  Future<void> _saveScheduledNotification(Map<String, dynamic> notification) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getScheduledNotifications();
    notifications.add(notification);
    await prefs.setString(prefsKey, json.encode(notifications));
  }

  Future<List<Map<String, dynamic>>> getScheduledNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString(prefsKey);
    if (notificationsJson == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(notificationsJson));
  }

  Future<void> cancelNotification(dynamic id) async {
    await notificationsPlugin.cancel(id.hashCode);
    final notifications = await getScheduledNotifications();
    notifications.removeWhere((notification) => notification['id'] == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, json.encode(notifications));
    debugPrint('Notificación cancelada: $id');
  }

  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
    debugPrint('Todas las notificaciones canceladas');
  }
}