import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../models/barcode_settings.dart';

class BarcodePrinterCard extends StatefulWidget {
  final BarcodeSettings settings;
  final List<Printer> availablePrinters;
  final Printer? selectedBarcodePrinter;
  final ValueChanged<Printer?> onPrinterChanged;
  final ValueChanged<String?> onPaperWidthChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<bool> onShowProductNameChanged;
  final ValueChanged<bool> onShowPriceChanged;
  final ValueChanged<bool> onShowBarcodeChanged;
  final ValueChanged<bool> onShowBranchNameChanged;
  final ValueChanged<int> onCopiesChanged;
  final VoidCallback onSave;

  const BarcodePrinterCard({
    super.key,
    required this.settings,
    required this.availablePrinters,
    required this.selectedBarcodePrinter,
    required this.onPrinterChanged,
    required this.onPaperWidthChanged,
    required this.onFontSizeChanged,
    required this.onShowProductNameChanged,
    required this.onShowPriceChanged,
    required this.onShowBarcodeChanged,
    required this.onShowBranchNameChanged,
    required this.onCopiesChanged,
    required this.onSave,
  });

  @override
  State<BarcodePrinterCard> createState() => _BarcodePrinterCardState();
}

class _BarcodePrinterCardState extends State<BarcodePrinterCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.qrCode,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'طابعة الملصقات والباركود',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'إعدادات طابعة الملصقات وتصميم ملصقات الباركود',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 28),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPrinterSelection()),
              const SizedBox(width: 24),
              Expanded(child: _buildPaperSettings()),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDisplayOptions()),
              const SizedBox(width: 24),
              Expanded(child: _buildLabelPreview()),
            ],
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: widget.selectedBarcodePrinter == null
                    ? null
                    : _printTestLabel,
                icon: const Icon(LucideIcons.play),
                label: const Text('طباعة تجريبية'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: widget.onSave,
                icon: const Icon(LucideIcons.save),
                label: const Text('حفظ الإعدادات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'طابعة الملصقات',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Printer>(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: 'اختر طابعة الملصقات',
            prefixIcon: const Icon(
              LucideIcons.printer,
              color: Colors.orange,
              size: 18,
            ),
          ),
          value: widget.selectedBarcodePrinter,
          items: widget.availablePrinters
              .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
              .toList(),
          onChanged: widget.onPrinterChanged,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'عدد النسخ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.minus, size: 16),
                    onPressed: widget.settings.copies > 1
                        ? () => widget.onCopiesChanged(widget.settings.copies - 1)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${widget.settings.copies}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.plus, size: 16),
                    onPressed: widget.settings.copies < 10
                        ? () => widget.onCopiesChanged(widget.settings.copies + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaperSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'حجم ملصق الباركود',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: widget.settings.paperWidth,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(
              LucideIcons.maximize2,
              color: Colors.orange,
              size: 18,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: '50x30mm',
              child: Text('50 × 30 مم'),
            ),
            DropdownMenuItem(
              value: '40x30mm',
              child: Text('40 × 30 مم'),
            ),
            DropdownMenuItem(
              value: '60x40mm',
              child: Text('60 × 40 مم'),
            ),
            DropdownMenuItem(
              value: '70x50mm',
              child: Text('70 × 50 مم'),
            ),
          ],
          onChanged: widget.onPaperWidthChanged,
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'حجم الخط',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.minus, size: 14, color: AppTheme.textSecondary),
                Expanded(
                  child: Slider(
                    value: widget.settings.fontSize,
                    min: 0.7,
                    max: 1.5,
                    divisions: 8,
                    activeColor: Colors.orange,
                    label: '${(widget.settings.fontSize * 100).round()}%',
                    onChanged: widget.onFontSizeChanged,
                  ),
                ),
                const Icon(LucideIcons.plus, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${(widget.settings.fontSize * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisplayOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'محتوى الملصق',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildToggleOption(
          'اسم المنتج',
          widget.settings.showProductName,
          widget.onShowProductNameChanged,
        ),
        const SizedBox(height: 8),
        _buildToggleOption(
          'السعر',
          widget.settings.showPrice,
          widget.onShowPriceChanged,
        ),
        const SizedBox(height: 8),
        _buildToggleOption(
          'رقم الباركود',
          widget.settings.showBarcode,
          widget.onShowBarcodeChanged,
        ),
        const SizedBox(height: 8),
        _buildToggleOption(
          'اسم الفرع',
          widget.settings.showBranchName,
          widget.onShowBranchNameChanged,
        ),
      ],
    );
  }

  Widget _buildToggleOption(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.orange,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLabelPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'معاينة الملصق',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textSecondary.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              if (widget.settings.showProductName)
                Text(
                  'طماطم طازجة',
                  style: TextStyle(
                    fontSize: 14 * widget.settings.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (widget.settings.showBranchName)
                Text(
                  'فرع بغداد الرئيسي',
                  style: TextStyle(
                    fontSize: 10 * widget.settings.fontSize,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (widget.settings.showBarcode)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: const Icon(
                    LucideIcons.qrCode,
                    size: 40,
                    color: Colors.black87,
                  ),
                ),
              if (widget.settings.showPrice)
                Text(
                  '2,500 د.ع',
                  style: TextStyle(
                    fontSize: 16 * widget.settings.fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 4),
              Text(
                '001234567890',
                style: TextStyle(
                  fontSize: 10 * widget.settings.fontSize,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _printTestLabel() async {
    final font = await PdfGoogleFonts.tajawalRegular();
    final fontBold = await PdfGoogleFonts.tajawalBold();
    final doc = pw.Document();

    final size = _getPaperSize();
    final fs = widget.settings.fontSize;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(size[0], size[1], marginAll: 4),
        build: (context) => pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (widget.settings.showProductName)
              pw.Text(
                'طماطم طازجة',
                style: pw.TextStyle(font: fontBold, fontSize: 14 * fs),
                textAlign: pw.TextAlign.center,
              ),
            if (widget.settings.showBranchName)
              pw.Text(
                'فرع بغداد الرئيسي',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10 * fs,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
            if (widget.settings.showBarcode)
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: '001234567890',
                width: 60 * fs,
                height: 20 * fs,
              ),
            if (widget.settings.showPrice)
              pw.Text(
                '2,500 د.ع',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 16 * fs,
                  color: PdfColors.orange800,
                ),
                textAlign: pw.TextAlign.center,
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
    switch (widget.settings.paperWidth) {
      case '40x30mm':
        return [40, 30];
      case '60x40mm':
        return [60, 40];
      case '70x50mm':
        return [70, 50];
      case '50x30mm':
      default:
        return [50, 30];
    }
  }
}
