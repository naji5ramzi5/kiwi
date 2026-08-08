import 'dart:async';
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
import 'models/notification_item.dart';
import 'services/notification_storage.dart';
import 'services/notification_service.dart';

/// Global notifier: when set to true, DriverMainScreen switches to orders tab and refreshes.
final ValueNotifier<bool> fcmNavigateToOrders = ValueNotifier<bool>(false);

/// Extracts title, body, and image from a RemoteMessage, supporting both
/// FCM notification payload and data-only payload interchangeably.
Map<String, dynamic> _extractNotificationData(RemoteMessage message) {
  if (message.notification != null) {
    return {
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'imageUrl': message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl ??
          message.data['image'] ?? '',
    };
  }
  return {
    'title': message.data['title'] ?? '',
    'body': message.data['body'] ?? '',
    'imageUrl': message.data['image'] ?? '',
  };
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.init();
  final data = _extractNotificationData(message);
  // Only show notification for data-only messages (no notification payload)
  // to avoid duplicates — FCM auto-displays notification payloads in the tray.
  if (message.notification == null) {
    NotificationService.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch.hashCode,
      title: data['title'],
      body: data['body'],
      imageUrl: data['imageUrl'],
      payload: message.data['type'] ?? '',
    );
  }
  NotificationStorage.save(NotificationItem(
    id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: data['title'],
    body: data['body'],
    imageUrl: data['imageUrl'],
    timestamp: DateTime.now(),
  ));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  await NotificationService.init();

  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

    // Foreground: save to local inbox + show system notification + snackbar + trigger refresh
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      fcmNavigateToOrders.value = true;
      final notifData = _extractNotificationData(message);
      final title = notifData['title'].toString().isNotEmpty ? notifData['title'] : 'إشعار جديد';
      final body = notifData['body'] ?? '';
      final imageUrl = notifData['imageUrl'] ?? '';
      NotificationStorage.save(NotificationItem(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
      ));
      NotificationService.show(
        id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch.hashCode,
        title: title,
        body: body,
        imageUrl: imageUrl,
        payload: message.data['type'] ?? '',
      );
      Get.snackbar(
        title,
        body,
        backgroundColor: const Color(0xFF10b981),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    });

    // Background tap: navigate to orders tab
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      fcmNavigateToOrders.value = true;
      final notifData = _extractNotificationData(message);
      await NotificationStorage.save(NotificationItem(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: notifData['title'],
        body: notifData['body'],
        imageUrl: notifData['imageUrl'],
        timestamp: DateTime.now(),
      ));
    });

    // Cold start from notification
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      fcmNavigateToOrders.value = true;
      final notifData = _extractNotificationData(initialMessage);
      await NotificationStorage.save(NotificationItem(
        id: initialMessage.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: notifData['title'],
        body: notifData['body'],
        imageUrl: notifData['imageUrl'],
        timestamp: DateTime.now(),
      ));
    }
  } catch (e) {
    debugPrint('FCM init error: $e');
  }

  // Global error handler to prevent black screen from runtime exceptions
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kiwi_Driver',
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
      home: const SessionGate(),
    );
  }
}

/// Listens to auth state changes so login/logout/session-refresh always
/// navigate correctly without a manual app restart.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const DriverLoginScreen();
    return const AuthWrapper();
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
