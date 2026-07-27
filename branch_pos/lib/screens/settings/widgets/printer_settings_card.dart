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
      title: 'طابعة الفواتير الحرارية',
      subtitle: 'Thermal Receipt Printer',
      icon: LucideIcons.printer,
      iconColor: AppTheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر الطابعة المتصلة',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Printer>(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
              hintText: 'اختر الطابعة المتصلة',
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLighter,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.printer, color: AppTheme.primary, size: 18),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          const SizedBox(height: 16),
          // Status indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.selectedPrinter != null ? AppTheme.successLight : AppTheme.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  widget.selectedPrinter != null ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                  size: 18,
                  color: widget.selectedPrinter != null ? AppTheme.success : AppTheme.warning,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.selectedPrinter != null
                      ? 'الطابعة جاهزة: ${widget.selectedPrinter!.name}'
                      : 'لم يتم اختيار طابعة بعد',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.selectedPrinter != null ? AppTheme.success : AppTheme.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.selectedPrinter != null ? AppTheme.primaryGradient : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: widget.selectedPrinter != null ? AppTheme.buttonShadow : [],
              ),
              child: ElevatedButton.icon(
                onPressed: widget.selectedPrinter == null
                    ? null
                    : () => Printing.layoutPdf(
                        onLayout: (format) => widget.onGenerateTestPdf(format),
                      ),
                icon: const Icon(LucideIcons.play, size: 18),
                label: const Text('طباعة تجريبية', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.selectedPrinter != null ? Colors.transparent : Colors.grey.shade200,
                  foregroundColor: widget.selectedPrinter != null ? Colors.white : Colors.grey.shade500,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleCard() {
    return _buildHardwareCard(
      title: 'الميزان الإلكتروني',
      subtitle: 'Digital Scale',
      icon: LucideIcons.scale,
      iconColor: AppTheme.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر منفذ الميزان',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.accent, width: 2),
              ),
              hintText: 'اختر منفذ الميزان (COM)',
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.plug, color: AppTheme.accent, size: 18),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          const SizedBox(height: 16),
          // Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isScaleConnected ? AppTheme.successLight : AppTheme.errorLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isScaleConnected ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                  size: 18,
                  color: widget.isScaleConnected ? AppTheme.success : AppTheme.error,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.isScaleConnected ? 'الميزان متصل وجاهز' : 'الميزان غير متصل',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isScaleConnected ? AppTheme.success : AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.infoLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.info, size: 16, color: AppTheme.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تأكد من توصيل الميزان بمنفذ COM الصحيح',
                    style: TextStyle(fontSize: 12, color: AppTheme.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconColor.withOpacity(0.15), iconColor.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
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
