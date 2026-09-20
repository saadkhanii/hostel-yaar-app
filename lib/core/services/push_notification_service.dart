import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_client.dart';

/// Handles FCM: permission request, token retrieval, token sync with the
/// backend, and receiving foreground/background messages.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'hostel_yaar_default',
    'Hostel Yaar',
    description: 'Booking updates and messages from Hostel Yaar',
    importance: Importance.high,
  );

  /// Called after Firebase.initializeApp() and after the user is logged in.
  Future<void> initialize() async {
    await _requestPermission();
    await _setupLocalNotifications();
    await _setupMessageHandlers();
    await _syncTokenToBackend();

    _messaging.onTokenRefresh.listen((newToken) async {
      await _sendTokenToBackend(newToken);
    });
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission status: ${settings.authorizationStatus}');
  }

  Future<void> _setupLocalNotifications() async {
    if (!Platform.isAndroid) return;

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    // v19+ requires a named `settings:` argument.
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        // TODO: navigate based on payload if needed
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM opened: ${message.data}');
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('FCM launched from notification: ${initial.data}');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // v19+ uses `id:` and `settings:` named arguments.
    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> _syncTokenToBackend() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final dio = ApiClient().dio;
      await dio.patch('/auth/me/fcm-token', data: {'fcm_token': token});
      debugPrint('FCM token sent to backend');
    } catch (e) {
      debugPrint('Failed to send FCM token: $e');
    }
  }
}