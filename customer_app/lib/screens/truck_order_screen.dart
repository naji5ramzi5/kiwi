import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import '../controllers/auth_controller.dart';
import 'widgets/truck_order_header.dart';
import 'widgets/truck_order_form_field.dart';

class TruckOrderScreen extends StatefulWidget {
  const TruckOrderScreen({super.key});

  @override
  State<TruckOrderScreen> createState() => _TruckOrderScreenState();
}

class _TruckOrderScreenState extends State<TruckOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  final _supabase = Supabase.instance.client;
  final _authController = Get.find<AuthController>();

  String _generateOrderCode() {
    final now = DateTime.now();
    final rand = (10000 + (now.millisecondsSinceEpoch % 90000))
        .toString()
        .substring(0, 5);
    return 'TRK-$rand';
  }

  Future<bool> _canSubmitToday() async {
    final userId = _supabase.auth.currentUser!.id;
    final todayStart = DateTime.now().toUtc();
    final startOfDay = DateTime(
      todayStart.year,
      todayStart.month,
      todayStart.day,
    ).toUtc();

    final orders = await _supabase
        .from('truck_orders')
        .select('id')
        .eq('customer_id', userId)
        .gte('created_at', startOfDay.toIso8601String());

    return orders.length < 1;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    if (!_authController.isLoggedIn) {
      Get.snackbar(
        'login_required'.tr,
        'login_required_msg'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final canSubmit = await _canSubmitToday();
      if (!canSubmit) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        Get.snackbar(
          'daily_limit_exceeded'.tr,
          'daily_limit_msg'.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      final userId = _supabase.auth.currentUser!.id;
      final userName =
          _authController.userProfile['full_name']?.toString() ??
          'default_user_name'.tr;
      final orderCode = _generateOrderCode();
      final products = _productsController.text.trim();
      final phone = _phoneController.text.trim();
      final address = _addressController.text.trim();
      final notes = _notesController.text.trim();

      await _supabase.from('truck_orders').insert({
        'customer_id': userId,
        'order_code': orderCode,
        'products_text': products,
        'customer_name': userName,
        'customer_phone': phone,
        'delivery_address': address,
        'notes': notes,
        'status': 'new',
      });

      final message =
          '''
🚛 *${'truck_order_title'.tr}*
━━━━━━━━━━━━━━
📋 *${'shipping_details'.tr}:* $orderCode
👤 *${'default_user_name'.tr}:* $userName
📞 *${'contact_phone'.tr}:* $phone
📍 *${'delivery_address'.tr}:* $address
📦 *${'required_products'.tr}:* $products
📝 *${'additional_notes'.tr}:* ${notes.isEmpty ? 'none'.tr : notes}
━━━━━━━━━━━━━━
      '''
              .trim();

      await http.post(
        Uri.parse('https://api.telegram.org/bot${AppConfig.telegramBotToken}/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': AppConfig.telegramChatId,
          'text': message,
          'parse_mode': 'Markdown',
        }),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Get.back();

      Get.snackbar(
        'truck_order_success'.tr,
        'truck_order_success_msg'.trParams({'code': orderCode}),
        backgroundColor: AppTheme.emerald,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        icon: const Icon(LucideIcons.checkCircle, color: Colors.white),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Get.snackbar(
        'send_failed'.tr,
        'error_occurred'.trParams({'error': e.toString()}),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  void dispose() {
    _productsController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimary;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.background;
    final cardBgColor = isDark ? const Color(0xFF1E291F) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'truck_order_title'.tr,
          style: TextStyle(
            color: themeTextColor,
            fontWeight: FontWeight.w900,
            fontFamily: 'Cairo',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeTextColor),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TruckOrderHeader(
                  isDark: isDark,
                  themeTextColor: themeTextColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'shipping_details'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: themeTextColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.grey.shade100,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      TruckOrderFormField(
                        label:
                            'required_products'.tr,
                        hint:
                            'products_hint'.tr,
                        controller: _productsController,
                        icon: LucideIcons.shoppingBag,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'enter_required_products'.tr
                            : null,
                      ),
                      const SizedBox(height: 20),
                      TruckOrderFormField(
                        label: 'contact_phone'.tr,
                        hint: '07X XXXX XXXX',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        icon: LucideIcons.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'phone_required'.tr;
                          if (v.trim().length < 10)
                            return 'enter_valid_phone'.tr;
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TruckOrderFormField(
                        label: 'delivery_address'.tr,
                        hint:
                            'address_hint'.tr,
                        controller: _addressController,
                        icon: LucideIcons.mapPin,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'enter_delivery_address'.tr
                            : null,
                      ),
                      const SizedBox(height: 20),
                      TruckOrderFormField(
                        label: 'additional_notes'.tr,
                        hint: 'notes_hint'.tr,
                        controller: _notesController,
                        icon: LucideIcons.fileText,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryDark],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        height: 54,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.truck,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'send_truck_order'.tr,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
