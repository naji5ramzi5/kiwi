import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../models/barcode_settings.dart';

class BarcodePrinterSettingsPage extends StatefulWidget {
  const BarcodePrinterSettingsPage({super.key});

  @override
  State<BarcodePrinterSettingsPage> createState() =>
      _BarcodePrinterSettingsPageState();
}

class _BarcodePrinterSettingsPageState extends State<BarcodePrinterSettingsPage>
    with SingleTickerProviderStateMixin {
  late BarcodeSettings _settings;
  bool _loaded = false;
  bool _saving = false;
  List<Printer> _printers = [];
  Printer? _selectedPrinter;
  Timer? _debounce;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _settings = await BarcodeSettings.load();
    _selectedPrinter =
        _settings.printerName.isNotEmpty ? Printer(name: _settings.printerName, url: '') : null;
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
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _settings.save();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    _debounce?.cancel();
    await _settings.save();
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حفظ إعدادات طابعة الملصقات'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _testPrint() async {
    if (_selectedPrinter == null) return;
    final font = await PdfGoogleFonts.tajawalRegular();
    final fontBold = await PdfGoogleFonts.tajawalBold();
    final doc = pw.Document();
    final size = _getPaperSize();
    final fs = _settings.fontSize;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          size[0],
          size[1],
          marginAll: _settings.printMargins,
        ),
        build: (context) => pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (_settings.showProductName)
              pw.Text(
                'طماطم طازجة',
                style: pw.TextStyle(font: fontBold, fontSize: _settings.nameFontSize * fs),
                textAlign: pw.TextAlign.center,
              ),
            if (_settings.showBranchName)
              pw.Text(
                'فرع بغداد الرئيسي',
                style: pw.TextStyle(font: font, fontSize: 10 * fs, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
            if (_settings.showBarcode)
              pw.BarcodeWidget(
                barcode: _getBarcodeType(),
                data: '001234567890',
                width: _settings.barcodeWidth * fs,
                height: _settings.barcodeHeight * fs,
              ),
            if (_settings.showPrice)
              pw.Text(
                '2,500 د.ع',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: _settings.priceFontSize * fs,
                  color: PdfColors.orange800,
                ),
                textAlign: pw.TextAlign.center,
              ),
            if (_settings.showSku)
              pw.Text(
                'SKU: TOM-001',
                style: pw.TextStyle(font: font, fontSize: 8 * fs, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            if (_settings.showBatchNumber)
              pw.Text(
                'ال批次: B2026-07',
                style: pw.TextStyle(font: font, fontSize: 8 * fs, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            if (_settings.showExpiryDate)
              pw.Text(
                'الصالحية: 2026/08/15',
                style: pw.TextStyle(font: font, fontSize: 8 * fs, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            if (_settings.showQrCode)
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'https://kiwi.store/product/001',
                width: 30 * fs,
                height: 30 * fs,
              ),
            pw.Text(
              '001234567890',
              style: pw.TextStyle(font: font, fontSize: 8 * fs),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );

    final pdfBytes = await doc.save();
    await Printing.layoutPdf(
      onLayout: (format) => pdfBytes,
      name: 'ملصق تجريبي',
    );
  }

  List<double> _getPaperSize() {
    switch (_settings.paperWidth) {
      case '40x30mm':
        return [40, 30];
      case '60x40mm':
        return [60, 40];
      case '100x50mm':
        return [100, 50];
      case '50x25mm':
        return [50, 25];
      case '50x30mm':
      default:
        return [50, 30];
    }
  }

  pw.Barcode _getBarcodeType() {
    switch (_settings.barcodeType) {
      case 'EAN13':
        return pw.Barcode.ean13();
      case 'QR':
        return pw.Barcode.qrCode();
      case 'CODE128':
      default:
        return pw.Barcode.code128();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _loaded ? _buildContent() : _buildLoading(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildPrinterSelectionCard(),
          const SizedBox(height: 16),
          _buildLabelSizeCard(),
          const SizedBox(height: 16),
          _buildPrintSettingsCard(),
          const SizedBox(height: 24),
          _buildSaveButton(),
          const SizedBox(height: 40),
        ],
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
              'إعدادات طابعة الملصقات',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryDarker,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'تخصيص حجم الملصق وإعدادات الطباعة — التحديث لحظي',
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
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
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
      subtitle: 'تحديد طابعة الملصقات والبحث عن الطابعات المتاحة',
      icon: LucideIcons.printer,
      iconColor: AppTheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('طابعة الملصقات',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<Printer>(
            value: _selectedPrinter,
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
              hintText: 'اختر طابعة الملصقات',
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLighter,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.printer,
                    color: AppTheme.primary, size: 18),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _printers
                .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                .toList(),
            onChanged: (v) {
              setState(() {
                _selectedPrinter = v;
                _settings.printerName = v?.name ?? '';
              });
              _autoSave();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _searchPrinters,
                    icon: const Icon(LucideIcons.search, size: 16),
                    label: const Text('بحث عن الطابعات'),
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
                      label: const Text('طباعة تجريبية'),
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
          if (_selectedPrinter != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2,
                      color: AppTheme.success, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'الطابعة جاهزة: ${_selectedPrinter!.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
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

  Widget _buildLabelSizeCard() {
    return _buildSectionCard(
      title: 'حجم ملصق الباركود',
      subtitle: 'اختر الحجم المناسب لطابعتك',
      icon: LucideIcons.maximize2,
      iconColor: AppTheme.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildLabelSizeOption('40x30mm', '40 × 30 مم', 'صغير'),
              _buildLabelSizeOption('50x25mm', '50 × 25 مم', 'متوسط'),
              _buildLabelSizeOption('60x40mm', '60 × 40 مم', 'كبير'),
              _buildLabelSizeOption('100x50mm', '100 × 50 مم', 'كبير جداً'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabelSizeOption(String value, String label, String tag) {
    final isSelected = _settings.paperWidth == value;
    final size = _getPaperSizeFor(value);
    return GestureDetector(
      onTap: () {
        setState(() => _settings.paperWidth = value);
        _autoSave();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.warning.withOpacity(0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.warning : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isSelected ? AppTheme.warning : AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.warning
                        : AppTheme.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: size[0] * 1.2,
              height: size[1] * 1.2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${size[0].round()}×${size[1].round()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _getPaperSizeFor(String value) {
    switch (value) {
      case '40x30mm':
        return [40, 30];
      case '50x25mm':
        return [50, 25];
      case '60x40mm':
        return [60, 40];
      case '100x50mm':
        return [100, 50];
      default:
        return [50, 30];
    }
  }

  Widget _buildPrintSettingsCard() {
    return _buildSectionCard(
      title: 'إعدادات الطباعة',
      subtitle: 'عدد النسخ واتجاه الطباعة والهوامش',
      icon: LucideIcons.settings,
      iconColor: AppTheme.info,
      child: Column(
        children: [
          _buildCopiesSpinner(),
          const SizedBox(height: 20),
          _buildPrintDirectionDropdown(),
          const SizedBox(height: 20),
          _buildPrintMarginsSlider(),
        ],
      ),
    );
  }

  Widget _buildCopiesSpinner() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('عدد النسخ الافتراضي',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('عدد النسخ المطبوعة لكل ملصق',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _buildSpinnerButton(
                icon: LucideIcons.minus,
                onTap: _settings.copies > 1
                    ? () {
                        setState(() => _settings.copies--);
                        _autoSave();
                      }
                    : null,
              ),
              Container(
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  '${_settings.copies}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _buildSpinnerButton(
                icon: LucideIcons.plus,
                onTap: _settings.copies < 20
                    ? () {
                        setState(() => _settings.copies++);
                        _autoSave();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpinnerButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? AppTheme.primary : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildPrintDirectionDropdown() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اتجاه الطباعة',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('اتجاه طباعة الملصق',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _settings.printDirection,
              isDense: true,
              items: const [
                DropdownMenuItem(
                    value: 'ltr',
                    child: Text('من اليسار إلى اليمين (LTR)')),
                DropdownMenuItem(
                    value: 'rtl',
                    child: Text('من اليمين إلى اليسار (RTL)')),
                DropdownMenuItem(
                    value: 'ttb',
                    child: Text('من الأعلى إلى الأسفل (TTB)')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _settings.printDirection = v);
                  _autoSave();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrintMarginsSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('هوامش الطباعة',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.infoLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_settings.printMargins.toStringAsFixed(1)} مم',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.info,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('الهامش حول المحتوى على الملصق',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(LucideIcons.minus, size: 14, color: AppTheme.textSecondary),
            Expanded(
              child: Slider(
                value: _settings.printMargins,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                activeColor: AppTheme.info,
                inactiveColor: AppTheme.infoLight,
                label: '${_settings.printMargins.toStringAsFixed(1)} مم',
                onChanged: (v) {
                  setState(() => _settings.printMargins = v);
                  _autoSave();
                },
              ),
            ),
            const Icon(LucideIcons.plus, size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.buttonShadow,
        ),
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.save, size: 20),
          label: Text(
            _saving ? 'جارٍ الحفظ...' : 'حفظ الإعدادات',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}