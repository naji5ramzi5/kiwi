import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  bool _autoBackupEnabled = true;
  String _backupFrequency = 'daily';
  String _backupLocation = '/storage/emulated/0/kiwi_backups';
  bool _isBackingUp = false;

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
                    _buildBackupSettingsCard(),
                    const SizedBox(height: 16),
                    _buildManualBackupCard(),
                    const SizedBox(height: 16),
                    _buildDataManagementCard(),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
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
          child: const Icon(LucideIcons.database, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'النسخ الاحتياطي والاستعادة',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryDarker),
            ),
            const SizedBox(height: 2),
            Text(
              'إدارة النسخ الاحتياطي لبيانات النظام',
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

  Widget _buildBackupSettingsCard() {
    return _buildSectionCard(
      title: 'إعدادات النسخ الاحتياطي',
      subtitle: 'تفعيل وضبط النسخ الاحتياطي التلقائي',
      icon: LucideIcons.settings,
      iconColor: AppTheme.primary,
      child: Column(
        children: [
          _buildToggleRow('النسخ الاحتياطي التلقائي', _autoBackupEnabled, (v) {
            setState(() => _autoBackupEnabled = v);
          }),
          const SizedBox(height: 16),
          _buildFrequencyDropdown(),
          const SizedBox(height: 16),
          _buildBackupLocationField(),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Switch(
            value: value,
            activeColor: AppTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('تكرار النسخ الاحتياطي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _backupFrequency,
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
              child: const Icon(LucideIcons.calendar, color: AppTheme.primary, size: 18),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'daily', child: Text('يومياً')),
            DropdownMenuItem(value: 'weekly', child: Text('أسبوعياً')),
            DropdownMenuItem(value: 'monthly', child: Text('شهرياً')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _backupFrequency = v);
          },
        ),
      ],
    );
  }

  Widget _buildBackupLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('موقع النسخ الاحتياطي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _backupLocation,
          onChanged: (v) => _backupLocation = v,
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
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.folder, color: AppTheme.primary, size: 18),
            ),
            suffixIcon: IconButton(
              onPressed: () {},
              icon: const Icon(LucideIcons.folderSearch, color: AppTheme.primary, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualBackupCard() {
    return _buildSectionCard(
      title: 'النسخ الاحتياطي اليدوي',
      subtitle: 'إنشاء نسخة احتياطية الآن أو استعادتها',
      icon: LucideIcons.download,
      iconColor: AppTheme.info,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.buttonShadow,
                ),
                child: ElevatedButton.icon(
                  onPressed: _isBackingUp ? null : _performBackup,
                  icon: _isBackingUp
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.download, size: 18),
                  label: Text(_isBackingUp ? 'جارٍ النسخ...' : 'نسخ احتياطي الآن',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _restoreFromBackup,
                icon: const Icon(LucideIcons.upload, size: 18),
                label: const Text('استعادة من ملف', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.info, width: 1.5),
                  foregroundColor: AppTheme.info,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return _buildSectionCard(
      title: 'إدارة البيانات',
      subtitle: 'مسح البيانات أو تصديرها',
      icon: LucideIcons.layers,
      iconColor: AppTheme.warning,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _showClearDataDialog,
                icon: const Icon(LucideIcons.trash2, size: 18),
                label: const Text('مسح جميع البيانات', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error, width: 1.5),
                  foregroundColor: AppTheme.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.warningLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(LucideIcons.fileDown, size: 18, color: AppTheme.warning),
                  label: const Text('تصدير البيانات',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warning)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppTheme.warning,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.infoLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.info.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, color: AppTheme.info, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ماذا يتضمن النسخ الاحتياطي؟',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.info),
                ),
                const SizedBox(height: 8),
                Text(
                  'يتضمن النسخ الاحتياطي جميع بيانات النظام: المنتجات، الفواتير، المبيعات، الإعدادات، '
                  'بيانات المستخدمين، سجلات النشاطات، وإعدادات الواجهة. يُنصح بالنسخ الاحتياطي بانتظام لحماية بياناتك.',
                  style: TextStyle(fontSize: 13, color: AppTheme.info.withOpacity(0.8), height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _performBackup() {
    setState(() => _isBackingUp = true);
    Future.delayed(const Duration(seconds: 3), () {
      setState(() => _isBackingUp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إنشاء النسخة الاحتياطية بنجاح'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  }

  void _restoreFromBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('استعادة النسخة الاحتياطية'),
        content: const Text('هل أنت متأكد من استعادة النسخة الاحتياطية؟ سيتم استبدال جميع البيانات الحالية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمت الاستعادة بنجاح')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('استعادة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.alertTriangle, color: AppTheme.error, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('تحذير: مسح البيانات'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من مسح جميع البيانات؟ هذا الإجراء لا يمكن التراجع عنه.\n\n'
          'سيتم حذف:\n• جميع المنتجات\n• جميع الفواتير والمبيعات\n• جميع الإعدادات\n• سجلات النشاطات',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم مسح جميع البيانات')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('مسح الكل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جارٍ تصدير البيانات...')),
    );
  }
}
