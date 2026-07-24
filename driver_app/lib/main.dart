import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'config/app_config.dart';
import 'screens/auth/driver_login_screen.dart';
import 'screens/driver_main_screen.dart';
import 'screens/approval_waiting_screen.dart';

/// Global notifier: when set to true, DriverMainScreen switches to orders tab and refreshes.
final ValueNotifier<bool> fcmNavigateToOrders = ValueNotifier<bool>(false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    Future<void> saveToken(String token) async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', user.id);
      }
    }

    final fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      await saveToken(fcmToken);
    }

    messaging.onTokenRefresh.listen((token) async {
      await saveToken(token);
    });

    // Foreground: show snackbar and trigger refresh
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      fcmNavigateToOrders.value = true;
      Get.snackbar(
        message.notification?.title ?? 'إشعار جديد',
        message.notification?.body ?? '',
        backgroundColor: const Color(0xFF10b981),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    });

    // Background tap: navigate to orders tab
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      fcmNavigateToOrders.value = true;
    });

    // Cold start from notification
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      fcmNavigateToOrders.value = true;
    }
  } catch (e) {
    debugPrint('FCM init error: $e');
  }

  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    return GetMaterialApp(
      title: 'Fresh Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF10b981),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF10b981)),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: session == null ? const DriverLoginScreen() : const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? isApproved;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkApprovalStatus();
  }

  Future<void> _checkApprovalStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('is_approved')
            .eq('id', user.id)
            .maybeSingle();
        
        setState(() {
          isApproved = response?['is_approved'] ?? false;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking approval status: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (isApproved == true) {
      return const DriverMainScreen();
    } else {
      return const ApprovalWaitingScreen();
    }
  }
}
