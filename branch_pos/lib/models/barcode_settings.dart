import 'package:shared_preferences/shared_preferences.dart';

class BarcodeSettings {
  String printerName;
  String paperWidth;
  double fontSize;
  double nameFontSize;
  double priceFontSize;
  double barcodeHeight;
  double barcodeWidth;
  bool showProductName;
  bool showPrice;
  bool showBarcode;
  bool showBranchName;
  bool showSku;
  bool showExpiryDate;
  bool showBatchNumber;
  bool showQrCode;
  String barcodeType;
  String printDirection;
  double printMargins;
  int copies;

  BarcodeSettings({
    this.printerName = '',
    this.paperWidth = '50x30mm',
    this.fontSize = 1.0,
    this.nameFontSize = 14.0,
    this.priceFontSize = 16.0,
    this.barcodeHeight = 40.0,
    this.barcodeWidth = 120.0,
    this.showProductName = true,
    this.showPrice = true,
    this.showBarcode = true,
    this.showBranchName = false,
    this.showSku = true,
    this.showExpiryDate = false,
    this.showBatchNumber = false,
    this.showQrCode = false,
    this.barcodeType = 'CODE128',
    this.printDirection = 'ltr',
    this.printMargins = 4.0,
    this.copies = 1,
  });

  BarcodeSettings copyWith({
    String? printerName,
    String? paperWidth,
    double? fontSize,
    double? nameFontSize,
    double? priceFontSize,
    double? barcodeHeight,
    double? barcodeWidth,
    bool? showProductName,
    bool? showPrice,
    bool? showBarcode,
    bool? showBranchName,
    bool? showSku,
    bool? showExpiryDate,
    bool? showBatchNumber,
    bool? showQrCode,
    String? barcodeType,
    String? printDirection,
    double? printMargins,
    int? copies,
  }) {
    return BarcodeSettings(
      printerName: printerName ?? this.printerName,
      paperWidth: paperWidth ?? this.paperWidth,
      fontSize: fontSize ?? this.fontSize,
      nameFontSize: nameFontSize ?? this.nameFontSize,
      priceFontSize: priceFontSize ?? this.priceFontSize,
      barcodeHeight: barcodeHeight ?? this.barcodeHeight,
      barcodeWidth: barcodeWidth ?? this.barcodeWidth,
      showProductName: showProductName ?? this.showProductName,
      showPrice: showPrice ?? this.showPrice,
      showBarcode: showBarcode ?? this.showBarcode,
      showBranchName: showBranchName ?? this.showBranchName,
      showSku: showSku ?? this.showSku,
      showExpiryDate: showExpiryDate ?? this.showExpiryDate,
      showBatchNumber: showBatchNumber ?? this.showBatchNumber,
      showQrCode: showQrCode ?? this.showQrCode,
      barcodeType: barcodeType ?? this.barcodeType,
      printDirection: printDirection ?? this.printDirection,
      printMargins: printMargins ?? this.printMargins,
      copies: copies ?? this.copies,
    );
  }

  static const _keyPrinterName = 'barcode_printer_name';
  static const _keyPaperWidth = 'barcode_paper_width';
  static const _keyFontSize = 'barcode_font_size';
  static const _keyNameFontSize = 'barcode_name_font_size';
  static const _keyPriceFontSize = 'barcode_price_font_size';
  static const _keyBarcodeHeight = 'barcode_height';
  static const _keyBarcodeWidth = 'barcode_width';
  static const _keyShowProductName = 'barcode_show_product_name';
  static const _keyShowPrice = 'barcode_show_price';
  static const _keyShowBarcode = 'barcode_show_barcode';
  static const _keyShowBranchName = 'barcode_show_branch_name';
  static const _keyShowSku = 'barcode_show_sku';
  static const _keyShowExpiryDate = 'barcode_show_expiry_date';
  static const _keyShowBatchNumber = 'barcode_show_batch_number';
  static const _keyShowQrCode = 'barcode_show_qr_code';
  static const _keyBarcodeType = 'barcode_type';
  static const _keyPrintDirection = 'barcode_print_direction';
  static const _keyPrintMargins = 'barcode_print_margins';
  static const _keyCopies = 'barcode_copies';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrinterName, printerName);
    await prefs.setString(_keyPaperWidth, paperWidth);
    await prefs.setDouble(_keyFontSize, fontSize);
    await prefs.setDouble(_keyNameFontSize, nameFontSize);
    await prefs.setDouble(_keyPriceFontSize, priceFontSize);
    await prefs.setDouble(_keyBarcodeHeight, barcodeHeight);
    await prefs.setDouble(_keyBarcodeWidth, barcodeWidth);
    await prefs.setBool(_keyShowProductName, showProductName);
    await prefs.setBool(_keyShowPrice, showPrice);
    await prefs.setBool(_keyShowBarcode, showBarcode);
    await prefs.setBool(_keyShowBranchName, showBranchName);
    await prefs.setBool(_keyShowSku, showSku);
    await prefs.setBool(_keyShowExpiryDate, showExpiryDate);
    await prefs.setBool(_keyShowBatchNumber, showBatchNumber);
    await prefs.setBool(_keyShowQrCode, showQrCode);
    await prefs.setString(_keyBarcodeType, barcodeType);
    await prefs.setString(_keyPrintDirection, printDirection);
    await prefs.setDouble(_keyPrintMargins, printMargins);
    await prefs.setInt(_keyCopies, copies);
  }

  static Future<BarcodeSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return BarcodeSettings(
      printerName: prefs.getString(_keyPrinterName) ?? '',
      paperWidth: prefs.getString(_keyPaperWidth) ?? '50x30mm',
      fontSize: prefs.getDouble(_keyFontSize) ?? 1.0,
      nameFontSize: prefs.getDouble(_keyNameFontSize) ?? 14.0,
      priceFontSize: prefs.getDouble(_keyPriceFontSize) ?? 16.0,
      barcodeHeight: prefs.getDouble(_keyBarcodeHeight) ?? 40.0,
      barcodeWidth: prefs.getDouble(_keyBarcodeWidth) ?? 120.0,
      showProductName: prefs.getBool(_keyShowProductName) ?? true,
      showPrice: prefs.getBool(_keyShowPrice) ?? true,
      showBarcode: prefs.getBool(_keyShowBarcode) ?? true,
      showBranchName: prefs.getBool(_keyShowBranchName) ?? false,
      showSku: prefs.getBool(_keyShowSku) ?? true,
      showExpiryDate: prefs.getBool(_keyShowExpiryDate) ?? false,
      showBatchNumber: prefs.getBool(_keyShowBatchNumber) ?? false,
      showQrCode: prefs.getBool(_keyShowQrCode) ?? false,
      barcodeType: prefs.getString(_keyBarcodeType) ?? 'CODE128',
      printDirection: prefs.getString(_keyPrintDirection) ?? 'ltr',
      printMargins: prefs.getDouble(_keyPrintMargins) ?? 4.0,
      copies: prefs.getInt(_keyCopies) ?? 1,
    );
  }
}
