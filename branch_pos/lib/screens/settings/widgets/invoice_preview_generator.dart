import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../../../models/invoice_settings.dart';
import '../../../theme/app_theme.dart';

class InvoicePreviewGenerator {
  static Future<Uint8List> generateTestPdf(PdfPageFormat format) async {
    final font = await PdfGoogleFonts.tajawalRegular();
    final fontBold = await PdfGoogleFonts.tajawalBold();
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'Kiwi Fresh',
              style: pw.TextStyle(font: fontBold, fontSize: 22),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'سوق الخضار الطازج',
              style: pw.TextStyle(font: font, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'هاتف: 0770 123 4567',
              style: pw.TextStyle(font: font, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Text(
              '=== طباعة تجريبية ===',
              style: pw.TextStyle(font: fontBold, fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'إذا رأيت هذه الرسالة',
              style: pw.TextStyle(font: font, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'فالطابعة تعمل بشكل صحيح',
              style: pw.TextStyle(font: font, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Text(
              'Kiwi Fresh Branch POS v1.0',
              style: pw.TextStyle(font: font, fontSize: 8),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  static pw.Alignment _getAlignment(String alignment) {
    switch (alignment) {
      case 'right':
        return pw.Alignment.centerRight;
      case 'center':
      default:
        return pw.Alignment.center;
    }
  }

  static pw.TextAlign _getTextAlign(String alignment) {
    switch (alignment) {
      case 'right':
        return pw.TextAlign.right;
      case 'center':
      default:
        return pw.TextAlign.center;
    }
  }

  static Future<void> showInvoicePreview(BuildContext context, InvoiceSettings settings) async {
    final font = await PdfGoogleFonts.tajawalRegular();
    final fontBold = await PdfGoogleFonts.tajawalBold();
    final doc = pw.Document();

    final width = settings.pdfPageSize.width;
    final fontSizeMultiplier = settings.fontSize;
    final alignment = settings.alignment;

    pw.MemoryImage? logoImage;
    if (settings.logoPath != null) {
      try {
        final file = File(settings.logoPath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          logoImage = pw.MemoryImage(bytes);
        }
      } catch (_) {}
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width, double.infinity, marginAll: 6),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo
            if (logoImage != null)
              pw.Center(
                child: pw.Image(logoImage, height: 35 * fontSizeMultiplier),
              ),
            // Store name
            pw.Center(
              child: pw.Text(
                settings.storeName,
                style: pw.TextStyle(font: fontBold, fontSize: 18 * fontSizeMultiplier),
                textAlign: _getTextAlign(alignment),
              ),
            ),
            // Phone
            if (settings.storePhone.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  'هاتف: ${settings.storePhone}',
                  style: pw.TextStyle(font: font, fontSize: 9 * fontSizeMultiplier),
                  textAlign: _getTextAlign(alignment),
                ),
              ),
            // Address
            if (settings.storeAddress.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  settings.storeAddress,
                  style: pw.TextStyle(font: font, fontSize: 9 * fontSizeMultiplier),
                  textAlign: _getTextAlign(alignment),
                ),
              ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            // Column headers
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'الصنف',
                    style: pw.TextStyle(font: fontBold, fontSize: 9 * fontSizeMultiplier),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'الكمية',
                    style: pw.TextStyle(font: fontBold, fontSize: 9 * fontSizeMultiplier),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'السعر',
                    style: pw.TextStyle(font: fontBold, fontSize: 9 * fontSizeMultiplier),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'المجموع',
                    style: pw.TextStyle(font: fontBold, fontSize: 9 * fontSizeMultiplier),
                    textAlign: pw.TextAlign.left,
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 0.5),
            // Sample items
            _buildItemRow(font, fontBold, fontSizeMultiplier, 'طماطم طازجة', '2', '1,500', '3,000'),
            pw.SizedBox(height: 2),
            _buildItemRow(font, fontBold, fontSizeMultiplier, 'بصل أحمر', '5', '1,000', '5,000'),
            pw.SizedBox(height: 2),
            _buildItemRow(font, fontBold, fontSizeMultiplier, 'خيار بلدي', '3', '800', '2,400'),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            // Totals
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'المجموع الفرعي:',
                    style: pw.TextStyle(font: font, fontSize: 10 * fontSizeMultiplier),
                  ),
                ),
                pw.Text(
                  '10,400 د.ع',
                  style: pw.TextStyle(font: font, fontSize: 10 * fontSizeMultiplier),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'رسوم التوصيل:',
                    style: pw.TextStyle(font: font, fontSize: 10 * fontSizeMultiplier),
                  ),
                ),
                pw.Text(
                  '2,000 د.ع',
                  style: pw.TextStyle(font: font, fontSize: 10 * fontSizeMultiplier),
                ),
              ],
            ),
            pw.Divider(thickness: 0.5),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'الإجمالي:',
                    style: pw.TextStyle(font: fontBold, fontSize: 14 * fontSizeMultiplier),
                  ),
                ),
                pw.Text(
                  '12,400 د.ع',
                  style: pw.TextStyle(font: fontBold, fontSize: 14 * fontSizeMultiplier),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'طريقة الدفع: نقداً',
              style: pw.TextStyle(font: font, fontSize: 9 * fontSizeMultiplier),
            ),
            if (settings.showDate)
              pw.Text(
                'التاريخ: ${DateTime.now().toString().substring(0, 16)}',
                style: pw.TextStyle(font: font, fontSize: 8 * fontSizeMultiplier),
              ),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 6),
            // Footer
            pw.Center(
              child: pw.Text(
                settings.footerText,
                style: pw.TextStyle(font: fontBold, fontSize: 10 * fontSizeMultiplier),
                textAlign: _getTextAlign(alignment),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'شكراً لزيارتكم',
                style: pw.TextStyle(font: font, fontSize: 10 * fontSizeMultiplier),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    final pdfBytes = await doc.save();

    if (!context.mounted) return;

    // Show in-app PDF preview dialog
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.eye, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'معاينة الفاتورة',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              // PDF Preview
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: PdfPreview(
                    build: (format) => pdfBytes,
                    allowPrinting: true,
                    allowSharing: true,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    pdfFileName: 'معاينة_الفاتورة.pdf',
                    actions: [
                      PdfPreviewAction(
                        icon: const Icon(LucideIcons.printer, color: Colors.white),
                        onPressed: (context, buildPdf, format) async {
                          final bytes = await buildPdf(format);
                          await Printing.layoutPdf(onLayout: (format) => bytes);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildItemRow(
    pw.Font font,
    pw.Font fontBold,
    double fontSizeMultiplier,
    String name,
    String qty,
    String price,
    String total,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Text(
            name,
            style: pw.TextStyle(font: font, fontSize: 9 * fontSizeMultiplier),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Text(
            qty,
            style: pw.TextStyle(font: font, fontSize: 9 * fontSizeMultiplier),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            price,
            style: pw.TextStyle(font: font, fontSize: 9 * fontSizeMultiplier),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            '$total د.ع',
            style: pw.TextStyle(font: fontBold, fontSize: 9 * fontSizeMultiplier),
            textAlign: pw.TextAlign.left,
          ),
        ),
      ],
    );
  }
}
