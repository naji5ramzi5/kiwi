import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  // Company Info
  final _companyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  String? _logoPath;

  // Currency & Language
  String _selectedCurrency = 'IQD';
  String _selectedLanguage = 'ar';
  bool _darkMode = false;

  // Date & Time
  String _dateFormat = 'dd/MM/yyyy';
  String _timeFormat = '24';

  // Tax Settings
  final _taxRateController = TextEditingController();
  final _taxNumberController = TextEditingController();
  bool _showTaxOnReceipt = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _taxRateController.dispose();
    _taxNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyNameController.text = prefs.getString('company_name') ?? '';
      _phoneController.text = prefs.getString('company_phone') ?? '';
      _emailController.text = prefs.getString('company_email') ?? '';
      _addressController.text = prefs.getString('company_address') ?? '';
      _logoPath = prefs.getString('company_logo');
      _selectedCurrency = prefs.getString('currency') ?? 'IQD';
      _selectedLanguage = prefs.getString('language') ?? 'ar';
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _dateFormat = prefs.getString('date_format') ?? 'dd/MM/yyyy';
      _timeFormat = prefs.getString('time_format') ?? '24';
      _taxRateController.text = prefs.getString('tax_rate') ?? '0';
      _taxNumberController.text = prefs.getString('tax_number') ?? '';
      _showTaxOnReceipt = prefs.getBool('show_tax_on_receipt') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_name', _companyNameController.text.trim());
    await prefs.setString('company_phone', _phoneController.text.trim());
    await prefs.setString('company_email', _emailController.text.trim());
    await prefs.setString('company_address', _addressController.text.trim());
    if (_logoPath != null) await prefs.setString('company_logo', _logoPath!);
    await prefs.setString('currency', _selectedCurrency);
    await prefs.setString('language', _selectedLanguage);
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setString('date_format', _dateFormat);
    await prefs.setString('time_format', _timeFormat);
    await prefs.setString('tax_rate', _taxRateController.text.trim());
    await prefs.setString('tax_number', _taxNumberController.text.trim());
    await prefs.setBool('show_tax_on_receipt', _showTaxOnReceipt);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حفظ الإعدادات بنجاح'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _restoreDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('company_name');
    await prefs.remove('company_phone');
    await prefs.remove('company_email');
    await prefs.remove('company_address');
    await prefs.remove('company_logo');
    await prefs.setString('currency', 'IQD');
    await prefs.setString('language', 'ar');
    await prefs.setBool('dark_mode', false);
    await prefs.setString('date_format', 'dd/MM/yyyy');
    await prefs.setString('time_format', '24');
    await prefs.setString('tax_rate', '0');
    await prefs.remove('tax_number');
    await prefs.setBool('show_tax_on_receipt', true);

    await _loadSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تمت استعادة الإعدادات الافتراضية'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCompanyInfoCard(),
                    const SizedBox(height: 16),
                    _buildCurrencyLanguageCard(),
                    const SizedBox(height: 16),
                    _buildDateTimeCard(),
                    const SizedBox(height: 16),
                    _buildTaxSettingsCard(),
                    const SizedBox(height: 16),
                    _buildActionsCard(),
                    const SizedBox(height: 24),
                  ],
                ),
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
              'الإعدادات العامة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryDarker,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'إعدادات المتجر والعملة والضرائب',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ],
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
            color: iconColor.withOpacity(0.06),
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
            hintText: hintText,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyInfoCard() {
    return _buildSectionCard(
      title: 'معلومات المتجر',
      subtitle: 'اسم المتجر والشعار ومعلومات التواصل',
      icon: LucideIcons.store,
      iconColor: AppTheme.primary,
      child: Column(
        children: [
          // Logo picker
          Row(
            children: [
              GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _logoPath != null
                          ? AppTheme.primary
                          : Colors.grey.shade200,
                      width: 2,
                    ),
                  ),
                  child: _logoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(_logoPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildLogoPlaceholder(),
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
                    _logoPath != null ? 'تم تحميل الشعار' : 'اضغط لاختيار شعار',
                    style: TextStyle(
                      fontSize: 13,
                      color: _logoPath != null
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_logoPath != null)
                    TextButton(
                      onPressed: () => setState(() => _logoPath = null),
                      child: const Text(
                        'إزالة الشعار',
                        style: TextStyle(color: AppTheme.error, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'اسم المتجر',
            controller: _companyNameController,
            icon: LucideIcons.store,
            hintText: 'أدخل اسم المتجر',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'رقم الهاتف',
                  controller: _phoneController,
                  icon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  hintText: '07XX XXX XXXX',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'البريد الإلكتروني',
                  controller: _emailController,
                  icon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'info@example.com',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'العنوان',
            controller: _addressController,
            icon: LucideIcons.mapPin,
            hintText: 'عنوان الفرع',
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.image, color: Colors.grey.shade400, size: 24),
        const SizedBox(height: 4),
        Text(
          'شعار',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _logoPath = result.files.single.path);
    }
  }

  Widget _buildCurrencyLanguageCard() {
    return _buildSectionCard(
      title: 'العملة واللغة',
      subtitle: 'اختر العملة واللغة الافتراضية',
      icon: LucideIcons.globe,
      iconColor: AppTheme.info,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown<String>(
                  label: 'العملة الافتراضية',
                  value: _selectedCurrency,
                  items: const [
                    DropdownMenuItem(value: 'IQD', child: Text('دينار عراقي (IQD)')),
                    DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
                    DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
                    DropdownMenuItem(value: 'AED', child: Text('درهم إماراتي (AED)')),
                    DropdownMenuItem(value: 'EGP', child: Text('جنيه مصري (EGP)')),
                  ],
                  onChanged: (v) => setState(() => _selectedCurrency = v!),
                  icon: LucideIcons.coins,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown<String>(
                  label: 'اللغة',
                  value: _selectedLanguage,
                  items: const [
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (v) => setState(() => _selectedLanguage = v!),
                  icon: LucideIcons.languages,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildToggleRow(
            label: 'الوضع الليلي',
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
            icon: LucideIcons.moon,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return _buildSectionCard(
      title: 'التاريخ والوقت',
      subtitle: 'تنسيق التاريخ والوقت في الفواتير',
      icon: LucideIcons.calendar,
      iconColor: AppTheme.warning,
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown<String>(
              label: 'تنسيق التاريخ',
              value: _dateFormat,
              items: const [
                DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('31/12/2025')),
                DropdownMenuItem(value: 'MM/dd/yyyy', child: Text('12/31/2025')),
                DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('2025-12-31')),
              ],
              onChanged: (v) => setState(() => _dateFormat = v!),
              icon: LucideIcons.calendarDays,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdown<String>(
              label: 'تنسيق الوقت',
              value: _timeFormat,
              items: const [
                DropdownMenuItem(value: '24', child: Text('24 ساعة (14:30)')),
                DropdownMenuItem(value: '12', child: Text('12 ساعة (2:30 م)')),
              ],
              onChanged: (v) => setState(() => _timeFormat = v!),
              icon: LucideIcons.clock,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxSettingsCard() {
    return _buildSectionCard(
      title: 'إعدادات الضريبة',
      subtitle: 'نسبة الضريبة ورقم السجل الضريبي',
      icon: LucideIcons.receipt,
      iconColor: AppTheme.accent,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'نسبة الضريبة (%)',
                  controller: _taxRateController,
                  icon: LucideIcons.percent,
                  keyboardType: TextInputType.number,
                  hintText: '0',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'رقم السجل الضريبي',
                  controller: _taxNumberController,
                  icon: LucideIcons.hash,
                  hintText: 'اختياري',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildToggleRow(
            label: 'إظهار الضريبة على الفاتورة',
            value: _showTaxOnReceipt,
            onChanged: (v) => setState(() => _showTaxOnReceipt = v),
            icon: LucideIcons.eye,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return _buildSectionCard(
      title: 'الإجراءات',
      subtitle: 'حفظ واستعادة الإعدادات',
      icon: LucideIcons.save,
      iconColor: AppTheme.success,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.buttonShadow,
              ),
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(LucideIcons.save, size: 18),
                label: const Text(
                  'حفظ الإعدادات',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _restoreDefaults,
                icon: const Icon(LucideIcons.rotateCcw, size: 18),
                label: const Text(
                  'استعادة الافتراضي',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 18),
            ),
          ),
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: AppTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
