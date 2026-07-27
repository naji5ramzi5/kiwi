import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class ThermalPrinterSettingsPage extends StatefulWidget {
  const ThermalPrinterSettingsPage({super.key});

  @override
  State<ThermalPrinterSettingsPage> createState() =>
      _ThermalPrinterSettingsPageState();
}

class _ThermalPrinterSettingsPageState
    extends State<ThermalPrinterSettingsPage> {
  // Printer Selection
  List<Printer> _availablePrinters = [];
  Printer? _selectedPrinter;
  bool _isScanning = false;

  // Paper Settings
  String _paperSize = '80mm';
  int _copiesCount = 1;

  // Print Options
  bool _openCashDrawer = false;
  bool _autoCut = true;
  bool _silentPrint = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scanPrinters();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrinterName = prefs.getString('thermal_printer_name');
    setState(() {
      _paperSize = prefs.getString('thermal_paper_size') ?? '80mm';
      _copiesCount = prefs.getInt('thermal_copies_count') ?? 1;
      _openCashDrawer = prefs.getBool('thermal_open_cash_drawer') ?? false;
      _autoCut = prefs.getBool('thermal_auto_cut') ?? true;
      _silentPrint = prefs.getBool('thermal_silent_print') ?? false;
      _isLoading = false;

      // Try to restore selected printer
      if (savedPrinterName != null && _availablePrinters.isNotEmpty) {
        final matching = _availablePrinters.where(
          (p) => p.name == savedPrinterName,
        );
        if (matching.isNotEmpty) _selectedPrinter = matching.first;
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('thermal_paper_size', _paperSize);
    await prefs.setInt('thermal_copies_count', _copiesCount);
    await prefs.setBool('thermal_open_cash_drawer', _openCashDrawer);
    await prefs.setBool('thermal_auto_cut', _autoCut);
    await prefs.setBool('thermal_silent_print', _silentPrint);
    if (_selectedPrinter != null) {
      await prefs.setString('thermal_printer_name', _selectedPrinter!.name);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حفظ إعدادات الطابعة الحرارية'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _scanPrinters() async {
    setState(() => _isScanning = true);
    try {
      final printers = await Printing.listPrinters();
      final prefs = await SharedPreferences.getInstance();
      final savedPrinterName = prefs.getString('thermal_printer_name');

      setState(() {
        _availablePrinters = printers;
        _isScanning = false;

        if (savedPrinterName != null && printers.isNotEmpty) {
          final matching = printers.where((p) => p.name == savedPrinterName);
          if (matching.isNotEmpty) _selectedPrinter = matching.first;
        }
      });
    } catch (e) {
      setState(() => _isScanning = false);
    }
  }

  void _testPrint() {
    if (_selectedPrinter == null) return;
    Printing.layoutPdf(
      onLayout: (format) async => Uint8List.fromList(await _generateTestPdf(format)),
    );
  }

  Future<List<int>> _generateTestPdf(PdfPageFormat format) async {
    final doc = pdf.Document();
    doc.addPage(
      pdf.Page(
        pageFormat: format,
        build: (pdf.Context context) => pdf.Column(
          crossAxisAlignment: pdf.CrossAxisAlignment.center,
          children: [
            pdf.Text(
              'اختبار الطباعة',
              style: pdf.TextStyle(
                fontSize: 20,
                fontWeight: pdf.FontWeight.bold,
              ),
            ),
            pdf.SizedBox(height: 10),
            pdf.Text('تم الاتصال بالطابعة بنجاح'),
            pdf.Text(_selectedPrinter!.name),
            pdf.SizedBox(height: 10),
            pdf.Text('التاريخ: ${DateTime.now().toString().substring(0, 19)}'),
          ],
        ),
      ),
    );
    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
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
                    _buildPrinterSelectionCard(),
                    const SizedBox(height: 16),
                    _buildPaperSettingsCard(),
                    const SizedBox(height: 16),
                    _buildPrintOptionsCard(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 24),
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
          child: const Icon(LucideIcons.printer, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إعدادات الطابعة الحرارية',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryDarker,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'إعداد الطابعة وحجم الورق وخيارات الطباعة',
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
            color: iconColor.withOpacity(0.06),
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
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

  Widget _buildPrinterSelectionCard() {
    return _buildSectionCard(
      title: 'اختيار الطابعة',
      subtitle: 'اختر الطابعة الحرارية المتصلة',
      icon: LucideIcons.printer,
      iconColor: AppTheme.primary,
      child: Column(
        children: [
          // Printer dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الطابعة المتصلة',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Printer>(
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
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 2,
                    ),
                  ),
                  hintText: 'اختر الطابعة',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLighter,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.printer,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                value: _selectedPrinter,
                items: _availablePrinters
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPrinter = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedPrinter != null
                  ? AppTheme.successLight
                  : AppTheme.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedPrinter != null
                      ? LucideIcons.checkCircle2
                      : LucideIcons.alertCircle,
                  size: 18,
                  color: _selectedPrinter != null
                      ? AppTheme.success
                      : AppTheme.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPrinter != null
                            ? 'الطابعة جاهزة'
                            : 'لم يتم اختيار طابعة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedPrinter != null
                              ? AppTheme.success
                              : AppTheme.warning,
                        ),
                      ),
                      if (_selectedPrinter != null)
                        Text(
                          _selectedPrinter!.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _isScanning ? null : _scanPrinters,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          )
                        : const Icon(LucideIcons.refreshCw, size: 16),
                    label: Text(
                      _isScanning ? 'جاري البحث...' : 'بحث عن الطابعات',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _selectedPrinter != null
                          ? AppTheme.primaryGradient
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _selectedPrinter != null
                          ? AppTheme.buttonShadow
                          : [],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _selectedPrinter == null ? null : _testPrint,
                      icon: const Icon(LucideIcons.play, size: 16),
                      label: const Text(
                        'طباعة تجريبية',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPrinter != null
                            ? Colors.transparent
                            : Colors.grey.shade200,
                        foregroundColor: _selectedPrinter != null
                            ? Colors.white
                            : Colors.grey.shade500,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaperSettingsCard() {
    return _buildSectionCard(
      title: 'إعدادات الورق',
      subtitle: 'حجم الورق وعدد النسخ',
      icon: LucideIcons.fileText,
      iconColor: AppTheme.warning,
      child: Column(
        children: [
          // Paper size radio
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'حجم الورق',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPaperOption(
                  value: '58mm',
                  label: '58 مم (صغير)',
                  icon: LucideIcons.minimize2,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaperOption(
                  value: '80mm',
                  label: '80 مم (قياسي)',
                  icon: LucideIcons.maximize2,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Copies count
          Row(
            children: [
              const Expanded(
                child: Text(
                  'عدد النسخ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _copiesCount > 1
                          ? () => setState(() => _copiesCount--)
                          : null,
                      icon: const Icon(LucideIcons.minus, size: 18),
                      color: AppTheme.primary,
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '$_copiesCount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _copiesCount < 10
                          ? () => setState(() => _copiesCount++)
                          : null,
                      icon: const Icon(LucideIcons.plus, size: 18),
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaperOption({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _paperSize == value;
    return GestureDetector(
      onTap: () => setState(() => _paperSize = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : AppTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintOptionsCard() {
    return _buildSectionCard(
      title: 'خيارات الطباعة',
      subtitle: 'خيارات إضافية للطباعة',
      icon: LucideIcons.slidersHorizontal,
      iconColor: AppTheme.info,
      child: Column(
        children: [
          _buildToggleRow(
            label: 'فتح صندوق النقد بعد الطباعة',
            value: _openCashDrawer,
            onChanged: (v) => setState(() => _openCashDrawer = v),
            icon: LucideIcons.unlock,
          ),
          const SizedBox(height: 8),
          _buildToggleRow(
            label: 'قطع الورق تلقائياً',
            value: _autoCut,
            onChanged: (v) => setState(() => _autoCut = v),
            icon: LucideIcons.scissors,
          ),
          const SizedBox(height: 8),
          _buildToggleRow(
            label: 'طباعة صامتة (بدون أصوات)',
            value: _silentPrint,
            onChanged: (v) => setState(() => _silentPrint = v),
            icon: LucideIcons.volumeX,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.buttonShadow,
        ),
        child: ElevatedButton.icon(
          onPressed: _saveSettings,
          icon: const Icon(LucideIcons.save, size: 20),
          label: const Text(
            'حفظ إعدادات الطابعة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
