import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/app_constants.dart';
import '../database/app_database.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Track timestamps for cooldown mechanism
  final Map<String, DateTime> _lastAlertTimestamps = {};

  NotificationService._internal();

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Request permission for Android 13+ (API 33+)
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  /// Check cooldown before firing an alert
  bool _canTriggerAlert(String typeKey) {
    final lastTime = _lastAlertTimestamps[typeKey];
    if (lastTime == null) return true;

    final diffSeconds = DateTime.now().difference(lastTime).inSeconds;
    return diffSeconds >= AppConstants.notificationCooldownSeconds;
  }

  /// Record alert trigger time
  void _recordAlertTrigger(String typeKey) {
    _lastAlertTimestamps[typeKey] = DateTime.now();
  }

  /// Reset cooldown for a given type (e.g. when visitor is gone)
  void resetCooldown(String typeKey) {
    _lastAlertTimestamps.remove(typeKey);
  }

  /// Show local notification and persist to SQLite
  Future<void> triggerAlert({
    required String title,
    required String message,
    required String type,
    bool force = false,
  }) async {
    // Enforce cooldown unless forced
    if (!force && !_canTriggerAlert(type)) {
      return;
    }

    _recordAlertTrigger(type);

    // 1. Show device local notification
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'smarthome_alerts_channel',
        'Smart Home Alerts',
        channelDescription: 'Peringatan kondisi sensor dan perangkat Smart Home',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notificationsPlugin.show(
        id,
        title,
        message,
        platformDetails,
        payload: type,
      );
    } catch (e) {
      debugPrint('Local notification show error: $e');
    }

    // 2. Persist to SQLite
    try {
      final now = DateTime.now().toIso8601String();
      await AppDatabase.instance.insertNotification(
        NotificationModel(
          title: title,
          message: message,
          type: type,
          isRead: 0,
          createdAt: now,
        ),
      );
    } catch (e) {
      debugPrint('Error inserting notification to SQLite: $e');
    }
  }
}
