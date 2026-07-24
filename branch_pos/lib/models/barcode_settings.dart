import 'package:shared_preferences/shared_preferences.dart';

class BarcodeSettings {
  String printerName;
  String paperWidth;
  double fontSize;
  bool showProductName;
  bool showPrice;
  bool showBarcode;
  bool showBranchName;
  int copies;

  BarcodeSettings({
    this.printerName = '',
    this.paperWidth = '50x30mm',
    this.fontSize = 1.0,
    this.showProductName = true,
    this.showPrice = true,
    this.showBarcode = true,
    this.showBranchName = false,
    this.copies = 1,
  });

  static const _keyPrinterName = 'barcode_printer_name';
  static const _keyPaperWidth = 'barcode_paper_width';
  static const _keyFontSize = 'barcode_font_size';
  static const _keyShowProductName = 'barcode_show_product_name';
  static const _keyShowPrice = 'barcode_show_price';
  static const _keyShowBarcode = 'barcode_show_barcode';
  static const _keyShowBranchName = 'barcode_show_branch_name';
  static const _keyCopies = 'barcode_copies';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrinterName, printerName);
    await prefs.setString(_keyPaperWidth, paperWidth);
    await prefs.setDouble(_keyFontSize, fontSize);
    await prefs.setBool(_keyShowProductName, showProductName);
    await prefs.setBool(_keyShowPrice, showPrice);
    await prefs.setBool(_keyShowBarcode, showBarcode);
    await prefs.setBool(_keyShowBranchName, showBranchName);
    await prefs.setInt(_keyCopies, copies);
  }

  static Future<BarcodeSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return BarcodeSettings(
      printerName: prefs.getString(_keyPrinterName) ?? '',
      paperWidth: prefs.getString(_keyPaperWidth) ?? '50x30mm',
      fontSize: prefs.getDouble(_keyFontSize) ?? 1.0,
      showProductName: prefs.getBool(_keyShowProductName) ?? true,
      showPrice: prefs.getBool(_keyShowPrice) ?? true,
      showBarcode: prefs.getBool(_keyShowBarcode) ?? true,
      showBranchName: prefs.getBool(_keyShowBranchName) ?? false,
      copies: prefs.getInt(_keyCopies) ?? 1,
    );
  }
}
