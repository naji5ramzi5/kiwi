import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_layout.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Supabase only
    await Supabase.initialize(
      url: 'https://pftjlvtdzokbzuioqfug.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM',
    );
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  // Initialize Desktop Window Manager
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(900, 700),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.white,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Kiwi Fresh',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Init local DB to prevent future lag
  try {
    await DatabaseService().database;
  } catch (e) {
    debugPrint('DB Init error: $e');
  }

  runApp(const FreshPOSApp());
}

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
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
      home: Obx(() {
        if (!Get.isRegistered<AuthController>()) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final authController = Get.find<AuthController>();
        return authController.isLoggedIn.value 
          ? const MainLayout() 
          : const LoginScreen();
      }),
    );
  }
}
