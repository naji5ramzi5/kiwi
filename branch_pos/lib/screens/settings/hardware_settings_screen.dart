import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../models/invoice_settings.dart';
import '../../models/barcode_settings.dart';
import 'widgets/printer_settings_card.dart';
import 'widgets/barcode_printer_card.dart';
import 'widgets/invoice_preview_generator.dart';
import 'widgets/receipt_preview_widget.dart';

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

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scanDevices();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _storeNameController.dispose();
    _storePhoneController.dispose();
    _storeAddressController.dispose();
    _footerTextController.dispose();
    super.dispose();
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

  void _autoSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _invoiceSettings.storeName = _storeNameController.text.trim();
      _invoiceSettings.storePhone = _storePhoneController.text.trim();
      _invoiceSettings.storeAddress = _storeAddressController.text.trim();
      _invoiceSettings.footerText = _footerTextController.text.trim();
      _invoiceSettings.save();
    });
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
      if (matching.isNotEmpty) setState(() => _selectedPrinter = matching.first);
    }
    if (savedBarcodePrinterName != null && printers.isNotEmpty) {
      final matching = printers.where((p) => p.name == savedBarcodePrinterName);
      if (matching.isNotEmpty) setState(() => _selectedBarcodePrinter = matching.first);
    }
    if (savedPort != null && _availablePorts.contains(savedPort)) {
      setState(() => _selectedPort = savedPort);
    }
  }

  void _resetToDefaults() {
    setState(() {
      _invoiceSettings = InvoiceSettings();
      _storeNameController.text = _invoiceSettings.storeName;
      _storePhoneController.text = '';
      _storeAddressController.text = '';
      _footerTextController.text = _invoiceSettings.footerText;
    });
    _autoSave();
    Get.snackbar('تم', 'تمت استعادة الإعدادات الافتراضية', snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),
            // Main content: Left preview + Right settings
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT: Receipt Preview
                  Expanded(
                    flex: 2,
                    child: _settingsLoaded
                        ? ReceiptPreviewWidget(settings: _invoiceSettings)
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  const SizedBox(width: 24),
                  // RIGHT: Settings
                  Expanded(
                    flex: 3,
                    child: _settingsLoaded
                        ? _buildSettingsPanel()
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          child: const Icon(LucideIcons.settings, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إعدادات الطباعة الحرارية',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryDarker),
            ),
            const SizedBox(height: 2),
            Text(
              'تخصيص الفاتورة وإعدادات الطابعة — التحديث لحظي',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
        const Spacer(),
        // Reset button
        Container(
          decoration: BoxDecoration(
            color: AppTheme.errorLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(LucideIcons.rotateCcw, size: 18, color: AppTheme.error),
            tooltip: 'استعادة الإعدادات الافتراضية',
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Section 1: Identity
          _buildSectionCard(
            title: 'هوية المتجر',
            subtitle: 'الشعار والمعلومات الأساسية',
            icon: LucideIcons.store,
            iconColor: AppTheme.primary,
            child: Column(
              children: [
                _buildLogoPicker(),
                const SizedBox(height: 16),
                _buildTextField('اسم المتجر', _storeNameController, LucideIcons.store),
                const SizedBox(height: 12),
                _buildTextField('رقم الهاتف', _storePhoneController, LucideIcons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildTextField('عنوان الفرع', _storeAddressController, LucideIcons.mapPin),
              ],
            ),
          ),

          // Section 2: Font
          _buildSectionCard(
            title: 'إعدادات الخط',
            subtitle: 'حجم ونوع الخط',
            icon: LucideIcons.type,
            iconColor: AppTheme.info,
            child: Column(
              children: [
                _buildFontSizeSlider(),
                const SizedBox(height: 16),
                _buildFontScalePreview(),
              ],
            ),
          ),

          // Section 3: Paper
          _buildSectionCard(
            title: 'حجم ورق الطباعة',
            subtitle: 'اختر حجم الورق الخاص بطابعتك',
            icon: LucideIcons.maximize2,
            iconColor: AppTheme.warning,
            child: _buildPaperSizeSelector(),
          ),

          // Section 4: Display options
          _buildSectionCard(
            title: 'المعلومات الظاهرة',
            subtitle: 'اختر ما يظهر في الفاتورة',
            icon: LucideIcons.eye,
            iconColor: AppTheme.secondary,
            child: Column(
              children: [
                _buildToggleRow('إظهار بيانات العميل', _invoiceSettings.showCustomerInfo, (v) {
                  setState(() => _invoiceSettings.showCustomerInfo = v);
                  _autoSave();
                }),
                _buildToggleRow('إظهار التاريخ والوقت', _invoiceSettings.showDate, (v) {
                  setState(() => _invoiceSettings.showDate = v);
                  _autoSave();
                }),
                _buildToggleRow('إظهار الباركود', _invoiceSettings.showBarcode, (v) {
                  setState(() => _invoiceSettings.showBarcode = v);
                  _autoSave();
                }),
              ],
            ),
          ),

          // Section 5: Footer
          _buildSectionCard(
            title: 'تذييل الفاتورة',
            subtitle: 'رسالة شكر مخصصة',
            icon: LucideIcons.quote,
            iconColor: AppTheme.accent,
            child: _buildTextField('نص التذييل', _footerTextController, LucideIcons.messageSquare),
          ),

          // Section 6: Printer connection
          _buildSectionCard(
            title: 'إعدادات الطابعة',
            subtitle: 'توصيل واختبار الطابعة',
            icon: LucideIcons.printer,
            iconColor: AppTheme.primary,
            child: Column(
              children: [
                _buildPrinterDropdown(),
                const SizedBox(height: 16),
                _buildPrinterStatus(),
                const SizedBox(height: 16),
                _buildTestPrintButton(),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: 16),
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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

  Widget _buildLogoPicker() {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(type: FileType.image);
            if (result != null && result.files.single.path != null) {
              setState(() => _invoiceSettings.logoPath = result.files.single.path);
              _autoSave();
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _invoiceSettings.logoPath != null ? AppTheme.primary : Colors.grey.shade200,
                width: 2,
              ),
            ),
            child: _invoiceSettings.logoPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(_invoiceSettings.logoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
                    ),
                  )
                : _buildLogoPlaceholder(),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _invoiceSettings.logoPath != null ? 'تم تحميل الشعار' : 'اضغط لاختيار شعار',
              style: TextStyle(
                fontSize: 13,
                color: _invoiceSettings.logoPath != null ? AppTheme.success : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_invoiceSettings.logoPath != null)
              TextButton(
                onPressed: () {
                  setState(() => _invoiceSettings.logoPath = null);
                  _autoSave();
                },
                child: const Text('إزالة الشعار', style: TextStyle(color: AppTheme.error, fontSize: 12)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.image, color: Colors.grey.shade400, size: 24),
        const SizedBox(height: 4),
        Text('شعار', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (_) => _autoSave(),
          style: const TextStyle(fontSize: 14),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('حجم الخط', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(_invoiceSettings.fontSize * 100).round()}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(LucideIcons.minus, size: 16, color: AppTheme.textSecondary),
            Expanded(
              child: Slider(
                value: _invoiceSettings.fontSize,
                min: 0.7,
                max: 1.5,
                divisions: 8,
                activeColor: AppTheme.primary,
                inactiveColor: AppTheme.primaryLighter,
                onChanged: (v) {
                  setState(() => _invoiceSettings.fontSize = v);
                  _autoSave();
                },
              ),
            ),
            const Icon(LucideIcons.plus, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ],
    );
  }

  Widget _buildFontScalePreview() {
    final fs = _invoiceSettings.fontSize;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('معاينة حجم الخط', style: TextStyle(fontSize: 10 * fs, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text('اسم المتجر', style: TextStyle(fontSize: 18 * fs, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('تفاح ×2 — 10,000 د.ع', style: TextStyle(fontSize: 10 * fs)),
          const SizedBox(height: 4),
          Text('الإجمالي: 25,000 د.ع', style: TextStyle(fontSize: 13 * fs, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaperSizeSelector() {
    return Row(
      children: [
        _buildPaperOption('58mm', '58 مم (صغير)', LucideIcons.minimize2, AppTheme.warning),
        const SizedBox(width: 12),
        _buildPaperOption('80mm', '80 مم (قياسي)', LucideIcons.maximize2, AppTheme.primary),
      ],
    );
  }

  Widget _buildPaperOption(String value, String label, IconData icon, Color color) {
    final isSelected = _invoiceSettings.paperSize == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _invoiceSettings.paperSize = value);
          _autoSave();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.08) : AppTheme.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : AppTheme.textSecondary, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Switch(
              value: value,
              activeColor: AppTheme.primary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اختر الطابعة المتصلة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Printer>(
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
            hintText: 'اختر الطابعة',
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
      ],
    );
  }

  Widget _buildPrinterStatus() {
    final isReady = _selectedPrinter != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isReady ? AppTheme.successLight : AppTheme.warningLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isReady ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
            color: isReady ? AppTheme.success : AppTheme.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReady ? 'الطابعة جاهزة' : 'لم يتم اختيار طابعة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isReady ? AppTheme.success : AppTheme.warning,
                  ),
                ),
                if (isReady)
                  Text(
                    _selectedPrinter!.name,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestPrintButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          gradient: _selectedPrinter != null ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _selectedPrinter != null ? AppTheme.buttonShadow : [],
        ),
        child: ElevatedButton.icon(
          onPressed: _selectedPrinter == null
              ? null
              : () => Printing.layoutPdf(
                  onLayout: (format) => InvoicePreviewGenerator.generateTestPdf(format),
                ),
          icon: const Icon(LucideIcons.play, size: 18),
          label: const Text('طباعة تجريبية', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedPrinter != null ? Colors.transparent : Colors.grey.shade200,
            foregroundColor: _selectedPrinter != null ? Colors.white : Colors.grey.shade500,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
