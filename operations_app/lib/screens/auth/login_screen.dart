import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../access_denied_screen.dart';
import '../ops_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  // حسابات النظام الأرضية: تُجرب كلمة السر عليها تباعاً
  static const List<String> _candidateAccounts = [
    'admin@kiwi.iq', // حساب المدير العام
    '07700000000@kiwi.internal', // مرادف الرقم للـ admin
  ];

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() {
        _error = 'يرجى إدخال كلمة المرور';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    AuthException? lastError;
    var signedIn = false;
    for (final email in _candidateAccounts) {
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        signedIn = true;
        break;
      } on AuthException catch (e) {
        lastError = e;
      }
    }

    if (!signedIn) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = lastError != null
              ? (lastError.message.contains('Invalid login cred')
                  ? 'كلمة المرور غير صحيحة'
                  : lastError.message)
              : 'فشل تسجيل الدخول';
        });
      }
      return;
    }

    try {
      final auth = await AuthService.fetchAuthState();
      if (!mounted) return;
      if (auth == null || !auth.role.canAccessOperations) {
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AccessDeniedScreen()),
        );
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OpsMainScreen(auth: auth)),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'خطأ في جلب بيانات الحساب: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10b981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10b981).withOpacity(.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, size: 46, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  'Kiwi Operations',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'نظام مراقبة عمليات التوصيل',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF94A3B8),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 34),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  style: GoogleFonts.cairo(color: Colors.white),
                  decoration: _dec('كلمة المرور', Icons.lock_outline),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F1D1D).withOpacity(.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDC2626).withOpacity(.4)),
                    ),
                    child: Text(
                      _error!,
                      style: GoogleFonts.cairo(color: Colors.redAccent.shade100, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10b981),
                      disabledBackgroundColor: const Color(0xFF10b981).withOpacity(.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'دخول',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'منظومة Kiwi — مدير النظام فقط',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF475569),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: const Color(0xFF64748B)),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}