import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/barcode_settings.dart';

class BarcodePrinterFullPage extends StatefulWidget {
  const BarcodePrinterFullPage({super.key});

  @override
  State<BarcodePrinterFullPage> createState() => _BarcodePrinterFullPageState();
}

class _BarcodePrinterFullPageState extends State<BarcodePrinterFullPage> with SingleTickerProviderStateMixin {
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
                Tab(text: 'تصميم الملصق', icon: Icon(LucideIcons.paintbrush, size: 18)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _BarcodeSettingsTab(),
                _BarcodeDesignerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 1: Printer Settings (from barcode_printer_settings_page.dart)
// ---------------------------------------------------------------------------
class _BarcodeSettingsTab extends StatefulWidget {
  const _BarcodeSettingsTab();

  @override
  State<_BarcodeSettingsTab> createState() => _BarcodeSettingsTabState();
}

class _BarcodeSettingsTabState extends State<_BarcodeSettingsTab> {
  late BarcodeSettings _settings;
  bool _loaded = false;
  bool _saving = false;
  List<Printer> _printers = [];
  Printer? _selectedPrinter;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    _settings = await BarcodeSettings.load();
    _selectedPrinter = _settings.printerName.isNotEmpty ? Printer(name: _settings.printerName, url: '') : null;
    setState(() => _loaded = true);
  }

  Future<void> _searchPrinters() async {
    final printers = await Printing.listPrinters();
    setState(() {
      _printers = printers;
      if (_settings.printerName.isNotEmpty) {
        final match = printers.where((p) => p.name == _settings.printerName);
        _selectedPrinter = match.isNotEmpty ? match.first : null;
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم العثور على ${printers.length} طابعة'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _autoSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _settings.save());
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    _debounce?.cancel();
    await _settings.save();
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('تم حفظ إعدادات طابعة الملصقات'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
  }

  Future<void> _testPrint() async {
    if (_selectedPrinter == null) return;
    final font = await PdfGoogleFonts.tajawalRegular();
    final fontBold = await PdfGoogleFonts.tajawalBold();
    final doc = pw.Document();
    final size = _getPaperSize();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(size[0], size[1], marginAll: _settings.printMargins),
        build: (context) => pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (_settings.showProductName) pw.Text('طماطم طازجة', style: pw.TextStyle(font: fontBold, fontSize: _settings.nameFontSize * _settings.fontSize), textAlign: pw.TextAlign.center),
            if (_settings.showBranchName) pw.Text('فرع بغداد الرئيسي', style: pw.TextStyle(font: font, fontSize: 10 * _settings.fontSize, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
            if (_settings.showBarcode) pw.BarcodeWidget(barcode: _getBarcodeType(), data: '001234567890', width: _settings.barcodeWidth * _settings.fontSize, height: _settings.barcodeHeight * _settings.fontSize),
            if (_settings.showPrice) pw.Text('2,500 د.ع', style: pw.TextStyle(font: fontBold, fontSize: _settings.priceFontSize * _settings.fontSize, color: PdfColors.orange800), textAlign: pw.TextAlign.center),
            if (_settings.showSku) pw.Text('SKU: TOM-001', style: pw.TextStyle(font: font, fontSize: 8 * _settings.fontSize, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
            if (_settings.showBatchNumber) pw.Text('الدفعة: B2026-07', style: pw.TextStyle(font: font, fontSize: 8 * _settings.fontSize, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
            if (_settings.showExpiryDate) pw.Text('الصالحية: 2026/08/15', style: pw.TextStyle(font: font, fontSize: 8 * _settings.fontSize, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
            if (_settings.showQrCode) pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: 'https://kiwi.store/product/001', width: 30 * _settings.fontSize, height: 30 * _settings.fontSize),
            pw.Text('001234567890', style: pw.TextStyle(font: font, fontSize: 8 * _settings.fontSize), textAlign: pw.TextAlign.center),
          ],
        ),
      ),
    );

    final pdfBytes = await doc.save();
    await Printing.layoutPdf(onLayout: (format) => pdfBytes, name: 'ملصق تجريبي');
  }

  List<double> _getPaperSize() {
    switch (_settings.paperWidth) {
      case '40x30mm': return [40, 30];
      case '60x40mm': return [60, 40];
      case '100x50mm': return [100, 50];
      case '50x25mm': return [50, 25];
      case '50x30mm':
      default: return [50, 30];
    }
  }

  pw.Barcode _getBarcodeType() {
    switch (_settings.barcodeType) {
      case 'EAN13': return pw.Barcode.ean13();
      case 'QR': return pw.Barcode.qrCode();
      case 'CODE128':
      default: return pw.Barcode.code128();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPrinterSelection(),
          const SizedBox(height: 16),
          _buildLabelSize(),
          const SizedBox(height: 16),
          _buildPrintSettings(),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildPrinterSelection() {
    return _buildSectionCard(
      title: 'اختيار الطابعة',
      subtitle: 'تحديد طابعة الملصقات والبحث عن الطابعات المتاحة',
      icon: LucideIcons.printer,
      iconColor: AppTheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<Printer>(
            value: _selectedPrinter,
            decoration: InputDecoration(
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
              hintText: 'اختر طابعة الملصقات',
            ),
            items: _printers.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (v) { setState(() { _selectedPrinter = v; _settings.printerName = v?.name ?? ''; }); _autoSave(); },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SizedBox(height: 44, child: OutlinedButton.icon(
                onPressed: _searchPrinters,
                icon: const Icon(LucideIcons.search, size: 16),
                label: const Text('بحث عن الطابعات'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: const BorderSide(color: AppTheme.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ))),
              const SizedBox(width: 12),
              Expanded(child: SizedBox(height: 44, child: Container(
                decoration: BoxDecoration(gradient: _selectedPrinter != null ? AppTheme.primaryGradient : null, borderRadius: BorderRadius.circular(12)),
                child: ElevatedButton.icon(
                  onPressed: _selectedPrinter == null ? null : _testPrint,
                  icon: const Icon(LucideIcons.play, size: 16),
                  label: const Text('طباعة تجريبية'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedPrinter != null ? Colors.transparent : Colors.grey.shade200,
                    foregroundColor: _selectedPrinter != null ? Colors.white : Colors.grey.shade500,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ))),
            ],
          ),
          if (_selectedPrinter != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(LucideIcons.checkCircle2, color: AppTheme.success, size: 18),
                const SizedBox(width: 8),
                Text('الطابعة جاهزة: ${_selectedPrinter!.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.success)),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabelSize() {
    return _buildSectionCard(
      title: 'حجم ملصق الباركود',
      subtitle: 'اختر الحجم المناسب لطابعتك',
      icon: LucideIcons.maximize2,
      iconColor: AppTheme.warning,
      child: Wrap(
        spacing: 12, runSpacing: 12,
        children: [
          _buildSizeOption('40x30mm', '40 × 30 مم', 'صغير'),
          _buildSizeOption('50x25mm', '50 × 25 مم', 'متوسط'),
          _buildSizeOption('60x40mm', '60 × 40 مم', 'كبير'),
          _buildSizeOption('100x50mm', '100 × 50 مم', 'كبير جداً'),
        ],
      ),
    );
  }

  Widget _buildSizeOption(String value, String label, String tag) {
    final isSelected = _settings.paperWidth == value;
    return GestureDetector(
      onTap: () { setState(() => _settings.paperWidth = value); _autoSave(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.warning.withOpacity(0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppTheme.warning : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isSelected ? AppTheme.warning : AppTheme.textPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: isSelected ? AppTheme.warning : AppTheme.textSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.textSecondary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintSettings() {
    return _buildSectionCard(
      title: 'إعدادات الطباعة',
      subtitle: 'عدد النسخ واتجاه الطباعة والهوامش',
      icon: LucideIcons.settings,
      iconColor: AppTheme.info,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('عدد النسخ الافتراضي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('عدد النسخ المطبوعة لكل ملصق', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ])),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Row(children: [
                  _buildSpinnerButton(icon: LucideIcons.minus, onTap: _settings.copies > 1 ? () { setState(() => _settings.copies--); _autoSave(); } : null),
                  Container(width: 48, alignment: Alignment.center, child: Text('${_settings.copies}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  _buildSpinnerButton(icon: LucideIcons.plus, onTap: _settings.copies < 20 ? () { setState(() => _settings.copies++); _autoSave(); } : null),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('اتجاه الطباعة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('اتجاه طباعة الملصق', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _settings.printDirection, isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'ltr', child: Text('من اليسار إلى اليمين')),
                      DropdownMenuItem(value: 'rtl', child: Text('من اليمين إلى اليسار')),
                      DropdownMenuItem(value: 'ttb', child: Text('من الأعلى إلى الأسفل')),
                    ],
                    onChanged: (v) { if (v != null) { setState(() => _settings.printDirection = v); _autoSave(); } },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpinnerButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(onTap: onTap, child: Container(width: 40, height: 40, alignment: Alignment.center, child: Icon(icon, size: 16, color: onTap != null ? AppTheme.primary : Colors.grey.shade300)));
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, height: 52,
      child: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.buttonShadow),
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(LucideIcons.save, size: 20),
          label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ الإعدادات', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String subtitle, required IconData icon, required Color iconColor, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: iconColor.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          ]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 2: Label Designer (from barcode_label_designer_page.dart)
// ---------------------------------------------------------------------------
class _BarcodeDesignerTab extends StatefulWidget {
  const _BarcodeDesignerTab();

  @override
  State<_BarcodeDesignerTab> createState() => _BarcodeDesignerTabState();
}

class _BarcodeDesignerTabState extends State<_BarcodeDesignerTab> {
  late BarcodeSettings _settings;
  bool _loaded = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    _settings = await BarcodeSettings.load();
    setState(() => _loaded = true);
  }

  void _autoSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _settings.save());
  }

  void _resetToDefaults() {
    setState(() => _settings = BarcodeSettings());
    _autoSave();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('تمت استعادة الإعدادات الافتراضية'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
  }

  List<double> _getLabelDimensions() {
    switch (_settings.paperWidth) {
      case '40x30mm': return [180.0, 135.0];
      case '50x25mm': return [200.0, 100.0];
      case '60x40mm': return [240.0, 160.0];
      case '100x50mm': return [300.0, 150.0];
      case '50x30mm':
      default: return [200.0, 120.0];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildPreview()),
          const SizedBox(width: 24),
          Expanded(flex: 3, child: _buildControls()),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final dims = _getLabelDimensions();
    final fs = _settings.fontSize;
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Row(children: [
              const Icon(LucideIcons.eye, size: 18, color: AppTheme.primary),
              const SizedBox(width: 10),
              const Text('معاينة الملصق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.primaryLighter, borderRadius: BorderRadius.circular(6)),
                child: Text(_settings.paperWidth, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
            ]),
          ),
          Expanded(
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: dims[0], height: dims[1],
                padding: EdgeInsets.all(_settings.printMargins * 2),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_settings.showProductName) ...[
                      Text('طماطم طازجة', style: TextStyle(fontSize: _settings.nameFontSize * fs, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, height: 1.2), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 2 * fs),
                    ],
                    if (_settings.showSku) ...[
                      Text('SKU: TOM-001', style: TextStyle(fontSize: 8 * fs, color: AppTheme.textSecondary, height: 1.2), textAlign: TextAlign.center),
                      SizedBox(height: 2 * fs),
                    ],
                    if (_settings.showBarcode) ...[
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 2 * fs),
                        child: Column(children: [
                          Container(width: _settings.barcodeWidth * fs * 0.5, height: _settings.barcodeHeight * fs * 0.5, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)), child: Center(child: Text('||| || ||| | || |||', style: TextStyle(color: Colors.white, fontSize: 8 * fs, fontFamily: 'monospace', letterSpacing: 1)))),
                          SizedBox(height: 2 * fs),
                          Text('001234567890', style: TextStyle(fontSize: 7 * fs, fontFamily: 'monospace', color: AppTheme.textSecondary), textAlign: TextAlign.center),
                        ]),
                      ),
                    ],
                    if (_settings.showQrCode) ...[
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 2 * fs),
                        width: 30 * fs, height: 30 * fs,
                        decoration: BoxDecoration(border: Border.all(color: AppTheme.textPrimary, width: 1), borderRadius: BorderRadius.circular(2)),
                        child: Center(child: Icon(LucideIcons.qrCode, size: 22 * fs, color: AppTheme.textPrimary)),
                      ),
                    ],
                    if (_settings.showPrice) ...[
                      Text('2,500 د.ع', style: TextStyle(fontSize: _settings.priceFontSize * fs, fontWeight: FontWeight.bold, color: AppTheme.accent, height: 1.2), textAlign: TextAlign.center),
                      SizedBox(height: 1 * fs),
                    ],
                    if (_settings.showBatchNumber) Text('الدفعة: B2026-07', style: TextStyle(fontSize: 7 * fs, color: AppTheme.textLight, height: 1.2), textAlign: TextAlign.center),
                    if (_settings.showExpiryDate) Text('الصالحية: 2026/08/15', style: TextStyle(fontSize: 7 * fs, color: AppTheme.textLight, height: 1.2), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionCard(title: 'حجم الخط', subtitle: 'تخصيص حجم خط اسم المنتج والسعر', icon: LucideIcons.type, iconColor: AppTheme.primary, child: Column(children: [
            _buildFontSizeSlider(label: 'حجم خط اسم المنتج', value: _settings.nameFontSize, min: 8.0, max: 24.0, onChanged: (v) { setState(() => _settings.nameFontSize = v); _autoSave(); }),
            const SizedBox(height: 16),
            _buildFontSizeSlider(label: 'حجم خط السعر', value: _settings.priceFontSize, min: 10.0, max: 28.0, onChanged: (v) { setState(() => _settings.priceFontSize = v); _autoSave(); }),
          ])),
          const SizedBox(height: 16),
          _buildSectionCard(title: 'حجم الباركود', subtitle: 'تخصيص ارتفاع وعرض شريط الباركود', icon: LucideIcons.maximize2, iconColor: AppTheme.info, child: Column(children: [
            _buildFontSizeSlider(label: 'ارتفاع الباركود', value: _settings.barcodeHeight, min: 15.0, max: 80.0, onChanged: (v) { setState(() => _settings.barcodeHeight = v); _autoSave(); }),
            const SizedBox(height: 16),
            _buildFontSizeSlider(label: 'عرض الباركود', value: _settings.barcodeWidth, min: 60.0, max: 200.0, onChanged: (v) { setState(() => _settings.barcodeWidth = v); _autoSave(); }),
          ])),
          const SizedBox(height: 16),
          _buildSectionCard(title: 'خيارات العرض', subtitle: 'تحديد المعلومات الظاهرة على الملصق', icon: LucideIcons.eye, iconColor: AppTheme.secondary, child: Column(children: [
            _buildToggleRow('إظهار اسم المنتج', _settings.showProductName, (v) { setState(() => _settings.showProductName = v); _autoSave(); }),
            _buildToggleRow('إظهار السعر', _settings.showPrice, (v) { setState(() => _settings.showPrice = v); _autoSave(); }),
            _buildToggleRow('إظهار الباركود', _settings.showBarcode, (v) { setState(() => _settings.showBarcode = v); _autoSave(); }),
            _buildToggleRow('إظهار رقم الصنف (SKU)', _settings.showSku, (v) { setState(() => _settings.showSku = v); _autoSave(); }),
            _buildToggleRow('إظهار تاريخ الصلاحية', _settings.showExpiryDate, (v) { setState(() => _settings.showExpiryDate = v); _autoSave(); }),
            _buildToggleRow('إظهار رقم التشغيلة', _settings.showBatchNumber, (v) { setState(() => _settings.showBatchNumber = v); _autoSave(); }),
            _buildToggleRow('إظهار رمز QR', _settings.showQrCode, (v) { setState(() => _settings.showQrCode = v); _autoSave(); }),
          ])),
          const SizedBox(height: 16),
          _buildSectionCard(title: 'نوع الباركود', subtitle: 'اختيار تنسيق ترميز الباركود', icon: LucideIcons.scanLine, iconColor: AppTheme.warning, child: Column(children: [
            _buildBarcodeTypeOption('CODE128', 'شائع الاستخدام، يدعم الأرقام والحروف'),
            const SizedBox(height: 10),
            _buildBarcodeTypeOption('EAN13', 'مستخدم في المنتجات التجارية والبضائع'),
            const SizedBox(height: 10),
            _buildBarcodeTypeOption('QR', 'رمز استجابة سريع، يدعم روابط ومعلومات كثيرة'),
          ])),
          const SizedBox(height: 16),
          _buildSectionCard(title: 'الإجراءات', subtitle: 'إدارة الإعدادات', icon: LucideIcons.settings, iconColor: AppTheme.error, child: Column(children: [
            SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(
              onPressed: _resetToDefaults, icon: const Icon(LucideIcons.rotateCcw, size: 18), label: const Text('استعادة الإعدادات الافتراضية'),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 48, child: Container(
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.buttonShadow),
              child: ElevatedButton.icon(
                onPressed: () async { await _settings.save(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم حفظ التصميم بنجاح'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))); },
                icon: const Icon(LucideIcons.save, size: 18), label: const Text('حفظ التصميم'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            )),
          ])),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFontSizeSlider({required String label, required double value, required double min, required double max, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primaryLighter, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.toStringAsFixed(1)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(LucideIcons.minus, size: 14, color: AppTheme.textSecondary),
          Expanded(child: Slider(value: value, min: min, max: max, divisions: ((max - min) * 2).round(), activeColor: AppTheme.primary, inactiveColor: AppTheme.primaryLighter, label: value.toStringAsFixed(1), onChanged: onChanged)),
          const Icon(LucideIcons.plus, size: 14, color: AppTheme.textSecondary),
        ]),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        Switch(value: value, activeColor: AppTheme.primary, onChanged: onChanged),
      ]),
    );
  }

  Widget _buildBarcodeTypeOption(String type, String description) {
    final isSelected = _settings.barcodeType == type;
    return GestureDetector(
      onTap: () { setState(() => _settings.barcodeType = type); _autoSave(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.warning.withOpacity(0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.warning : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20, height: 20,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? AppTheme.warning : Colors.grey.shade300, border: Border.all(color: isSelected ? AppTheme.warning : Colors.grey.shade400, width: 2)),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? AppTheme.warning : AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(description, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String subtitle, required IconData icon, required Color iconColor, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: iconColor.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          ]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
