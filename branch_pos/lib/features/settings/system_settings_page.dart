import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';
import '../../theme/app_theme.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  String _defaultReceiptPrinter = 'HP LaserJet Pro';
  String _defaultBarcodePrinter = 'Zebra ZD421';
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _autoRefreshInterval = 30;
  bool _cacheEnabled = true;
  int _cacheSizeMB = 128;
  bool _debugMode = false;
  String _logLevel = 'info';
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _checkFullscreen();
  }

  Future<void> _checkFullscreen() async {
    try {
      final isFull = await windowManager.isFullScreen();
      if (mounted) setState(() => _isFullscreen = isFull);
    } catch (_) {}
  }

  Future<void> _toggleFullscreen() async {
    try {
      if (_isFullscreen) {
        await windowManager.setFullScreen(false);
      } else {
        await windowManager.setFullScreen(true);
      }
      setState(() => _isFullscreen = !_isFullscreen);
    } catch (_) {}
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
                    _buildDisplayCard(),
                    const SizedBox(height: 16),
                    _buildPrinterSettingsCard(),
                    const SizedBox(height: 16),
                    _buildNotificationSettingsCard(),
                    const SizedBox(height: 16),
                    _buildPerformanceCard(),
                    const SizedBox(height: 16),
                    _buildAdvancedCard(),
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
          child: const Icon(LucideIcons.monitor, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إعدادات النظام',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryDarker),
            ),
            const SizedBox(height: 2),
            Text(
              'إعدادات الطابعة والإشعارات والأداء',
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

  Widget _buildDisplayCard() {
    return _buildSectionCard(
      title: 'الشاشة',
      subtitle: 'التحكم بوضع ملء الشاشة',
      icon: LucideIcons.maximize2,
      iconColor: AppTheme.info,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isFullscreen ? 'وضع ملء الشاشة مفعّل' : 'وضع ملء الشاشة',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'يمكنك أيضاً استخدام مفتاح F11',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isFullscreen,
              activeColor: AppTheme.primary,
              onChanged: (_) => _toggleFullscreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterSettingsCard() {
    return _buildSectionCard(
      title: 'إعدادات الطابعة',
      subtitle: 'تحديد الطابعات الافتراضية',
      icon: LucideIcons.printer,
      iconColor: AppTheme.primary,
      child: Column(
        children: [
          _buildPrinterDropdown(
            label: 'طابعة الإيصالات الافتراضية',
            value: _defaultReceiptPrinter,
            onChanged: (v) => setState(() => _defaultReceiptPrinter = v!),
            items: const ['HP LaserJet Pro', 'Epson TM-T88', 'Canon PIXMA', 'Brother HL-L2350DW'],
          ),
          const SizedBox(height: 16),
          _buildPrinterDropdown(
            label: 'طابعة الباركود الافتراضية',
            value: _defaultBarcodePrinter,
            onChanged: (v) => setState(() => _defaultBarcodePrinter = v!),
            items: const ['Zebra ZD421', 'Honeywell PC45t', 'TSC TTP-244 Pro', 'Datamax E-4205A'],
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
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
              child: const Icon(LucideIcons.printer, color: AppTheme.primary, size: 18),
            ),
          ),
          items: items.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNotificationSettingsCard() {
    return _buildSectionCard(
      title: 'إعدادات الإشعارات',
      subtitle: 'تفعيل أو تعطيل الأصوات والاهتزاز',
      icon: LucideIcons.bell,
      iconColor: AppTheme.info,
      child: Column(
        children: [
          _buildToggleRow('تشغيل الأصوات', _soundEnabled, (v) {
            setState(() => _soundEnabled = v);
          }),
          const SizedBox(height: 8),
          _buildToggleRow('الاهتزاز عند الإشعارات', _vibrationEnabled, (v) {
            setState(() => _vibrationEnabled = v);
          }),
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

  Widget _buildPerformanceCard() {
    return _buildSectionCard(
      title: 'الأداء',
      subtitle: 'تحسين أداء النظام',
      icon: LucideIcons.gauge,
      iconColor: AppTheme.warning,
      child: Column(
        children: [
          _buildAutoRefreshSlider(),
          const SizedBox(height: 16),
          _buildCacheSettings(),
        ],
      ),
    );
  }

  Widget _buildAutoRefreshSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('فترة التحديث التلقائي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_autoRefreshInterval ثانية',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _autoRefreshInterval.toDouble(),
          min: 5,
          max: 120,
          divisions: 23,
          activeColor: AppTheme.primary,
          inactiveColor: AppTheme.primaryLighter,
          onChanged: (v) => setState(() => _autoRefreshInterval = v.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('5 ثوانٍ', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            Text('دقيقتان', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildCacheSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggleRow('تفعيل التخزين المؤقت', _cacheEnabled, (v) {
          setState(() => _cacheEnabled = v);
        }),
        if (_cacheEnabled) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.hardDrive, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    const Text('حجم التخزين المؤقت', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('$_cacheSizeMB MB', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _cacheSizeMB.toDouble(),
                  min: 32,
                  max: 512,
                  divisions: 15,
                  activeColor: AppTheme.primary,
                  inactiveColor: AppTheme.primaryLighter,
                  onChanged: (v) => setState(() => _cacheSizeMB = v.round()),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('مسح التخزين المؤقت'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(color: AppTheme.error.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedCard() {
    return _buildSectionCard(
      title: 'الإعدادات المتقدمة',
      subtitle: 'خيارات للمطورين والصيانة',
      icon: LucideIcons.terminal,
      iconColor: AppTheme.error,
      child: Column(
        children: [
          _buildToggleRow('وضع التطوير (Debug)', _debugMode, (v) {
            setState(() => _debugMode = v);
          }),
          const SizedBox(height: 12),
          _buildLogLevelDropdown(),
          if (_debugMode) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warningLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: AppTheme.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'وضع التطوير مفعّل — يعرض معلومات إضافية في السجلات',
                      style: TextStyle(fontSize: 12, color: AppTheme.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogLevelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('مستوى السجلات (Log Level)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _logLevel,
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
              child: const Icon(LucideIcons.scrollText, color: AppTheme.primary, size: 18),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'verbose', child: Text('Verbose (تفصيلي)')),
            DropdownMenuItem(value: 'debug', child: Text('Debug (تصحيح)')),
            DropdownMenuItem(value: 'info', child: Text('Info (معلومات)')),
            DropdownMenuItem(value: 'warning', child: Text('Warning (تحذير)')),
            DropdownMenuItem(value: 'error', child: Text('Error (أخطاء فقط)')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _logLevel = v);
          },
        ),
      ],
    );
  }
}
