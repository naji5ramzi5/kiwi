import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'config/app_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/ops_main_screen.dart';
import 'screens/access_denied_screen.dart';
import 'models/notification_item.dart';
import 'services/notification_storage.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';

/// Global notifier: when set, the main screen refreshes data.
final ValueNotifier<bool> opsRefreshSignal = ValueNotifier<bool>(false);

/// يكتمل بمجرد جاهزية Supabase (سريع، بلا شبكة) — الواجهة تنتظره فقط
final Future<void> opsSupabaseReady = _initSupabase();

Future<void> _initSupabase() async {
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    debugPrint('Supabase initialized');
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }
}

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
  if (message.notification == null) {
    NotificationService.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch.hashCode,
      title: data['title'],
      body: data['body'],
      imageUrl: data['imageUrl'],
      payload: message.data['type'] ?? '',
    );
  }
  await NotificationStorage.save(NotificationItem(
    id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: data['title'],
    body: data['body'],
    imageUrl: data['imageUrl'],
    timestamp: DateTime.now(),
  ));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // الواجهة تظهر فوراً — التهيئة الكاملة تتم خلف الكواليس بلا تجميد
  runApp(const OpsApp());
  unawaited(_initBackground());
}

Future<void> _initBackground() async {
  // 1) انتظار جاهزية Supabase (سريع)
  try {
    await opsSupabaseReady;
  } catch (_) {}

  // 2) Firebase + إشعارات — غير حرجة إطلاقاً
  var firebaseOk = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseOk = true;
    debugPrint('Firebase initialized');
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  try {
    await NotificationService.init();
    debugPrint('NotificationService initialized');
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }

  if (firebaseOk) {
    try {
      await _setupPushNotifications();
    } catch (e) {
      debugPrint('FCM setup error: $e');
    }
  }
}

Future<void> _setupPushNotifications() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  Future<void> saveToken(String token) async {
    await AuthService.saveFcmToken(token);
  }

  final fcmToken = await messaging.getToken();
  if (fcmToken != null) await saveToken(fcmToken);

  messaging.onTokenRefresh.listen((token) async {
    await saveToken(token);
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    opsRefreshSignal.value = true;
    final notifData = _extractNotificationData(message);
    final title = notifData['title'].toString().isNotEmpty
        ? notifData['title']
        : 'إشعار جديد';
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
      id: message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.hashCode,
      title: title,
      body: body,
      imageUrl: imageUrl,
      payload: message.data['type'] ?? '',
    );
    Get.snackbar(
      title,
      body,
      backgroundColor: const Color(0xFF1E293B),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    opsRefreshSignal.value = true;
  });

  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    opsRefreshSignal.value = true;
  }
}

class OpsApp extends StatelessWidget {
  const OpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kiwi Operations',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E293B),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
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

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  StreamSubscription<dynamic>? _authSub;

  @override
  void initState() {
    super.initState();
    opsSupabaseReady.then((_) {
      if (!mounted) return;
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: opsSupabaseReady,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return const LoginScreen();
        return FutureBuilder<AuthState?>(
          future: AuthService.fetchAuthState(),
          builder: (context, s2) {
            if (s2.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final auth = s2.data;
            if (auth == null || !auth.role.canAccessOperations) {
              return const AccessDeniedScreen();
            }
            return OpsMainScreen(auth: auth);
          },
        );
      },
    );
  }
}