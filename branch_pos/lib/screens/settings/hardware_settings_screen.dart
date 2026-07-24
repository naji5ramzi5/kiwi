import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../models/invoice_settings.dart';
import '../../models/barcode_settings.dart';
import 'widgets/printer_settings_card.dart';
import 'widgets/invoice_design_card.dart';
import 'widgets/barcode_printer_card.dart';
import 'widgets/invoice_preview_generator.dart';

class HardwareSettingsScreen extends StatefulWidget {
  const HardwareSettingsScreen({super.key});

  @override
  State<HardwareSettingsScreen> createState() => _HardwareSettingsScreenState();
}

class _HardwareSettingsScreenState extends State<HardwareSettingsScreen> {
  List<String> _availablePorts = [];
  List<Printer> _availablePrinters = [];
  Printer? _selectedPrinter;
  Printer? _selectedBarcodePrinter;
  String? _selectedPort;
  bool _isScaleConnected = false;

  late InvoiceSettings _invoiceSettings;
  late BarcodeSettings _barcodeSettings;
  bool _settingsLoaded = false;

  final _storeNameController = TextEditingController();
  final _storePhoneController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _footerTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scanDevices();
  }

  Future<void> _loadSettings() async {
    _invoiceSettings = await InvoiceSettings.load();
    _barcodeSettings = await BarcodeSettings.load();
    _storeNameController.text = _invoiceSettings.storeName;
    _storePhoneController.text = _invoiceSettings.storePhone;
    _storeAddressController.text = _invoiceSettings.storeAddress;
    _footerTextController.text = _invoiceSettings.footerText;
    setState(() => _settingsLoaded = true);
  }

  Future<void> _saveInvoiceSettings() async {
    _invoiceSettings.storeName = _storeNameController.text.trim();
    _invoiceSettings.storePhone = _storePhoneController.text.trim();
    _invoiceSettings.storeAddress = _storeAddressController.text.trim();
    _invoiceSettings.footerText = _footerTextController.text.trim();
    await _invoiceSettings.save();
    if (mounted) {
      Get.snackbar(
        'تم الحفظ',
        'تم حفظ إعدادات الفاتورة بنجاح',
        backgroundColor: AppTheme.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _saveBarcodeSettings() async {
    await _barcodeSettings.save();
    if (mounted) {
      Get.snackbar(
        'تم الحفظ',
        'تم حفظ إعدادات طابعة الملصقات بنجاح',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _scanDevices() async {
    setState(() => _availablePorts = ['COM1', 'COM2', 'COM3', 'COM4']);

    final printers = await Printing.listPrinters();
    setState(() => _availablePrinters = printers);

    final prefs = await SharedPreferences.getInstance();
    final savedPrinterName = prefs.getString('thermal_printer_name');
    final savedBarcodePrinterName = prefs.getString('barcode_printer_name');
    final savedPort = prefs.getString('scale_port');

    if (savedPrinterName != null && printers.isNotEmpty) {
      final matching = printers.where((p) => p.name == savedPrinterName);
      if (matching.isNotEmpty) {
        setState(() => _selectedPrinter = matching.first);
      }
    }

    if (savedBarcodePrinterName != null && printers.isNotEmpty) {
      final matching = printers.where((p) => p.name == savedBarcodePrinterName);
      if (matching.isNotEmpty) {
        setState(() => _selectedBarcodePrinter = matching.first);
      }
    }

    if (savedPort != null && _availablePorts.contains(savedPort)) {
      setState(() => _selectedPort = savedPort);
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storePhoneController.dispose();
    _storeAddressController.dispose();
    _footerTextController.dispose();
    super.dispose();
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
            const Text(
              'إعدادات الأجهزة والفاتورة',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'إعدادات الطابعة، الميزان، تصميم الفاتورة، وطابعة الملصقات',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 40),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    PrinterSettingsCard(
                      selectedPrinter: _selectedPrinter,
                      availablePrinters: _availablePrinters,
                      selectedPort: _selectedPort,
                      availablePorts: _availablePorts,
                      isScaleConnected: _isScaleConnected,
                      onPrinterChanged: (v) =>
                          setState(() => _selectedPrinter = v),
                      onPortChanged: (v) => setState(() => _selectedPort = v),
                      onGenerateTestPdf:
                          InvoicePreviewGenerator.generateTestPdf,
                    ),
                    const SizedBox(height: 24),
                    InvoiceDesignCard(
                      settings: _invoiceSettings,
                      settingsLoaded: _settingsLoaded,
                      storeNameController: _storeNameController,
                      storePhoneController: _storePhoneController,
                      storeAddressController: _storeAddressController,
                      footerTextController: _footerTextController,
                      onPreview: () =>
                          InvoicePreviewGenerator.showInvoicePreview(
                            _invoiceSettings,
                          ),
                      onSave: _saveInvoiceSettings,
                      onPaperSizeChanged: (v) {
                        if (v != null)
                          setState(() => _invoiceSettings.paperSize = v);
                      },
                      onShowCustomerInfoChanged: (v) =>
                          setState(() => _invoiceSettings.showCustomerInfo = v),
                      onLogoChanged: (v) =>
                          setState(() => _invoiceSettings.logoPath = v),
                      onFontSizeChanged: (v) =>
                          setState(() => _invoiceSettings.fontSize = v),
                      onAlignmentChanged: (v) {
                        if (v != null)
                          setState(() => _invoiceSettings.alignment = v);
                      },
                      onShowBarcodeChanged: (v) =>
                          setState(() => _invoiceSettings.showBarcode = v),
                      onShowDateChanged: (v) =>
                          setState(() => _invoiceSettings.showDate = v),
                    ),
                    const SizedBox(height: 24),
                    BarcodePrinterCard(
                      settings: _barcodeSettings,
                      availablePrinters: _availablePrinters,
                      selectedBarcodePrinter: _selectedBarcodePrinter,
                      onPrinterChanged: (v) {
                        setState(() => _selectedBarcodePrinter = v);
                        if (v != null) {
                          SharedPreferences.getInstance().then((prefs) {
                            prefs.setString('barcode_printer_name', v.name);
                          });
                        }
                      },
                      onPaperWidthChanged: (v) {
                        if (v != null)
                          setState(() => _barcodeSettings.paperWidth = v);
                      },
                      onFontSizeChanged: (v) =>
                          setState(() => _barcodeSettings.fontSize = v),
                      onShowProductNameChanged: (v) =>
                          setState(() => _barcodeSettings.showProductName = v),
                      onShowPriceChanged: (v) =>
                          setState(() => _barcodeSettings.showPrice = v),
                      onShowBarcodeChanged: (v) =>
                          setState(() => _barcodeSettings.showBarcode = v),
                      onShowBranchNameChanged: (v) =>
                          setState(() => _barcodeSettings.showBranchName = v),
                      onCopiesChanged: (v) =>
                          setState(() => _barcodeSettings.copies = v),
                      onSave: _saveBarcodeSettings,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
