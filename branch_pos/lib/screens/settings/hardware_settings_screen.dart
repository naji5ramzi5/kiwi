import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:printing/printing.dart';
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
      _availablePorts = SerialPort.availablePorts;
    });
    
    final printers = await Printing.listPrinters();
    setState(() {
      _availablePrinters = printers;
    });
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
                          onChanged: (v) => setState(() => _selectedPrinter = v),
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
                          onChanged: (v) => setState(() => _selectedPort = v),
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

  Future<Uint8List> _generateTestPdf(dynamic format) async {
    // Basic test PDF generation
    return Uint8List.fromList([]);
  }
}
