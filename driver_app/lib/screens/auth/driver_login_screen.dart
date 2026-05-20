import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  
  bool isRegistering = false;
  String vehicleType = 'bike'; // 'bike' or 'truck'
  bool isLoading = false;
  File? _avatarFile;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _avatarFile = File(pickedFile.path));
    }
  }

  Future<void> _handleAuth() async {
    if (isRegistering && (_nameController.text.isEmpty || _plateController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty)) {
      Get.snackbar('تنبيه', 'يرجى إكمال كافة البيانات المطلوبة', backgroundColor: Colors.orange.withOpacity(0.9), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20));
      return;
    }
    if (!isRegistering && (_emailController.text.isEmpty || _passwordController.text.isEmpty)) {
      Get.snackbar('تنبيه', 'يرجى إدخال البريد الإلكتروني وكلمة المرور', backgroundColor: Colors.orange.withOpacity(0.9), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20));
      return;
    }

    setState(() => isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      if (isRegistering) {
        final res = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {
            'full_name': _nameController.text.trim(),
            'role': 'driver',
            'vehicle_type': vehicleType,
            'plate_number': _plateController.text.trim(),
          },
        );
        
        if (res.user != null) {
          String? avatarUrl;
          
          if (_avatarFile != null) {
            final fileName = '${res.user!.id}/avatar.jpg';
            await supabase.storage.from('avatars').upload(fileName, _avatarFile!);
            avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
          }

          // Create profile entry
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': _nameController.text.trim(),
            'role': 'driver',
            'vehicle_type': vehicleType,
            'plate_number': _plateController.text.trim(),
            'avatar_url': avatarUrl,
            'is_approved': false,
            'is_online': false,
          });
          
          Get.snackbar('نجاح', 'تم إنشاء الحساب بنجاح، بانتظار موافقة الإدارة!', backgroundColor: const Color(0xFF10b981), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20));
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      Get.offAll(() => const DriverApp());
    } catch (e) {
      Get.snackbar('خطأ', 'البيانات غير صحيحة أو يوجد خلل في الاتصال', backgroundColor: Colors.red.withOpacity(0.9), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF), Color(0xFFE0F2F1)],
              ),
            ),
          ),
          
          // Decorative Abstract Shapes
          Positioned(top: -100, right: -50, child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF10b981).withOpacity(0.1))))),
          Positioned(bottom: -50, left: -50, child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF34D399).withOpacity(0.15))))),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / Header
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: const Color(0xFF10b981).withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 10))],
                          ),
                          child: const Icon(LucideIcons.truck, size: 50, color: Color(0xFF10b981)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isRegistering ? 'انضم لأسطولنا 🚀' : 'مرحباً بعودتك!',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1F2937), letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRegistering ? 'سجل كشريك توصيل وابدأ رحلتك معنا' : 'سجل دخولك لمتابعة استلام الطلبات',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 40),

                      // Glassmorphism Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.5)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))],
                            ),
                            child: Column(
                              children: [
                                if (isRegistering) ...[
                                  // Avatar Picker
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      height: 100, width: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        image: _avatarFile != null ? DecorationImage(image: FileImage(_avatarFile!), fit: BoxFit.cover) : null,
                                        border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3), width: 2),
                                        boxShadow: [BoxShadow(color: const Color(0xFF10b981).withOpacity(0.1), blurRadius: 15)],
                                      ),
                                      child: _avatarFile == null ? const Icon(LucideIcons.camera, size: 30, color: Color(0xFF10b981)) : null,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('الصورة الشخصية (اختياري)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 24),
                                  
                                  _buildTextField(_nameController, 'الاسم الكامل', LucideIcons.user),
                                  const SizedBox(height: 16),
                                  _buildTextField(_plateController, 'رقم اللوحة المرورية', LucideIcons.hash),
                                  const SizedBox(height: 24),
                                  
                                  const Align(alignment: Alignment.centerRight, child: Text('نوع المركبة:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937)))),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildVehicleOption('bike', 'دراجة نارية', LucideIcons.bike),
                                      const SizedBox(width: 12),
                                      _buildVehicleOption('truck', 'مركبة شحن', LucideIcons.truck),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                _buildTextField(_emailController, 'البريد الإلكتروني', LucideIcons.mail, keyboardType: TextInputType.emailAddress),
                                const SizedBox(height: 16),
                                _buildTextField(_passwordController, 'كلمة المرور', LucideIcons.lock, isPassword: true),
                                
                                const SizedBox(height: 32),
                                
                                // Submit Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _handleAuth,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10b981),
                                      foregroundColor: Colors.white,
                                      elevation: isLoading ? 0 : 8,
                                      shadowColor: const Color(0xFF10b981).withOpacity(0.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: isLoading 
                                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                      : Text(isRegistering ? 'تسجيل حساب جديد' : 'تسجيل الدخول', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Toggle Button
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isRegistering = !isRegistering;
                            _animationController.reset();
                            _animationController.forward();
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF10b981),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          isRegistering ? 'لديك حساب بالفعل؟ سجل دخولك الآن' : 'شريك جديد؟ انضم لأسطولنا',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF10b981), size: 22),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildVehicleOption(String type, String label, IconData icon) {
    final isSelected = vehicleType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => vehicleType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10b981).withOpacity(0.1) : Colors.white,
            border: Border.all(color: isSelected ? const Color(0xFF10b981) : Colors.transparent, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF10b981) : Colors.grey.shade400, size: 32),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF10b981) : Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
