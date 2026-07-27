import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../models/barcode_settings.dart';

class BarcodeLabelDesignerPage extends StatefulWidget {
  const BarcodeLabelDesignerPage({super.key});

  @override
  State<BarcodeLabelDesignerPage> createState() =>
      _BarcodeLabelDesignerPageState();
}

class _BarcodeLabelDesignerPageState extends State<BarcodeLabelDesignerPage>
    with SingleTickerProviderStateMixin {
  late BarcodeSettings _settings;
  bool _loaded = false;
  Timer? _debounce;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _settings = await BarcodeSettings.load();
    setState(() => _loaded = true);
  }

  void _autoSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _settings.save();
    });
  }

  void _resetToDefaults() {
    setState(() => _settings = BarcodeSettings());
    _autoSave();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تمت استعادة الإعدادات الافتراضية'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  List<double> _getLabelDimensions() {
    switch (_settings.paperWidth) {
      case '40x30mm':
        return [180.0, 135.0];
      case '50x25mm':
        return [200.0, 100.0];
      case '60x40mm':
        return [240.0, 160.0];
      case '100x50mm':
        return [300.0, 150.0];
      case '50x30mm':
      default:
        return [200.0, 120.0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _loaded ? _buildContent() : _buildLoading(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildLeftPreview()),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: _buildRightControls()),
              ],
            ),
          ),
        ],
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
          child: const Icon(LucideIcons.paintbrush, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تصميم ملصق الباركود',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryDarker,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'تصميم وتخصيص ملصق الباركود — معاينة لحظية',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeftPreview() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.eye, size: 18, color: AppTheme.primary),
                const SizedBox(width: 10),
                const Text('معاينة الملصق',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLighter,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _settings.paperWidth,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: _buildLabelPreview(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelPreview() {
    final dims = _getLabelDimensions();
    final fs = _settings.fontSize;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: dims[0],
      height: dims[1],
      padding: EdgeInsets.all(_settings.printMargins * 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(-2, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_settings.showProductName) ...[
            Text(
              'طماطم طازجة',
              style: TextStyle(
                fontSize: _settings.nameFontSize * fs,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2 * fs),
          ],
          if (_settings.showSku) ...[
            Text(
              'SKU: TOM-001',
              style: TextStyle(
                fontSize: 8 * fs,
                color: AppTheme.textSecondary,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2 * fs),
          ],
          if (_settings.showBarcode) ...[
            Container(
              margin: EdgeInsets.symmetric(vertical: 2 * fs),
              child: _buildBarcodeVisual(fs),
            ),
          ],
          if (_settings.showQrCode) ...[
            Container(
              margin: EdgeInsets.symmetric(vertical: 2 * fs),
              width: 30 * fs,
              height: 30 * fs,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.textPrimary, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.qrCode,
                  size: 22 * fs,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
          if (_settings.showPrice) ...[
            Text(
              '2,500 د.ع',
              style: TextStyle(
                fontSize: _settings.priceFontSize * fs,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1 * fs),
          ],
          if (_settings.showBatchNumber) ...[
            Text(
              'ال批次: B2026-07',
              style: TextStyle(
                fontSize: 7 * fs,
                color: AppTheme.textLight,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (_settings.showExpiryDate) ...[
            Text(
              'الصالحية: 2026/08/15',
              style: TextStyle(
                fontSize: 7 * fs,
                color: AppTheme.textLight,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarcodeVisual(double fs) {
    return Column(
      children: [
        Container(
          width: _settings.barcodeWidth * fs * 0.5,
          height: _settings.barcodeHeight * fs * 0.5,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Text(
              '||| || ||| | || |||',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8 * fs,
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        SizedBox(height: 2 * fs),
        Text(
          '001234567890',
          style: TextStyle(
            fontSize: 7 * fs,
            fontFamily: 'monospace',
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRightControls() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionCard(
            title: 'حجم الخط',
            subtitle: 'تخصيص حجم خط اسم المنتج والسعر',
            icon: LucideIcons.type,
            iconColor: AppTheme.primary,
            child: Column(
              children: [
                _buildFontSizeSlider(
                  label: 'حجم خط اسم المنتج',
                  value: _settings.nameFontSize,
                  min: 8.0,
                  max: 24.0,
                  onChanged: (v) {
                    setState(() => _settings.nameFontSize = v);
                    _autoSave();
                  },
                ),
                const SizedBox(height: 16),
                _buildFontSizeSlider(
                  label: 'حجم خط السعر',
                  value: _settings.priceFontSize,
                  min: 10.0,
                  max: 28.0,
                  onChanged: (v) {
                    setState(() => _settings.priceFontSize = v);
                    _autoSave();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'حجم الباركود',
            subtitle: 'تخصيص ارتفاع وعرض شريط الباركود',
            icon: LucideIcons.maximize2,
            iconColor: AppTheme.info,
            child: Column(
              children: [
                _buildFontSizeSlider(
                  label: 'ارتفاع الباركود',
                  value: _settings.barcodeHeight,
                  min: 15.0,
                  max: 80.0,
                  onChanged: (v) {
                    setState(() => _settings.barcodeHeight = v);
                    _autoSave();
                  },
                ),
                const SizedBox(height: 16),
                _buildFontSizeSlider(
                  label: 'عرض الباركود',
                  value: _settings.barcodeWidth,
                  min: 60.0,
                  max: 200.0,
                  onChanged: (v) {
                    setState(() => _settings.barcodeWidth = v);
                    _autoSave();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'خيارات العرض',
            subtitle: 'تحديد المعلومات الظاهرة على الملصق',
            icon: LucideIcons.eye,
            iconColor: AppTheme.secondary,
            child: Column(
              children: [
                _buildToggleRow(
                    'إظهار اسم المنتج', _settings.showProductName, (v) {
                  setState(() => _settings.showProductName = v);
                  _autoSave();
                }),
                _buildToggleRow('إظهار السعر', _settings.showPrice, (v) {
                  setState(() => _settings.showPrice = v);
                  _autoSave();
                }),
                _buildToggleRow('إظهار الباركود', _settings.showBarcode, (v) {
                  setState(() => _settings.showBarcode = v);
                  _autoSave();
                }),
                _buildToggleRow('إظهار رقم الصنف (SKU)', _settings.showSku, (v) {
                  setState(() => _settings.showSku = v);
                  _autoSave();
                }),
                _buildToggleRow(
                    'إظهار تاريخ الصلاحية', _settings.showExpiryDate, (v) {
                  setState(() => _settings.showExpiryDate = v);
                  _autoSave();
                }),
                _buildToggleRow(
                    'إظهار رقم التشغيلة', _settings.showBatchNumber, (v) {
                  setState(() => _settings.showBatchNumber = v);
                  _autoSave();
                }),
                _buildToggleRow('إظهار رمز QR', _settings.showQrCode, (v) {
                  setState(() => _settings.showQrCode = v);
                  _autoSave();
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'نوع الباركود',
            subtitle: 'اختيار تنسيق ترميز الباركود',
            icon: LucideIcons.scanLine,
            iconColor: AppTheme.warning,
            child: Column(
              children: [
                _buildBarcodeTypeOption(
                    'CODE128', 'شائع الاستخدام، يدعم الأرقام والحروف'),
                const SizedBox(height: 10),
                _buildBarcodeTypeOption(
                    'EAN13', 'مستخدم في المنتجات التجارية والبضائع'),
                const SizedBox(height: 10),
                _buildBarcodeTypeOption(
                    'QR', 'رمز استجابة سريع، يدعم روابط ومعلومات كثيرة'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'الإجراءات',
            subtitle: 'إدارة الإعدادات',
            icon: LucideIcons.settings,
            iconColor: AppTheme.error,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _resetToDefaults,
                    icon: const Icon(LucideIcons.rotateCcw, size: 18),
                    label: const Text('استعادة الإعدادات الافتراضية'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.buttonShadow,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _settings.save();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('تم حفظ التصميم بنجاح'),
                              backgroundColor: AppTheme.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                      icon: const Icon(LucideIcons.save, size: 18),
                      label: const Text('حفظ التصميم'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
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
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
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

  Widget _buildFontSizeSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(LucideIcons.minus, size: 14, color: AppTheme.textSecondary),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: ((max - min) * 2).round(),
                activeColor: AppTheme.primary,
                inactiveColor: AppTheme.primaryLighter,
                label: value.toStringAsFixed(1),
                onChanged: onChanged,
              ),
            ),
            const Icon(LucideIcons.plus, size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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

  Widget _buildBarcodeTypeOption(String type, String description) {
    final isSelected = _settings.barcodeType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _settings.barcodeType = type);
        _autoSave();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.warning.withOpacity(0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.warning : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.warning : Colors.grey.shade300,
                border: Border.all(
                  color: isSelected ? AppTheme.warning : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color:
                          isSelected ? AppTheme.warning : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
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
}