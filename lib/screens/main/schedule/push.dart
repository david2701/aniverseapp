import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/services/anime_notification_service.dart';

class TestNotificationScreen extends StatefulWidget {
  const TestNotificationScreen({super.key});

  @override
  State<TestNotificationScreen> createState() => _TestNotificationScreenState();
}

class _TestNotificationScreenState extends State<TestNotificationScreen> {
  final AnimeNotificationService _notificationService = AnimeNotificationService();
  Timer? _timer;
  int _notificationId = 0;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      await _notificationService.init();
      final granted = await _notificationService.requestPermissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permisos de notificación: ${granted ? "Concedidos" : "Denegados"}')),
        );
      }
    } catch (e) {
      debugPrint('Error inicializando notificaciones: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _startTestNotifications() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _scheduleTestNotification();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificaciones de prueba iniciadas')),
      );
    }
  }

  void _stopTestNotifications() {
    _timer?.cancel();
    _timer = null;
    _notificationService.cancelAllNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificaciones de prueba detenidas')),
      );
    }
  }

  Future<void> _scheduleTestNotification() async {
    try {
      // Asegurar que la fecha sea futura
      final scheduledDate = DateTime.now().add(const Duration(seconds: 10));
      debugPrint('Programando notificación para: ${scheduledDate.toString()}');

      await _notificationService.scheduleAnimeNotification(
        id: _notificationId++,
        title: 'Prueba de Notificación',
        body: 'Notificación de prueba enviada a las ${TimeOfDay.now().format(context)}',
        scheduledDate: scheduledDate,
        animeId: 'test-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notificación programada para: ${scheduledDate.toString()}')),
        );
      }
    } catch (e) {
      debugPrint('Error al programar notificación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notificaciones'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startTestNotifications,
              child: const Text('Iniciar Notificaciones de Prueba'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _stopTestNotifications,
              child: const Text('Detener Notificaciones de Prueba'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scheduleTestNotification,
              child: const Text('Enviar Una Notificación'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initNotifications,
              child: const Text('Reiniciar Notificaciones'),
            ),
          ],
        ),
      ),
    );
  }
}