import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'translations/app_translations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/orders_list_screen.dart';
import 'controllers/home_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/favorites_controller.dart';
import 'config/app_config.dart';

import 'dart:math';
import 'models/notification_item.dart';
import 'services/notification_storage.dart';
import 'services/notification_service.dart';

// Global FCM message notifier
final ValueNotifier<RemoteMessage?> fcmMessageNotifier = ValueNotifier(null);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.init();
  final title = message.notification?.title ?? 'New Notification';
  final body = message.notification?.body ?? '';
  final imageUrl = message.notification?.android?.imageUrl ??
      message.notification?.apple?.imageUrl ??
      message.data['image'];
  NotificationService.show(
    id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch.hashCode,
    title: title,
    body: body,
    imageUrl: imageUrl,
    payload: message.data['type'] ?? '',
  );
  NotificationStorage.save(NotificationItem(
    id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: title,
    body: body,
    imageUrl: imageUrl,
    timestamp: DateTime.now(),
  ));
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize local storage
    await GetStorage.init();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Supabase
    await Supabase.initialize(
      url: AppConfig.supabaseUrl.isNotEmpty
          ? AppConfig.supabaseUrl
          : const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
      anonKey: AppConfig.supabaseAnonKey.isNotEmpty
          ? AppConfig.supabaseAnonKey
          : const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
    );

    // Initialize notification service
    await NotificationService.init();

    // Register Controllers BEFORE running app
    Get.put(ThemeController());
    Get.put(AuthController());
    Get.put(HomeController());
    Get.put(CartController());
    Get.put(FavoritesController());

    // Setup Notifications
    await _setupFCM();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    runApp(const KiwiCustomerApp());
  } catch (e) {
    // Basic error view if initialization fails
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Error: $e')))));
  }
}

/// Generates a UUID v4-format string for guest device identification.
String _generateDeviceUuid() {
  final rng = Random();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 1
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
      '${hex(bytes[4])}${hex(bytes[5])}-'
      '${hex(bytes[6])}${hex(bytes[7])}-'
      '${hex(bytes[8])}${hex(bytes[9])}-'
      '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
}

Future<void> _setupFCM() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Register background message handler (fires for data + notification payloads)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get or generate a persistent device ID for guest tracking (UUID v4 format)
    final storage = GetStorage();
    String deviceId = storage.read<String>('device_id') ?? _generateDeviceUuid();
    await storage.write('device_id', deviceId);

    // Get and save token
    String? token = await messaging.getToken();
    if (token != null) {
      await _saveFcmToken(token, deviceId);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      await _saveFcmToken(newToken, deviceId);
    });

    // Handle foreground messages - save to inbox, show system notification + snackbar
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      fcmMessageNotifier.value = message;
      if (message.notification != null) {
        final title = message.notification?.title ?? 'new_notification'.tr;
        final body = message.notification?.body ?? '';
        final imageUrl = message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl ?? message.data['image'];
        // Save to local notification inbox
        NotificationStorage.save(NotificationItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          body: body,
          imageUrl: imageUrl,
          timestamp: DateTime.now(),
        ));
        // Show system notification with BigPictureStyle
        NotificationService.show(
          id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch.hashCode,
          title: title,
          body: body,
          imageUrl: imageUrl,
          payload: message.data['type'] ?? '',
        );
        // Show snackbar via GetX if app is running
        if (Get.key.currentContext != null) {
          Get.snackbar(
            title,
            body,
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppTheme.primary.withOpacity(0.95),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(12),
            borderRadius: 12,
          );
        }
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      fcmMessageNotifier.value = message;
      // Navigate to orders screen
      Get.to(() => const OrdersListScreen(), transition: Transition.fadeIn);
    });

    // Handle cold start from notification
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      fcmMessageNotifier.value = initialMessage;
    }
  } catch (e) {
    debugPrint('FCM setup error: $e');
  }
}

/// Saves FCM token to user_fcm_tokens table for ALL users (guests + logged in).
/// Also saves to profiles.fcm_token for logged-in users (backward compat).
Future<void> _saveFcmToken(String token, String deviceId) async {
  try {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    // Always save to user_fcm_tokens (works for guests and logged-in users)
    final tokenId = userId ?? deviceId;
    await supabase.from('user_fcm_tokens').upsert({
      'user_id': tokenId,
      'token': token,
      'device_type': 'android',
    }, onConflict: 'token');

    // Also save to profiles.fcm_token for logged-in users (backward compat)
    if (userId != null) {
      await supabase.from('profiles').update({'fcm_token': token}).eq('id', userId);
    }

    debugPrint('[FCM] Token saved for ${userId ?? 'guest($deviceId)'}');
  } catch (e) {
    debugPrint('[FCM] Error saving token: $e');
  }
}

class KiwiCustomerApp extends StatelessWidget {
  const KiwiCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Obx(() => GetMaterialApp(
      title: 'Kiwi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      translations: AppTranslations(),
      locale: _initialLocale(),
      fallbackLocale: const Locale('en', 'US'),
      home: const SplashScreen(),
    ));
  }
}

Locale _initialLocale() {
  final savedLang = GetStorage().read<String>('app_locale');
  if (savedLang == 'en') return const Locale('en', 'US');
  return const Locale('ar', 'IQ');
}
