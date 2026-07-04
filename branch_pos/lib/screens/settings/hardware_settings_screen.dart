import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
// import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import '../../theme/app_theme.dart';

class HardwareSettingsScreen extends StatefulWidget {
  const HardwareSettingsScreen({super.key});

  @override
  State<HardwareSettingsScreen> createState() => _HardwareSettingsScreenState();
}

class _HardwareSettingsScreenState extends State<HardwareSettingsScreen> {
  List<String> _availablePorts = [];
  List<Printer> _availablePrinters = [];
  
  String? _selectedPort;
  Printer? _selectedPrinter;
  
  bool _isScaleConnected = false;

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    setState(() {
      _availablePorts = ['COM1', 'COM2', 'COM3', 'COM4']; // Mocked available ports to bypass native compile errors
    });
    
    final printers = await Printing.listPrinters();
    setState(() {
      _availablePrinters = printers;
    });

    final prefs = await SharedPreferences.getInstance();
    final savedPrinterName = prefs.getString('thermal_printer_name');
    final savedPort = prefs.getString('scale_port');

    if (savedPrinterName != null && printers.isNotEmpty) {
      final matching = printers.where((p) => p.name == savedPrinterName);
      if (matching.isNotEmpty) {
        setState(() {
          _selectedPrinter = matching.first;
        });
      }
    }

    if (savedPort != null && _availablePorts.contains(savedPort)) {
      setState(() {
        _selectedPort = savedPort;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إعدادات الأجهزة والمعدات', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryDark)),
            const SizedBox(height: 10),
            const Text('قم بربط الميزان وطابعة الفواتير وقارئ الباركود', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 40),
            
            Expanded(
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                children: [
                  _buildHardwareCard(
                    title: 'طابعة الفواتير (Thermal Printer)',
                    icon: LucideIcons.printer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<Printer>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            hintText: 'اختر الطابعة المتصلة',
                          ),
                          value: _selectedPrinter,
                          items: _availablePrinters.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                          onChanged: (v) async {
                            setState(() => _selectedPrinter = v);
                            if (v != null) {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('thermal_printer_name', v.name);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _selectedPrinter == null ? null : () => Printing.layoutPdf(onLayout: (format) => _generateTestPdf(format)),
                          icon: const Icon(LucideIcons.play),
                          label: const Text('طباعة تجريبية'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        )
                      ],
                    ),
                  ),
                  _buildHardwareCard(
                    title: 'الميزان الإلكتروني (Digital Scale)',
                    icon: LucideIcons.scale,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            hintText: 'اختر منفذ الميزان (COM)',
                          ),
                          value: _selectedPort,
                          items: _availablePorts.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (v) async {
                            setState(() => _selectedPort = v);
                            if (v != null) {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('scale_port', v);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(_isScaleConnected ? LucideIcons.checkCircle2 : LucideIcons.xCircle, color: _isScaleConnected ? Colors.green : Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Text(_isScaleConnected ? 'الميزان متصل' : 'الميزان غير متصل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isScaleConnected ? Colors.green : Colors.red)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Future<Uint8List> _generateTestPdf(PdfPageFormat format) async {
    final font = await PdfGoogleFonts.tajawalRegular();
    final fontBold = await PdfGoogleFonts.tajawalBold();
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (context) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text('Fresh POS', style: pw.TextStyle(font: fontBold, fontSize: 20)),
            pw.SizedBox(height: 8),
            pw.Text('طباعة تجريبية', style: pw.TextStyle(font: font, fontSize: 14)),
            pw.SizedBox(height: 4),
            pw.Text('إذا رأيت هذه الرسالة فالطابعة تعمل بشكل صحيح', style: pw.TextStyle(font: font, fontSize: 10)),
            pw.SizedBox(height: 20),
            pw.Text('Fresh Branch POS v1.0', style: pw.TextStyle(font: font, fontSize: 8)),
          ],
        ),
      ),
    ));
    return doc.save();
  }
}
