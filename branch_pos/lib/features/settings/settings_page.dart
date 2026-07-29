import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import 'general_settings_page.dart';
import 'thermal_printer_full_page.dart';
import 'barcode_printer_full_page.dart';
import 'backup_settings_page.dart';
import 'users_settings_page.dart';
import 'system_settings_page.dart';

enum SettingsSection {
  general,
  thermalPrinter,
  barcodePrinter,
  backup,
  users,
  system,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsSection _selectedSection = SettingsSection.general;
  final AuthController _authController = Get.find<AuthController>();

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: Text('هل أنت متأكد من تسجيل الخروج من فرع: ${_authController.currentBranchName.value}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _authController.logout();
            },
            child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  final List<_SidebarItem> _sidebarItems = [
    _SidebarItem(
      section: SettingsSection.general,
      title: 'الإعدادات العامة',
      icon: LucideIcons.settings,
    ),
    _SidebarItem(
      section: SettingsSection.thermalPrinter,
      title: 'إعدادات الطابعة الحرارية',
      icon: LucideIcons.printer,
    ),
    _SidebarItem(
      section: SettingsSection.barcodePrinter,
      title: 'إعدادات طابعة الباركود',
      icon: LucideIcons.qrCode,
    ),
    _SidebarItem(
      section: SettingsSection.backup,
      title: 'النسخ الاحتياطي',
      icon: LucideIcons.database,
    ),
    _SidebarItem(
      section: SettingsSection.users,
      title: 'المستخدمين والصلاحيات',
      icon: LucideIcons.users,
    ),
    _SidebarItem(
      section: SettingsSection.system,
      title: 'إعدادات النظام',
      icon: LucideIcons.monitor,
    ),
  ];

  Widget _buildContentArea() {
    switch (_selectedSection) {
      case SettingsSection.general:
        return const GeneralSettingsPage();
      case SettingsSection.thermalPrinter:
        return const ThermalPrinterFullPage();
      case SettingsSection.barcodePrinter:
        return const BarcodePrinterFullPage();
      case SettingsSection.backup:
        return const BackupSettingsPage();
      case SettingsSection.users:
        return const UsersSettingsPage();
      case SettingsSection.system:
        return const SystemSettingsPage();
    }
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryLighter,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              LucideIcons.construction,
              size: 48,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'هذه الصفحة قيد التطوير',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Row(
          children: [
            // Sidebar (LEFT side for RTL = right visual, but we keep it left in code)
            // In RTL, the first child in Row appears on the right visually
            // So we put content first, then sidebar to make sidebar appear on the left
            Expanded(
              child: _buildContentArea(),
            ),
            const SizedBox(width: 1),
            // Sidebar
            Container(
              width: 280,
              decoration: const BoxDecoration(
                gradient: AppTheme.sidebarGradient,
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.settings,
                            color: AppTheme.primaryLight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الإعدادات',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'لوحة التحكم',
                                style: const TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'فرع: ${_authController.currentBranchName.value}',
                                style: const TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Divider
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                  // Navigation items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _sidebarItems.length,
                      itemBuilder: (context, index) {
                        final item = _sidebarItems[index];
                        final isSelected = _selectedSection == item.section;
                        return _buildSidebarItem(item, isSelected);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Logout button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _logout,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.logOut, color: Colors.red, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'تسجيل الخروج',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                _authController.currentBranchName.value,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(_SidebarItem item, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedSection = item.section),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: isSelected ? AppTheme.primaryLight : Colors.grey[500],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
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

class _SidebarItem {
  final SettingsSection section;
  final String title;
  final IconData icon;

  const _SidebarItem({
    required this.section,
    required this.title,
    required this.icon,
  });
}
