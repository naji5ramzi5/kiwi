import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';
import 'controllers/auth_controller.dart';
import 'controllers/pos_orders_controller.dart';
import 'screens/splash_screen.dart';
import 'services/database_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1000, 700),
    minimumSize: Size(900, 650),
    maximumSize: Size(1920, 1080),
    center: true,
    backgroundColor: Colors.white,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
    title: 'Kiwi Fresh - نظام إدارة الفرع',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setAlignment(Alignment.center);
    await windowManager.setSize(const Size(1000, 700));
    await windowManager.show();
    await windowManager.focus();
  });

  // Initialize Supabase and DB in background (don't block UI)
  Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  ).catchError((e) => debugPrint('Supabase init error: $e'));

  DatabaseService().database.catchError((e) => debugPrint('Database init error: $e'));
  SyncService().startMonitoring();

  runApp(const FreshPOSApp());
}

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
    Get.put(POSOrdersController(), permanent: true);
  }
}

class FreshPOSApp extends StatelessWidget {
  const FreshPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kiwi Fresh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar'),
      fallbackLocale: const Locale('en'),
      initialBinding: AppBinding(),
      home: const SplashScreen(),
    );
  }
}


