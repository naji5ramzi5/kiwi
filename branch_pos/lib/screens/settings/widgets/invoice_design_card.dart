import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../models/invoice_settings.dart';

class InvoiceDesignCard extends StatelessWidget {
  final InvoiceSettings settings;
  final bool settingsLoaded;
  final TextEditingController storeNameController;
  final TextEditingController storePhoneController;
  final TextEditingController storeAddressController;
  final TextEditingController footerTextController;
  final VoidCallback onPreview;
  final VoidCallback onSave;
  final ValueChanged<String?> onPaperSizeChanged;
  final ValueChanged<bool> onShowCustomerInfoChanged;
  final ValueChanged<String?> onLogoChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<String?> onAlignmentChanged;
  final ValueChanged<bool> onShowBarcodeChanged;
  final ValueChanged<bool> onShowDateChanged;

  const InvoiceDesignCard({
    super.key,
    required this.settings,
    required this.settingsLoaded,
    required this.storeNameController,
    required this.storePhoneController,
    required this.storeAddressController,
    required this.footerTextController,
    required this.onPreview,
    required this.onSave,
    required this.onPaperSizeChanged,
    required this.onShowCustomerInfoChanged,
    required this.onLogoChanged,
    required this.onFontSizeChanged,
    required this.onAlignmentChanged,
    required this.onShowBarcodeChanged,
    required this.onShowDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.fileText,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'تصميم الفاتورة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'تخصيص معلومات المتجر التي تظهر في فاتورة الطباعة',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 28),

          if (!settingsLoaded)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSettingsField(
                        storeNameController,
                        'اسم المتجر',
                        'مثال: كيوي - سوق الخضار',
                        LucideIcons.store,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildSettingsField(
                        storePhoneController,
                        'رقم الهاتف',
                        '07XX XXX XXXX',
                        LucideIcons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildSettingsField(
                        storeAddressController,
                        'عنوان الفرع',
                        'العراق، بغداد، منطقة...',
                        LucideIcons.mapPin,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildSettingsField(
                        footerTextController,
                        'نص التذييل',
                        'شكراً لتسوقكم مع كيوي',
                        LucideIcons.quote,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildLogoSection(),
                const SizedBox(height: 24),

                _buildFontAndAlignmentRow(),
                const SizedBox(height: 24),

                Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'حجم ورق الطباعة',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: settings.paperSize,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                LucideIcons.maximize2,
                                color: AppTheme.primary,
                                size: 18,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: '80mm',
                                child: Text('80 مم (قياسي)'),
                              ),
                              DropdownMenuItem(
                                value: '58mm',
                                child: Text('58 مم (صغير)'),
                              ),
                            ],
                            onChanged: onPaperSizeChanged,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    _buildToggleChip(
                      'إظهار بيانات العميل',
                      settings.showCustomerInfo,
                      onShowCustomerInfoChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildToggleChip(
                      'إظهار الباركود',
                      settings.showBarcode,
                      onShowBarcodeChanged,
                    ),
                    const SizedBox(width: 16),
                    _buildToggleChip(
                      'إظهار التاريخ والوقت',
                      settings.showDate,
                      onShowDateChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: onPreview,
                      icon: const Icon(LucideIcons.eye),
                      label: const Text('معاينة الفاتورة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: onSave,
                      icon: const Icon(LucideIcons.save),
                      label: const Text('حفظ الإعدادات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Row(
      children: [
        const Text(
          'شعار المتجر',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.image,
            );
            if (result != null && result.files.single.path != null) {
              onLogoChanged(result.files.single.path);
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: settings.logoPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(settings.logoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
                    ),
                  )
                : _buildLogoPlaceholder(),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.logoPath != null ? 'تم تحميل الشعار' : 'اضغط لاختيار شعار',
              style: TextStyle(
                fontSize: 12,
                color: settings.logoPath != null ? Colors.green : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (settings.logoPath != null)
              TextButton(
                onPressed: () => onLogoChanged(null),
                child: const Text(
                  'إزالة الشعار',
                  style: TextStyle(color: Colors.red, fontSize: 11),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.image, color: AppTheme.textSecondary, size: 24),
        SizedBox(height: 4),
        Text(
          'شعار',
          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFontAndAlignmentRow() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'حجم الخط',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.minus, size: 16, color: AppTheme.textSecondary),
                SizedBox(
                  width: 180,
                  child: Slider(
                    value: settings.fontSize,
                    min: 0.7,
                    max: 1.5,
                    divisions: 8,
                    activeColor: AppTheme.primary,
                    label: '${(settings.fontSize * 100).round()}%',
                    onChanged: onFontSizeChanged,
                  ),
                ),
                const Icon(LucideIcons.plus, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${(settings.fontSize * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 40),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'محاذاة النص',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildAlignmentOption('right', 'يمين', LucideIcons.alignRight),
                const SizedBox(width: 8),
                _buildAlignmentOption('center', 'وسط', LucideIcons.alignCenter),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlignmentOption(String value, String label, IconData icon) {
    final isSelected = settings.alignment == value;
    return GestureDetector(
      onTap: () => onAlignmentChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleChip(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeColor: AppTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
