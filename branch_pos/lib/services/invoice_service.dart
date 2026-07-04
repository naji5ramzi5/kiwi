import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice.dart';

class InvoiceService {
  static const _arabicFont = 'Tajawal';

  Future<Uint8List> generatePdf(Invoice invoice) async {
    final font = await PdfGoogleFonts.tajawalRegular();
    final fontBold = await PdfGoogleFonts.tajawalBold();

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.roll80,  // 80mm thermal receipt
        margin: const pw.EdgeInsets.all(8),
        build: (context) => [
          // Header
          pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('Fresh Market', style: pw.TextStyle(font: fontBold, fontSize: 20)),
                pw.Text(invoice.branchName, style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 4),
                pw.Text('رقم الفاتورة: ${invoice.id.substring(0, 8)}', style: pw.TextStyle(font: font, fontSize: 10)),
                pw.Text('التاريخ: ${_formatDate(invoice.createdAt)}', style: pw.TextStyle(font: font, fontSize: 10)),
                pw.Text('الكاشير: ${invoice.cashierName ?? "---"}', style: pw.TextStyle(font: font, fontSize: 10)),
                pw.Divider(thickness: 0.5),
              ],
            ),
          ),

          // Column headers
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('الصنف', style: pw.TextStyle(font: fontBold, fontSize: 10)),
              pw.Text('الكمية', style: pw.TextStyle(font: fontBold, fontSize: 10)),
              pw.Text('السعر', style: pw.TextStyle(font: fontBold, fontSize: 10)),
              pw.Text('المجموع', style: pw.TextStyle(font: fontBold, fontSize: 10)),
            ],
          ),
          pw.Divider(thickness: 0.5),

          // Items
          ...invoice.items.map((item) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(item.name, style: pw.TextStyle(font: font, fontSize: 9))),
              pw.Text('${item.quantity}', style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Text('${item.price.toStringAsFixed(0)}', style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Text('${item.total.toStringAsFixed(0)}', style: pw.TextStyle(font: font, fontSize: 9)),
            ],
          )),

          pw.Divider(thickness: 0.5),

          // Totals
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('المجموع الفرعي:', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text('${invoice.subtotal.toStringAsFixed(0)} د.ع', style: pw.TextStyle(font: font, fontSize: 10)),
            ],
          ),
          if (invoice.discount > 0) pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('الخصم:', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text('-${invoice.discount.toStringAsFixed(0)} د.ع', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.red)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('الإجمالي:', style: pw.TextStyle(font: fontBold, fontSize: 14)),
              pw.Text('${invoice.total.toStringAsFixed(0)} د.ع', style: pw.TextStyle(font: fontBold, fontSize: 14)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('طريقة الدفع: ${invoice.paymentMethod}', style: pw.TextStyle(font: font, fontSize: 10)),

          pw.Divider(thickness: 0.5),
          pw.Center(child: pw.Text('شكراً لتسوقك مع Fresh!', style: pw.TextStyle(font: fontBold, fontSize: 10))),
          pw.Center(child: pw.Text('www.fresh.iq', style: pw.TextStyle(font: font, fontSize: 8))),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> printInvoice(Invoice invoice) async {
    final pdf = await generatePdf(invoice);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf,
      name: 'invoice_${invoice.id.substring(0, 8)}',
    );
  }

  Future<void> printDirect(Invoice invoice) async {
    final pdf = await generatePdf(invoice);
    final printer = await _getDefaultPrinter();
    if (printer == null) {
      Get.snackbar('خطأ', 'لم يتم العثور على طابعة');
      return;
    }
    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (format) async => pdf,
    );
  }

  Future<Printer?> _getDefaultPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrinterName = prefs.getString('thermal_printer_name');

    final printers = await Printing.listPrinters();
    if (printers.isNotEmpty) {
      if (savedPrinterName != null) {
        final matching = printers.where((p) => p.name == savedPrinterName);
        if (matching.isNotEmpty) return matching.first;
      }

      // Prefer a thermal printer if available
      final thermal = printers.where((p) =>
          p.name.toLowerCase().contains('thermal') ||
          p.name.toLowerCase().contains('pos') ||
          p.name.toLowerCase().contains('epson')).toList();
      return thermal.isNotEmpty ? thermal.first : printers.first;
    }
    return null;
  }

  Future<void> showPreview(BuildContext context, Invoice invoice) async {
    final pdf = await generatePdf(invoice);
    await Printing.sharePdf(
      bytes: pdf,
      filename: 'invoice_${invoice.id.substring(0, 8)}.pdf',
    );
  }

  Future<void> reprint(Invoice invoice) async {
    await printInvoice(invoice);
  }

  String _formatDate(DateTime dt) {
    final months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
