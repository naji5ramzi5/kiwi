import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import 'general_settings_page.dart';
import 'thermal_printer_settings_page.dart';
import 'thermal_receipt_designer_page.dart';
import 'barcode_printer_settings_page.dart';
import 'barcode_label_designer_page.dart';
import 'backup_settings_page.dart';
import 'users_settings_page.dart';
import 'system_settings_page.dart';
import 'about_page.dart';

enum SettingsSection {
  general,
  thermalPrinter,
  receiptDesigner,
  barcodePrinter,
  labelDesigner,
  backup,
  users,
  system,
  about,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsSection _selectedSection = SettingsSection.general;

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
      section: SettingsSection.receiptDesigner,
      title: 'تصميم الفاتورة الحرارية',
      icon: LucideIcons.receipt,
    ),
    _SidebarItem(
      section: SettingsSection.barcodePrinter,
      title: 'إعدادات طابعة الباركود',
      icon: LucideIcons.qrCode,
    ),
    _SidebarItem(
      section: SettingsSection.labelDesigner,
      title: 'تصميم ملصق الباركود',
      icon: LucideIcons.tag,
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
    _SidebarItem(
      section: SettingsSection.about,
      title: 'حول البرنامج',
      icon: LucideIcons.info,
    ),
  ];

  Widget _buildContentArea() {
    switch (_selectedSection) {
      case SettingsSection.general:
        return const GeneralSettingsPage();
      case SettingsSection.thermalPrinter:
        return const ThermalPrinterSettingsPage();
      case SettingsSection.receiptDesigner:
        return const ThermalReceiptDesignerPage();
      case SettingsSection.barcodePrinter:
        return const BarcodePrinterSettingsPage();
      case SettingsSection.labelDesigner:
        return const BarcodeLabelDesignerPage();
      case SettingsSection.backup:
        return const BackupSettingsPage();
      case SettingsSection.users:
        return const UsersSettingsPage();
      case SettingsSection.system:
        return const SystemSettingsPage();
      case SettingsSection.about:
        return const AboutPage();
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الإعدادات',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '管理中心',
                                style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
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
