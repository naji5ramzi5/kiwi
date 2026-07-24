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

// Global FCM message notifier
final ValueNotifier<RemoteMessage?> fcmMessageNotifier = ValueNotifier(null);

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

Future<void> _setupFCM() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Get and save token
    String? token = await messaging.getToken();
    if (token != null) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('profiles').update({'fcm_token': token}).eq('id', userId);
      }
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('profiles').update({'fcm_token': newToken}).eq('id', userId);
      }
    });

    // Handle foreground messages - show snackbar
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      fcmMessageNotifier.value = message;
      if (message.notification != null) {
        final title = message.notification?.title ?? 'new_notification'.tr;
        final body = message.notification?.body ?? '';
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
