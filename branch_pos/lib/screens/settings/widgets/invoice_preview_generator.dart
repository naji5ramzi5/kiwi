import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../../../models/invoice_settings.dart';

class InvoicePreviewGenerator {
  static Future<Uint8List> generateTestPdf(PdfPageFormat format) async {
    final font = await PdfGoogleFonts.tajawalRegular();
    final fontBold = await PdfGoogleFonts.tajawalBold();
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Fresh POS',
                style: pw.TextStyle(font: fontBold, fontSize: 20),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'طباعة تجريبية',
                style: pw.TextStyle(font: font, fontSize: 14),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'إذا رأيت هذه الرسالة فالطابعة تعمل بشكل صحيح',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Fresh Branch POS v1.0',
                style: pw.TextStyle(font: font, fontSize: 8),
              ),
            ],
          ),
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

  static Future<void> showInvoicePreview(InvoiceSettings settings) async {
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
        pageFormat: PdfPageFormat(width, 200, marginAll: 8),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Center(
                child: pw.Image(logoImage, height: 40 * fontSizeMultiplier),
              ),
            pw.Center(
              child: pw.Text(
                settings.storeName,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 16 * fontSizeMultiplier,
                ),
                textAlign: _getTextAlign(alignment),
              ),
            ),
            if (settings.storePhone.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  'هاتف: ${settings.storePhone}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                  textAlign: _getTextAlign(alignment),
                ),
              ),
            if (settings.storeAddress.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  settings.storeAddress,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                  textAlign: _getTextAlign(alignment),
                ),
              ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'الصنف',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                ),
                pw.Text(
                  'الكمية',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                ),
                pw.Text(
                  'السعر',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                ),
                pw.Text(
                  'المجموع',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'طماطم',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                ),
                pw.Text(
                  '2',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                ),
                pw.Text(
                  '1500',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                ),
                pw.Text(
                  '3000',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'بصل',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                ),
                pw.Text(
                  '5',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                ),
                pw.Text(
                  '1000',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                ),
                pw.Text(
                  '5000',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9 * fontSizeMultiplier,
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'الإجمالي:',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12 * fontSizeMultiplier,
                  ),
                ),
                pw.Text(
                  '8000 د.ع',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12 * fontSizeMultiplier,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'طريقة الدفع: نقداً',
              style: pw.TextStyle(
                font: font,
                fontSize: 9 * fontSizeMultiplier,
              ),
            ),
            if (settings.showDate)
              pw.Text(
                'التاريخ: ${DateTime.now().toString().substring(0, 16)}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8 * fontSizeMultiplier,
                ),
              ),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                settings.footerText,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10 * fontSizeMultiplier,
                ),
                textAlign: _getTextAlign(alignment),
              ),
            ),
          ],
        ),
      ),
    );

    final pdfBytes = await doc.save();
    await Printing.sharePdf(bytes: pdfBytes, filename: 'معاينة_الفاتورة.pdf');
  }
}
