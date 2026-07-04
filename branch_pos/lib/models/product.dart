class Product {
  final String id;
  final String name;
  final String? category;
  final String unit;
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
    this.defaultPrice = 0.0,
    this.imageUrl,
    this.isActive = true,
    this.isOffer = false,
    this.stockQuantity,
    this.barcode,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'],
      unit: json['unit'] ?? 'قطعة',
      defaultPrice: (json['default_price'] ?? 0).toDouble(),
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
      isOffer: json['is_offer'] ?? false,
      stockQuantity: json['stock_quantity']?.toDouble(),
      barcode: json['barcode'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'unit': unit,
    'default_price': defaultPrice,
    'image_url': imageUrl,
    'is_active': isActive,
    'is_offer': isOffer,
    'barcode': barcode,
  };
}
