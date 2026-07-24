import 'package:shared_preferences/shared_preferences.dart';

class InvoiceSettings {
  String storeName;
  String storePhone;
  String storeAddress;
  String footerText;
  String paperSize;
  bool showCustomerInfo;
  String? logoPath;
  double fontSize;
  String alignment;
  bool showBarcode;
  bool showDate;

  InvoiceSettings({
    this.storeName = 'كيوي - سوق الخضار',
    this.storePhone = '',
    this.storeAddress = '',
    this.footerText = 'شكراً لتسوقكم مع كيوي',
    this.paperSize = '80mm',
    this.showCustomerInfo = true,
    this.logoPath,
    this.fontSize = 1.0,
    this.alignment = 'center',
    this.showBarcode = true,
    this.showDate = true,
  });

  static const _keyStoreName = 'invoice_store_name';
  static const _keyStorePhone = 'invoice_store_phone';
  static const _keyStoreAddress = 'invoice_store_address';
  static const _keyFooterText = 'invoice_footer_text';
  static const _keyPaperSize = 'invoice_paper_size';
  static const _keyShowCustomer = 'invoice_show_customer';
  static const _keyLogoPath = 'invoice_logo_path';
  static const _keyFontSize = 'invoice_font_size';
  static const _keyAlignment = 'invoice_alignment';
  static const _keyShowBarcode = 'invoice_show_barcode';
  static const _keyShowDate = 'invoice_show_date';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStoreName, storeName);
    await prefs.setString(_keyStorePhone, storePhone);
    await prefs.setString(_keyStoreAddress, storeAddress);
    await prefs.setString(_keyFooterText, footerText);
    await prefs.setString(_keyPaperSize, paperSize);
    await prefs.setBool(_keyShowCustomer, showCustomerInfo);
    if (logoPath != null) {
      await prefs.setString(_keyLogoPath, logoPath!);
    } else {
      await prefs.remove(_keyLogoPath);
    }
    await prefs.setDouble(_keyFontSize, fontSize);
    await prefs.setString(_keyAlignment, alignment);
    await prefs.setBool(_keyShowBarcode, showBarcode);
    await prefs.setBool(_keyShowDate, showDate);
  }

  static Future<InvoiceSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return InvoiceSettings(
      storeName: prefs.getString(_keyStoreName) ?? 'كيوي - سوق الخضار',
      storePhone: prefs.getString(_keyStorePhone) ?? '',
      storeAddress: prefs.getString(_keyStoreAddress) ?? '',
      footerText: prefs.getString(_keyFooterText) ?? 'شكراً لتسوقكم مع كيوي',
      paperSize: prefs.getString(_keyPaperSize) ?? '80mm',
      showCustomerInfo: prefs.getBool(_keyShowCustomer) ?? true,
      logoPath: prefs.getString(_keyLogoPath),
      fontSize: prefs.getDouble(_keyFontSize) ?? 1.0,
      alignment: prefs.getString(_keyAlignment) ?? 'center',
      showBarcode: prefs.getBool(_keyShowBarcode) ?? true,
      showDate: prefs.getBool(_keyShowDate) ?? true,
    );
  }

  PdfPageSize get pdfPageSize =>
      paperSize == '58mm' ? PdfPageSize.mm58 : PdfPageSize.mm80;
}

enum PdfPageSize { mm80, mm58 }

extension PdfPageSizeUtils on PdfPageSize {
  double get width {
    switch (this) {
      case PdfPageSize.mm80:
        return 80.0;
      case PdfPageSize.mm58:
        return 58.0;
    }
  }
}
