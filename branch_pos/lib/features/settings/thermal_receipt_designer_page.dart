import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/invoice_settings.dart';
import '../../theme/app_theme.dart';

class ThermalReceiptDesignerPage extends StatefulWidget {
  const ThermalReceiptDesignerPage({super.key});

  @override
  State<ThermalReceiptDesignerPage> createState() =>
      _ThermalReceiptDesignerPageState();
}

class _ThermalReceiptDesignerPageState
    extends State<ThermalReceiptDesignerPage> {
  InvoiceSettings _settings = InvoiceSettings();
  bool _isLoading = true;
  Timer? _debounceTimer;

  // Extra design fields not in InvoiceSettings
  bool _showLogo = true;
  bool _showCashierName = true;
  bool _showTaxNumber = true;
  bool _showQRCode = false;
  String _fontFamily = 'Noto Sans Arabic';
  Color _receiptBgColor = Colors.white;

  final TextEditingController _footerController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storePhoneController = TextEditingController();
  final TextEditingController _storeAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await InvoiceSettings.load();
    setState(() {
      _settings = settings;
      _footerController.text = settings.footerText;
      _storeNameController.text = settings.storeName;
      _storePhoneController.text = settings.storePhone;
      _storeAddressController.text = settings.storeAddress;
      _isLoading = false;
    });
  }

  void _onChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _settings.save();
    });
    setState(() {});
  }

  void _resetToDefaults() {
    final defaults = InvoiceSettings();
    setState(() {
      _settings = defaults;
      _showLogo = true;
      _showCashierName = true;
      _showTaxNumber = true;
      _showQRCode = false;
      _fontFamily = 'Noto Sans Arabic';
      _receiptBgColor = Colors.white;
      _footerController.text = defaults.footerText;
      _storeNameController.text = defaults.storeName;
      _storePhoneController.text = defaults.storePhone;
      _storeAddressController.text = defaults.storeAddress;
    });
    _onChanged();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _footerController.dispose();
    _storeNameController.dispose();
    _storePhoneController.dispose();
    _storeAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('مصمم الإيصال الحراري'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Row(
        children: [
          Expanded(flex: 2, child: _buildPreviewSection()),
          const SizedBox(width: 1),
          Container(color: AppTheme.primaryLighter, width: 1),
          Expanded(flex: 3, child: _buildSettingsSection()),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LEFT SIDE — Live Receipt Preview
  // ---------------------------------------------------------------------------
  Widget _buildPreviewSection() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildReceiptPaper(),
        ),
      ),
    );
  }

  Widget _buildReceiptPaper() {
    final fs = _settings.fontSize;
    final isCenter = _settings.alignment == 'center';
    final align = isCenter ? TextAlign.center : TextAlign.right;

    return Container(
      width: 280,
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: _receiptBgColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dotted top edge
          Container(
            height: 8,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment:
                  isCenter ? CrossAxisAlignment.center : CrossAxisAlignment.end,
              children: [
                if (_showLogo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Icon(
                      Icons.storefront,
                      size: 36 * fs,
                      color: AppTheme.primary,
                    ),
                  ),
                _receiptLine(
                  _settings.storeName,
                  fontSize: 16 * fs,
                  fontWeight: FontWeight.w800,
                  align: align,
                ),
                if (_settings.storePhone.isNotEmpty)
                  _receiptLine(
                    _settings.storePhone,
                    fontSize: 11 * fs,
                    align: align,
                    color: Colors.grey.shade600,
                  ),
                if (_settings.storeAddress.isNotEmpty)
                  _receiptLine(
                    _settings.storeAddress,
                    fontSize: 11 * fs,
                    align: align,
                    color: Colors.grey.shade600,
                  ),
                const SizedBox(height: 8),
                _dashedDivider(),
                const SizedBox(height: 8),

                // Cashier
                if (_showCashierName)
                  _receiptLine(
                    'الكاشير: أحمد',
                    fontSize: 10 * fs,
                    align: align,
                    color: Colors.grey.shade600,
                  ),

                // Customer
                if (_settings.showCustomerInfo)
                  _receiptLine(
                    'العميل: محمد علي',
                    fontSize: 10 * fs,
                    align: align,
                    color: Colors.grey.shade600,
                  ),

                if (_showTaxNumber)
                  _receiptLine(
                    'الرقم الضريبي: 123456789',
                    fontSize: 9 * fs,
                    align: align,
                    color: Colors.grey.shade500,
                  ),

                const SizedBox(height: 8),
                _dashedDivider(),
                const SizedBox(height: 8),

                // Items header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _receiptLine('الصنف', fontSize: 10 * fs, fontWeight: FontWeight.bold),
                    _receiptLine('الكمية', fontSize: 10 * fs, fontWeight: FontWeight.bold),
                    _receiptLine('السعر', fontSize: 10 * fs, fontWeight: FontWeight.bold),
                  ],
                ),
                const SizedBox(height: 4),
                _dashedDivider(),
                const SizedBox(height: 4),

                // Sample items
                _buildItemRow('تفاح أحمر', '2 كجم', '4,000 د.ع', fs),
                _buildItemRow('موز', '1 كجم', '2,500 د.ع', fs),
                _buildItemRow('حليب طازج', '3 حبة', '6,750 د.ع', fs),
                _buildItemRow('خبز أبيض', '1 رغيف', '1,000 د.ع', fs),

                const SizedBox(height: 8),
                _dashedDivider(),
                const SizedBox(height: 8),

                // Totals
                _totalRow('المجموع الفرعي:', '14,250 د.ع', fs),
                const SizedBox(height: 2),
                _totalRow('الضريبة (10%):', '1,425 د.ع', fs),
                const SizedBox(height: 4),
                _dashedDivider(),
                const SizedBox(height: 4),
                _totalRow(
                  'الإجمالي:',
                  '15,675 د.ع',
                  fs,
                  bold: true,
                  fontSize: 14 * fs,
                ),
                _dashedDivider(),
                const SizedBox(height: 8),

                // Date / Time
                if (_settings.showDate)
                  _receiptLine(
                    _formatNow(),
                    fontSize: 10 * fs,
                    align: align,
                    color: Colors.grey.shade500,
                  ),

                const SizedBox(height: 12),

                // Barcode
                if (_settings.showBarcode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CustomPaint(
                      painter: _BarcodePainter(),
                      size: Size(200, 40 * fs),
                    ),
                  ),

                // QR code
                if (_showQRCode)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Icon(
                      Icons.qr_code_2,
                      size: 64 * fs,
                      color: Colors.black87,
                    ),
                  ),

                const SizedBox(height: 12),
                _dashedDivider(),
                const SizedBox(height: 8),

                // Footer
                _receiptLine(
                  _settings.footerText,
                  fontSize: 11 * fs,
                  align: align,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Dotted bottom edge
          Container(
            height: 8,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptLine(
    String text, {
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign align = TextAlign.right,
    Color color = AppTheme.textPrimary,
  }) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.getFont(
        _fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }

  Widget _buildItemRow(String name, String qty, String price, double fs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              name,
              style: GoogleFonts.getFont(
                _fontFamily,
                fontSize: 11 * fs,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(
                _fontFamily,
                fontSize: 11 * fs,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              price,
              textAlign: TextAlign.right,
              style: GoogleFonts.getFont(
                _fontFamily,
                fontSize: 11 * fs,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, double fs,
      {bool bold = false, double? fontSize}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.getFont(
            _fontFamily,
            fontSize: fontSize ?? (11 * fs),
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.getFont(
            _fontFamily,
            fontSize: fontSize ?? (11 * fs),
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: List.generate(
            (constraints.maxWidth / 6).floor(),
            (i) => Expanded(
              child: Container(
                height: 1,
                color: i.isEven ? Colors.grey.shade300 : Colors.transparent,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // RIGHT SIDE — Settings Controls
  // ---------------------------------------------------------------------------
  Widget _buildSettingsSection() {
    return Container(
      color: AppTheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('الإعدادات العامة'),
          const SizedBox(height: 12),
          _buildFontSettingsCard(),
          const SizedBox(height: 12),
          _buildAlignmentCard(),
          const SizedBox(height: 12),
          _buildDisplayOptionsCard(),
          const SizedBox(height: 12),
          _buildStoreInfoCard(),
          const SizedBox(height: 12),
          _buildFooterCard(),
          const SizedBox(height: 12),
          _buildPreviewColorCard(),
          const SizedBox(height: 12),
          _buildActionsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.notoSansArabic(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      color: AppTheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.notoSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  // --- Font Settings ---
  Widget _buildFontSettingsCard() {
    return _buildCard(
      title: 'إعدادات الخط',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'حجم الخط: ${_settings.fontSize.toStringAsFixed(1)}x',
                  style: GoogleFonts.notoSansArabic(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primary,
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primaryLighter,
              inactiveTrackColor: Colors.grey.shade200,
            ),
            child: Slider(
              value: _settings.fontSize,
              min: 0.7,
              max: 1.5,
              divisions: 16,
              onChanged: (v) {
                _settings.fontSize = v;
                _onChanged();
              },
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _fontFamily,
            decoration: InputDecoration(
              labelText: 'نوع الخط',
              labelStyle: GoogleFonts.notoSansArabic(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Noto Sans Arabic', child: Text('Noto Sans Arabic')),
              DropdownMenuItem(value: 'Cairo', child: Text('Cairo')),
              DropdownMenuItem(value: 'Tajawal', child: Text('Tajawal')),
              DropdownMenuItem(value: 'Almarai', child: Text('Almarai')),
              DropdownMenuItem(value: 'Amiri', child: Text('Amiri')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _fontFamily = v);
                _onChanged();
              }
            },
          ),
        ],
      ),
    );
  }

  // --- Alignment ---
  Widget _buildAlignmentCard() {
    return _buildCard(
      title: 'محاذاة النص',
      child: Row(
        children: [
          Expanded(
            child: _buildRadioOption(
              label: 'وسط',
              value: 'center',
              groupValue: _settings.alignment,
              onChanged: (v) {
                _settings.alignment = v!;
                _onChanged();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildRadioOption(
              label: 'يمين',
              value: 'right',
              groupValue: _settings.alignment,
              onChanged: (v) {
                _settings.alignment = v!;
                _onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLighter : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? AppTheme.primary : AppTheme.textLight,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.notoSansArabic(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Display Options ---
  Widget _buildDisplayOptionsCard() {
    return _buildCard(
      title: 'خيارات العرض',
      child: Column(
        children: [
          _buildToggleRow('إظهار الشعار', _showLogo, (v) {
            setState(() => _showLogo = v);
            _onChanged();
          }),
          _buildToggleRow('إظهار معلومات العميل', _settings.showCustomerInfo, (v) {
            _settings.showCustomerInfo = v;
            _onChanged();
          }),
          _buildToggleRow('إظهار اسم الكاشير', _showCashierName, (v) {
            setState(() => _showCashierName = v);
            _onChanged();
          }),
          _buildToggleRow('إظهار التاريخ والوقت', _settings.showDate, (v) {
            _settings.showDate = v;
            _onChanged();
          }),
          _buildToggleRow('إظهار الرقم الضريبي', _showTaxNumber, (v) {
            setState(() => _showTaxNumber = v);
            _onChanged();
          }),
          _buildToggleRow('إظهار الباركود', _settings.showBarcode, (v) {
            _settings.showBarcode = v;
            _onChanged();
          }),
          _buildToggleRow('إظهار كود QR', _showQRCode, (v) {
            setState(() => _showQRCode = v);
            _onChanged();
          }),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.notoSansArabic(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              activeColor: AppTheme.primary,
              activeTrackColor: AppTheme.primaryLight,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // --- Store Info ---
  Widget _buildStoreInfoCard() {
    return _buildCard(
      title: 'معلومات المتجر',
      child: Column(
        children: [
          _buildTextField(
            label: 'اسم المتجر',
            controller: _storeNameController,
            onChanged: (v) {
              _settings.storeName = v;
              _onChanged();
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: 'رقم الهاتف',
            controller: _storePhoneController,
            onChanged: (v) {
              _settings.storePhone = v;
              _onChanged();
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: 'العنوان',
            controller: _storeAddressController,
            onChanged: (v) {
              _settings.storeAddress = v;
              _onChanged();
            },
          ),
        ],
      ),
    );
  }

  // --- Footer ---
  Widget _buildFooterCard() {
    return _buildCard(
      title: 'نص التذييل',
      child: _buildTextField(
        label: 'نص التذييل',
        controller: _footerController,
        maxLines: 2,
        onChanged: (v) {
          _settings.footerText = v;
          _onChanged();
        },
      ),
    );
  }

  // --- Preview Color ---
  Widget _buildPreviewColorCard() {
    final presetColors = [
      Colors.white,
      const Color(0xFFFFFDE7),
      const Color(0xFFF3E5F5),
      const Color(0xFFE8F5E9),
      const Color(0xFFE3F2FD),
      const Color(0xFFFFF3E0),
    ];

    return _buildCard(
      title: 'لون خلفية الإيصال',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: presetColors.map((color) {
          final isSelected = _receiptBgColor.value == color.value;
          return GestureDetector(
            onTap: () {
              setState(() => _receiptBgColor = color);
              _onChanged();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 18, color: AppTheme.primary)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Actions ---
  Widget _buildActionsCard() {
    return _buildCard(
      title: 'الإجراءات',
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _resetToDefaults,
          icon: const Icon(Icons.restart_alt, size: 20),
          label: Text(
            'إعادة تعيين إلى الافتراضي',
            style: GoogleFonts.notoSansArabic(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.error,
            side: const BorderSide(color: AppTheme.error, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // --- Shared TextField ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.notoSansArabic(
        fontSize: 14,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSansArabic(
          color: AppTheme.textLight,
          fontSize: 13,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

// ---------------------------------------------------------------------------
// Inline barcode painter
// ---------------------------------------------------------------------------
class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.2
      ..style = PaintingStyle.fill;

    final pattern = [
      2, 1, 1, 3, 1, 2, 1, 1, 3, 1, 2, 1, 1, 2, 3, 1, 1, 2, 1, 3, 1, 2, 1,
      1, 3, 1, 2, 1, 1, 2, 3, 1, 1, 2, 1, 3, 1, 2, 1, 1
    ];

    double x = 4;
    final totalWidth =
        pattern.reduce((a, b) => a + b).toDouble();
    final scale = (size.width - 8) / totalWidth;

    for (final w in pattern) {
      final isBar = pattern.indexOf(w).isEven || (pattern.indexOf(w) % 3 == 0);
      if (isBar) {
        canvas.drawRect(
          Rect.fromLTWH(x * scale + 4, 0, w * scale, size.height),
          paint,
        );
      }
      x += w;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
