import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class UsersSettingsPage extends StatefulWidget {
  const UsersSettingsPage({super.key});

  @override
  State<UsersSettingsPage> createState() => _UsersSettingsPageState();
}

class _UsersSettingsPageState extends State<UsersSettingsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _newUserRole = 'cashier';

  final List<Map<String, dynamic>> _users = [
    {'name': 'أحمد محمد', 'email': 'ahmed@kiwi.com', 'role': 'admin', 'active': true},
    {'name': 'سارة العلي', 'email': 'sara@kiwi.com', 'role': 'manager', 'active': true},
    {'name': 'محمد حسين', 'email': 'mohammed@kiwi.com', 'role': 'cashier', 'active': true},
    {'name': 'فاطمة أحمد', 'email': 'fatima@kiwi.com', 'role': 'cashier', 'active': false},
  ];

  final Map<String, bool> _permissions = {
    'manage_inventory': true,
    'process_orders': true,
    'view_reports': true,
    'manage_users': false,
    'manage_settings': false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCurrentUserCard(),
                    const SizedBox(height: 16),
                    _buildUserListCard(),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildAddUserCard()),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: _buildPermissionsCard()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(LucideIcons.users, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إدارة المستخدمين والصلاحيات',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryDarker),
            ),
            const SizedBox(height: 2),
            Text(
              'إدارة حسابات المستخدمين وصلاحيات الوصول',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildCurrentUserCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.userCircle, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'المستخدم الحالي',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              const Text(
                'أحمد محمد',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                'ahmed@kiwi.com',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'مدير النظام',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListCard() {
    return _buildSectionCard(
      title: 'قائمة المستخدمين',
      subtitle: '${_users.length} مستخدم مسجل',
      icon: LucideIcons.users,
      iconColor: AppTheme.secondary,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('الاسم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary))),
                Expanded(flex: 3, child: Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary))),
                Expanded(flex: 2, child: Text('الدور', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary))),
                Expanded(flex: 1, child: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary))),
                SizedBox(width: 48),
              ],
            ),
          ),
          ..._users.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            final roleColor = _getRoleColor(user['role']);
            final roleLabel = _getRoleLabel(user['role']);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: roleColor.withOpacity(0.1),
                          child: Text(
                            user['name'][0],
                            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(user['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                  Expanded(flex: 3, child: Text(user['email'], style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(roleLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: roleColor), textAlign: TextAlign.center),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: user['active'] ? AppTheme.success : AppTheme.textLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(LucideIcons.moreVertical, size: 16, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddUserCard() {
    return _buildSectionCard(
      title: 'إضافة مستخدم جديد',
      subtitle: 'إدخال بيانات المستخدم الجديد',
      icon: LucideIcons.userPlus,
      iconColor: AppTheme.info,
      child: Column(
        children: [
          _buildTextField('اسم المستخدم', _nameController, LucideIcons.user),
          const SizedBox(height: 12),
          _buildTextField('البريد الإلكتروني', _emailController, LucideIcons.mail, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildRoleDropdown(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.buttonShadow,
              ),
              child: ElevatedButton.icon(
                onPressed: _addUser,
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: const Text('إضافة مستخدم', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('دور المستخدم', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _newUserRole,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.shield, color: AppTheme.primary, size: 18),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'admin', child: Text('مدير النظام')),
            DropdownMenuItem(value: 'manager', child: Text('مدير')),
            DropdownMenuItem(value: 'cashier', child: Text('أمين صندوق')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _newUserRole = v);
          },
        ),
      ],
    );
  }

  Widget _buildPermissionsCard() {
    return _buildSectionCard(
      title: 'الصلاحيات',
      subtitle: 'تحديد صلاحيات الوصول',
      icon: LucideIcons.keyRound,
      iconColor: AppTheme.accent,
      child: Column(
        children: _permissions.entries.map((entry) {
          final labels = {
            'manage_inventory': 'إدارة المخزون',
            'process_orders': 'معالجة الطلبات',
            'view_reports': 'عرض التقارير',
            'manage_users': 'إدارة المستخدمين',
            'manage_settings': 'إدارة الإعدادات',
          };
          final icons = {
            'manage_inventory': LucideIcons.package,
            'process_orders': LucideIcons.shoppingCart,
            'view_reports': LucideIcons.barChart3,
            'manage_users': LucideIcons.users,
            'manage_settings': LucideIcons.settings,
          };
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icons[entry.key], size: 18, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(labels[entry.key]!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                Checkbox(
                  value: entry.value,
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (v) {
                    setState(() => _permissions[entry.key] = v ?? false);
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppTheme.error;
      case 'manager':
        return AppTheme.info;
      case 'cashier':
        return AppTheme.primary;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'مدير النظام';
      case 'manager':
        return 'مدير';
      case 'cashier':
        return 'أمين صندوق';
      default:
        return role;
    }
  }

  void _addUser() {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }
    setState(() {
      _users.add({
        'name': _nameController.text,
        'email': _emailController.text,
        'role': _newUserRole,
        'active': true,
      });
    });
    _nameController.clear();
    _emailController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تمت إضافة المستخدم بنجاح'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
