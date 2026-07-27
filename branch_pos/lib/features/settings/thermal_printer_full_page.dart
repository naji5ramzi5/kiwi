import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/invoice_settings.dart';
import '../../theme/app_theme.dart';

class ThermalPrinterFullPage extends StatefulWidget {
  const ThermalPrinterFullPage({super.key});

  @override
  State<ThermalPrinterFullPage> createState() => _ThermalPrinterFullPageState();
}

class _ThermalPrinterFullPageState extends State<ThermalPrinterFullPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primary,
              labelStyle: GoogleFonts.notoSansArabic(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: 'الإعدادات', icon: Icon(LucideIcons.settings, size: 18)),
                Tab(text: 'تصميم الإيصال', icon: Icon(LucideIcons.fileText, size: 18)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ThermalSettingsTab(),
                _ThermalDesignerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 1: Printer Settings
// ---------------------------------------------------------------------------
class _ThermalSettingsTab extends StatefulWidget {
  const _ThermalSettingsTab();

  @override
  State<_ThermalSettingsTab> createState() => _ThermalSettingsTabState();
}

class _ThermalSettingsTabState extends State<_ThermalSettingsTab> {
  List<Printer> _availablePrinters = [];
  Printer? _selectedPrinter;
  bool _isScanning = false;
  String _paperSize = '80mm';
  int _copiesCount = 1;
  bool _openCashDrawer = false;
  bool _autoCut = true;
  bool _silentPrint = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scanPrinters();
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
      if (savedPrinterName != null && _availablePrinters.isNotEmpty) {
        final matching = _availablePrinters.where((p) => p.name == savedPrinterName);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            pdf.Text('اختبار الطباعة', style: pdf.TextStyle(fontSize: 20, fontWeight: pdf.FontWeight.bold)),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildPrinterSelection(),
            const SizedBox(height: 16),
            _buildPaperSettings(),
            const SizedBox(height: 16),
            _buildPrintOptions(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterSelection() {
    return _buildSectionCard(
      title: 'اختيار الطابعة',
      subtitle: 'اختر الطابعة الحرارية المتصلة',
      icon: LucideIcons.printer,
      iconColor: AppTheme.primary,
      child: Column(
        children: [
          DropdownButtonFormField<Printer>(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
              hintText: 'اختر الطابعة',
            ),
            value: _selectedPrinter,
            items: _availablePrinters.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (v) => setState(() => _selectedPrinter = v),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedPrinter != null ? AppTheme.successLight : AppTheme.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedPrinter != null ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                  size: 18,
                  color: _selectedPrinter != null ? AppTheme.success : AppTheme.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPrinter != null ? 'الطابعة جاهزة' : 'لم يتم اختيار طابعة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedPrinter != null ? AppTheme.success : AppTheme.warning,
                        ),
                      ),
                      if (_selectedPrinter != null)
                        Text(_selectedPrinter!.name, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _isScanning ? null : _scanPrinters,
                    icon: _isScanning
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                        : const Icon(LucideIcons.refreshCw, size: 16),
                    label: Text(_isScanning ? 'جاري البحث...' : 'بحث عن الطابعات', style: const TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      gradient: _selectedPrinter != null ? AppTheme.primaryGradient : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _selectedPrinter == null ? null : _testPrint,
                      icon: const Icon(LucideIcons.play, size: 16),
                      label: const Text('طباعة تجريبية', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPrinter != null ? Colors.transparent : Colors.grey.shade200,
                        foregroundColor: _selectedPrinter != null ? Colors.white : Colors.grey.shade500,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildPaperSettings() {
    return _buildSectionCard(
      title: 'إعدادات الورق',
      subtitle: 'حجم الورق وعدد النسخ',
      icon: LucideIcons.fileText,
      iconColor: AppTheme.warning,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPaperOption(value: '58mm', label: '58 مم (صغير)', icon: LucideIcons.minimize2, color: AppTheme.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaperOption(value: '80mm', label: '80 مم (قياسي)', icon: LucideIcons.maximize2, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Text('عدد النسخ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              Container(
                decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _copiesCount > 1 ? () => setState(() => _copiesCount--) : null,
                      icon: const Icon(LucideIcons.minus, size: 18),
                      color: AppTheme.primary,
                    ),
                    Container(width: 40, alignment: Alignment.center, child: Text('$_copiesCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    IconButton(
                      onPressed: _copiesCount < 10 ? () => setState(() => _copiesCount++) : null,
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

  Widget _buildPaperOption({required String value, required String label, required IconData icon, required Color color}) {
    final isSelected = _paperSize == value;
    return GestureDetector(
      onTap: () => setState(() => _paperSize = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : AppTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : AppTheme.textSecondary, size: 20),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? color : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintOptions() {
    return _buildSectionCard(
      title: 'خيارات الطباعة',
      subtitle: 'خيارات إضافية للطباعة',
      icon: LucideIcons.slidersHorizontal,
      iconColor: AppTheme.info,
      child: Column(
        children: [
          _buildToggleRow(label: 'فتح صندوق النقد بعد الطباعة', value: _openCashDrawer, onChanged: (v) => setState(() => _openCashDrawer = v), icon: LucideIcons.unlock),
          const SizedBox(height: 8),
          _buildToggleRow(label: 'قطع الورق تلقائياً', value: _autoCut, onChanged: (v) => setState(() => _autoCut = v), icon: LucideIcons.scissors),
          const SizedBox(height: 8),
          _buildToggleRow(label: 'طباعة صامتة (بدون أصوات)', value: _silentPrint, onChanged: (v) => setState(() => _silentPrint = v), icon: LucideIcons.volumeX),
        ],
      ),
    );
  }

  Widget _buildToggleRow({required String label, required bool value, required ValueChanged<bool> onChanged, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          Switch(value: value, activeColor: AppTheme.primary, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.buttonShadow),
        child: ElevatedButton.icon(
          onPressed: _saveSettings,
          icon: const Icon(LucideIcons.save, size: 20),
          label: const Text('حفظ إعدادات الطابعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String subtitle, required IconData icon, required Color iconColor, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: iconColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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
}

// ---------------------------------------------------------------------------
// TAB 2: Receipt Designer
// ---------------------------------------------------------------------------
class _ThermalDesignerTab extends StatefulWidget {
  const _ThermalDesignerTab();

  @override
  State<_ThermalDesignerTab> createState() => _ThermalDesignerTabState();
}

class _ThermalDesignerTabState extends State<_ThermalDesignerTab> {
  InvoiceSettings _settings = InvoiceSettings();
  bool _isLoading = true;
  Timer? _debounceTimer;
  bool _showLogo = true;
  bool _showCashierName = true;
  bool _showTaxNumber = true;
  bool _showQRCode = false;
  String _fontFamily = 'Noto Sans Arabic';
  Color _receiptBgColor = Colors.white;

  final TextEditingController _footerController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storePhoneController = TextEditingController();
  final TextEditingController _storeAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await InvoiceSettings.load();
    setState(() {
      _settings = settings;
      _footerController.text = settings.footerText;
      _storeNameController.text = settings.storeName;
      _storePhoneController.text = settings.storePhone;
      _storeAddressController.text = settings.storeAddress;
      _isLoading = false;
    });
  }

  void _onChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () => _settings.save());
    setState(() {});
  }

  void _resetToDefaults() {
    final defaults = InvoiceSettings();
    setState(() {
      _settings = defaults;
      _showLogo = true;
      _showCashierName = true;
      _showTaxNumber = true;
      _showQRCode = false;
      _fontFamily = 'Noto Sans Arabic';
      _receiptBgColor = Colors.white;
      _footerController.text = defaults.footerText;
      _storeNameController.text = defaults.storeName;
      _storePhoneController.text = defaults.storePhone;
      _storeAddressController.text = defaults.storeAddress;
    });
    _onChanged();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _footerController.dispose();
    _storeNameController.dispose();
    _storePhoneController.dispose();
    _storeAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    return Row(
      children: [
        Expanded(flex: 2, child: _buildPreviewSection()),
        const SizedBox(width: 1),
        Container(color: AppTheme.primaryLighter, width: 1),
        Expanded(flex: 3, child: _buildSettingsSection()),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: Center(
        child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: _buildReceiptPaper()),
      ),
    );
  }

  Widget _buildReceiptPaper() {
    final fs = _settings.fontSize;
    final isCenter = _settings.alignment == 'center';
    final align = isCenter ? TextAlign.center : TextAlign.right;

    return Container(
      width: 280,
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: _receiptBgColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: isCenter ? CrossAxisAlignment.center : CrossAxisAlignment.end,
              children: [
                if (_showLogo)
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: Icon(Icons.storefront, size: 36 * fs, color: AppTheme.primary)),
                _receiptLine(_settings.storeName, fontSize: 16 * fs, fontWeight: FontWeight.w800, align: align),
                if (_settings.storePhone.isNotEmpty) _receiptLine(_settings.storePhone, fontSize: 11 * fs, align: align, color: Colors.grey.shade600),
                if (_settings.storeAddress.isNotEmpty) _receiptLine(_settings.storeAddress, fontSize: 11 * fs, align: align, color: Colors.grey.shade600),
                const SizedBox(height: 8),
                _dashedDivider(),
                const SizedBox(height: 8),
                if (_showCashierName) _receiptLine('الكاشير: أحمد', fontSize: 10 * fs, align: align, color: Colors.grey.shade600),
                if (_settings.showCustomerInfo) _receiptLine('العميل: محمد علي', fontSize: 10 * fs, align: align, color: Colors.grey.shade600),
                if (_showTaxNumber) _receiptLine('الرقم الضريبي: 123456789', fontSize: 9 * fs, align: align, color: Colors.grey.shade500),
                const SizedBox(height: 8),
                _dashedDivider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _receiptLine('الصنف', fontSize: 10 * fs, fontWeight: FontWeight.bold),
                    _receiptLine('الكمية', fontSize: 10 * fs, fontWeight: FontWeight.bold),
                    _receiptLine('السعر', fontSize: 10 * fs, fontWeight: FontWeight.bold),
                  ],
                ),
                const SizedBox(height: 4),
                _dashedDivider(),
                const SizedBox(height: 4),
                _buildItemRow('تفاح أحمر', '2 كجم', '4,000 د.ع', fs),
                _buildItemRow('موز', '1 كجم', '2,500 د.ع', fs),
                _buildItemRow('حليب طازج', '3 حبة', '6,750 د.ع', fs),
                _buildItemRow('خبز أبيض', '1 رغيف', '1,000 د.ع', fs),
                const SizedBox(height: 8),
                _dashedDivider(),
                const SizedBox(height: 8),
                _totalRow('المجموع الفرعي:', '14,250 د.ع', fs),
                const SizedBox(height: 2),
                _totalRow('الضريبة (10%):', '1,425 د.ع', fs),
                const SizedBox(height: 4),
                _dashedDivider(),
                const SizedBox(height: 4),
                _totalRow('الإجمالي:', '15,675 د.ع', fs, bold: true, fontSize: 14 * fs),
                _dashedDivider(),
                const SizedBox(height: 8),
                if (_settings.showDate) _receiptLine(_formatNow(), fontSize: 10 * fs, align: align, color: Colors.grey.shade500),
                const SizedBox(height: 12),
                if (_showQRCode) Padding(padding: const EdgeInsets.only(top: 10), child: Icon(Icons.qr_code_2, size: 64 * fs, color: Colors.black87)),
                const SizedBox(height: 12),
                _dashedDivider(),
                const SizedBox(height: 8),
                _receiptLine(_settings.footerText, fontSize: 11 * fs, align: align, color: Colors.grey.shade700),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Container(
            height: 8,
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1))),
          ),
        ],
      ),
    );
  }

  Widget _receiptLine(String text, {double fontSize = 12, FontWeight fontWeight = FontWeight.normal, TextAlign align = TextAlign.right, Color color = AppTheme.textPrimary}) {
    return Text(text, textAlign: align, style: GoogleFonts.getFont(_fontFamily, fontSize: fontSize, fontWeight: fontWeight, color: color));
  }

  Widget _buildItemRow(String name, String qty, String price, double fs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 4, child: Text(name, style: GoogleFonts.getFont(_fontFamily, fontSize: 11 * fs, color: AppTheme.textPrimary))),
          Expanded(flex: 2, child: Text(qty, textAlign: TextAlign.center, style: GoogleFonts.getFont(_fontFamily, fontSize: 11 * fs, color: AppTheme.textSecondary))),
          Expanded(flex: 3, child: Text(price, textAlign: TextAlign.right, style: GoogleFonts.getFont(_fontFamily, fontSize: 11 * fs, color: AppTheme.textPrimary))),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, double fs, {bool bold = false, double? fontSize}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.getFont(_fontFamily, fontSize: fontSize ?? (11 * fs), fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: AppTheme.textPrimary)),
        Text(value, style: GoogleFonts.getFont(_fontFamily, fontSize: fontSize ?? (11 * fs), fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: AppTheme.primary)),
      ],
    );
  }

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: List.generate(
            (constraints.maxWidth / 6).floor(),
            (i) => Expanded(child: Container(height: 1, color: i.isEven ? Colors.grey.shade300 : Colors.transparent)),
          ),
        );
      },
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSettingsSection() {
    return Container(
      color: AppTheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('الإعدادات العامة', style: GoogleFonts.notoSansArabic(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          _buildCard(title: 'إعدادات الخط', child: Column(children: [
            SliderTheme(
              data: SliderThemeData(activeTrackColor: AppTheme.primary, thumbColor: AppTheme.primary, overlayColor: AppTheme.primaryLighter, inactiveTrackColor: Colors.grey.shade200),
              child: Slider(
                value: _settings.fontSize, min: 0.7, max: 1.5, divisions: 16,
                onChanged: (v) { _settings.fontSize = v; _onChanged(); },
              ),
            ),
            DropdownButtonFormField<String>(
              value: _fontFamily,
              decoration: InputDecoration(
                labelText: 'نوع الخط',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'Noto Sans Arabic', child: Text('Noto Sans Arabic')),
                DropdownMenuItem(value: 'Cairo', child: Text('Cairo')),
                DropdownMenuItem(value: 'Tajawal', child: Text('Tajawal')),
                DropdownMenuItem(value: 'Almarai', child: Text('Almarai')),
                DropdownMenuItem(value: 'Amiri', child: Text('Amiri')),
              ],
              onChanged: (v) { if (v != null) setState(() => _fontFamily = v); _onChanged(); },
            ),
          ])),
          const SizedBox(height: 12),
          _buildCard(title: 'خيارات العرض', child: Column(children: [
            _buildToggleRow('إظهار الشعار', _showLogo, (v) { setState(() => _showLogo = v); _onChanged(); }),
            _buildToggleRow('إظهار معلومات العميل', _settings.showCustomerInfo, (v) { _settings.showCustomerInfo = v; _onChanged(); }),
            _buildToggleRow('إظهار اسم الكاشير', _showCashierName, (v) { setState(() => _showCashierName = v); _onChanged(); }),
            _buildToggleRow('إظهار التاريخ والوقت', _settings.showDate, (v) { _settings.showDate = v; _onChanged(); }),
            _buildToggleRow('إظهار الرقم الضريبي', _showTaxNumber, (v) { setState(() => _showTaxNumber = v); _onChanged(); }),
            _buildToggleRow('إظهار الباركود', _settings.showBarcode, (v) { _settings.showBarcode = v; _onChanged(); }),
            _buildToggleRow('إظهار كود QR', _showQRCode, (v) { setState(() => _showQRCode = v); _onChanged(); }),
          ])),
          const SizedBox(height: 12),
          _buildCard(title: 'معلومات المتجر', child: Column(children: [
            _buildTextField(label: 'اسم المتجر', controller: _storeNameController, onChanged: (v) { _settings.storeName = v; _onChanged(); }),
            const SizedBox(height: 10),
            _buildTextField(label: 'رقم الهاتف', controller: _storePhoneController, onChanged: (v) { _settings.storePhone = v; _onChanged(); }),
            const SizedBox(height: 10),
            _buildTextField(label: 'العنوان', controller: _storeAddressController, onChanged: (v) { _settings.storeAddress = v; _onChanged(); }),
          ])),
          const SizedBox(height: 12),
          _buildCard(title: 'نص التذييل', child: _buildTextField(label: 'نص التذييل', controller: _footerController, maxLines: 2, onChanged: (v) { _settings.footerText = v; _onChanged(); })),
          const SizedBox(height: 12),
          _buildCard(title: 'الإجراءات', child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetToDefaults,
              icon: const Icon(Icons.restart_alt, size: 20),
              label: Text('إعادة تعيين إلى الافتراضي', style: GoogleFonts.notoSansArabic(fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      color: AppTheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.notoSansArabic(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: GoogleFonts.notoSansArabic(fontSize: 13, color: AppTheme.textPrimary))),
          Transform.scale(scale: 0.85, child: Switch(value: value, activeColor: AppTheme.primary, activeTrackColor: AppTheme.primaryLight, onChanged: onChanged)),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required ValueChanged<String> onChanged, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.notoSansArabic(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSansArabic(color: AppTheme.textLight, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
      ),
      onChanged: onChanged,
    );
  }
}
