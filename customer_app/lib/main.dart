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
import 'controllers/home_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/theme_controller.dart';

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
      url: 'https://pftjlvtdzokbzuioqfug.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM',
    );

    // Register Controllers BEFORE running app
    Get.put(ThemeController());
    Get.put(AuthController());
    Get.put(HomeController());
    Get.put(CartController());

    // Setup Notifications
    _setupFCM();

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
    String? token = await messaging.getToken();
    if (token != null) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('profiles').update({'fcm_token': token}).eq('id', userId);
      }
    }
  } catch (_) {}
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
      locale: const Locale('ar', 'IQ'),
      fallbackLocale: const Locale('en', 'US'),
      home: const SplashScreen(),
    ));
  }
}

