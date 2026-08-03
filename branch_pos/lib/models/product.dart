class Product {
  final String id;
  final String name;
  final String? category;
  final String unit;
  final String? unitType;
  final double defaultPrice;
  final String? imageUrl;
  final bool isActive;
  final bool isOffer;
  final double? stockQuantity;
  final String? barcode;

  Product({
    required this.id,
    required this.name,
    this.category,
    this.unit = 'قطعة',
    this.unitType,
    this.defaultPrice = 0.0,
    this.imageUrl,
    this.isActive = true,
    this.isOffer = false,
    this.stockQuantity,
    this.barcode,
  });

  bool get isDecimalUnit {
    const decimalTypes = ['kilogram', 'kg', 'gram', 'g', 'liter', 'l', 'milliliter', 'ml'];
    return decimalTypes.contains(unitType);
  }

  double get stepSize => isDecimalUnit ? 0.5 : 1.0;

  String get unitDisplayName => unit.isNotEmpty ? unit : _unitTypeToArabic;

  String get _unitTypeToArabic {
    switch (unitType) {
      case 'kilogram': return 'كيلو';
      case 'gram': return 'جرام';
      case 'piece': return 'قطعة';
      case 'unit': return 'وحدة';
      case 'box': return 'علبة';
      case 'carton': return 'كرتون';
      case 'pack': return 'باكيت';
      case 'bottle': return 'زجاجة';
      case 'can': return 'علبة';
      case 'bag': return 'كيس';
      case 'tray': return 'صينية';
      case 'bundle': return 'ربطة';
      case 'sack': return 'خرس';
      case 'liter': return 'لتر';
      case 'milliliter': return 'مل';
      default: return 'قطعة';
    }
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'],
      unit: json['unit'] ?? 'قطعة',
      unitType: json['unit_type'],
      defaultPrice: (json['default_price'] ?? 0).toDouble(),
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
      isOffer: json['is_offer'] ?? false,
      stockQuantity: (json['stock_quantity'] ?? json['actual_stock'])?.toDouble(),
      barcode: json['barcode'],
    );
  }

  Product copyWith({double? stockQuantity, double? defaultPrice}) => Product(
    id: id,
    name: name,
    category: category,
    unit: unit,
    unitType: unitType,
    defaultPrice: defaultPrice ?? this.defaultPrice,
    imageUrl: imageUrl,
    isActive: isActive,
    isOffer: isOffer,
    stockQuantity: stockQuantity ?? this.stockQuantity,
    barcode: barcode,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'unit': unit,
    'unit_type': unitType,
    'default_price': defaultPrice,
    'image_url': imageUrl,
    'is_active': isActive,
    'is_offer': isOffer,
    'barcode': barcode,
  };
}
