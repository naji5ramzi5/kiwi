import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';

class PrinterSettingsCard extends StatefulWidget {
  final Printer? selectedPrinter;
  final List<Printer> availablePrinters;
  final String? selectedPort;
  final List<String> availablePorts;
  final bool isScaleConnected;
  final ValueChanged<Printer?> onPrinterChanged;
  final ValueChanged<String?> onPortChanged;
  final Future<Uint8List> Function(PdfPageFormat) onGenerateTestPdf;

  const PrinterSettingsCard({
    super.key,
    required this.selectedPrinter,
    required this.availablePrinters,
    required this.selectedPort,
    required this.availablePorts,
    required this.isScaleConnected,
    required this.onPrinterChanged,
    required this.onPortChanged,
    required this.onGenerateTestPdf,
  });

  @override
  State<PrinterSettingsCard> createState() => _PrinterSettingsCardState();
}

class _PrinterSettingsCardState extends State<PrinterSettingsCard> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPrinterCard()),
        const SizedBox(width: 24),
        Expanded(child: _buildScaleCard()),
      ],
    );
  }

  Widget _buildPrinterCard() {
    return _buildHardwareCard(
      title: 'طابعة الفواتير (Thermal Printer)',
      icon: LucideIcons.printer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<Printer>(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: 'اختر الطابعة المتصلة',
            ),
            value: widget.selectedPrinter,
            items: widget.availablePrinters
                .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                .toList(),
            onChanged: (v) async {
              widget.onPrinterChanged(v);
              if (v != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('thermal_printer_name', v.name);
              }
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: widget.selectedPrinter == null
                ? null
                : () => Printing.layoutPdf(
                    onLayout: (format) => widget.onGenerateTestPdf(format),
                  ),
            icon: const Icon(LucideIcons.play),
            label: const Text('طباعة تجريبية'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleCard() {
    return _buildHardwareCard(
      title: 'الميزان الإلكتروني (Digital Scale)',
      icon: LucideIcons.scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: 'اختر منفذ الميزان (COM)',
            ),
            value: widget.selectedPort,
            items: widget.availablePorts
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) async {
              widget.onPortChanged(v);
              if (v != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('scale_port', v);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                widget.isScaleConnected
                    ? LucideIcons.checkCircle2
                    : LucideIcons.xCircle,
                color: widget.isScaleConnected ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isScaleConnected ? 'الميزان متصل' : 'الميزان غير متصل',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.isScaleConnected ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Icon(icon, color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
