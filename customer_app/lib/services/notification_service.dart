import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'kiwi_notifications',
          'Kiwi Notifications',
          description: 'Kiwi app notifications',
          importance: Importance.high,
          playSound: true,
        ),
      );
    }

    _initialized = true;
  }

  static Future<String?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = Directory.systemTemp;
        final file = File(
          '${dir.path}/notification_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      debugPrint('Failed to download notification image: $e');
    }
    return null;
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? imageUrl,
    String? payload,
  }) async {
    String? localPath;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      localPath = await _downloadImage(imageUrl);
    }

    final androidDetails = localPath != null
        ? AndroidNotificationDetails(
            'kiwi_notifications',
            'Kiwi Notifications',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigPictureStyleInformation(
              FilePathAndroidBitmap(localPath),
              largeIcon: FilePathAndroidBitmap(localPath),
              contentTitle: title,
              summaryText: body,
            ),
          )
        : const AndroidNotificationDetails(
            'kiwi_notifications',
            'Kiwi Notifications',
            importance: Importance.high,
            priority: Priority.high,
          );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      payload: payload,
    );
  }
}
