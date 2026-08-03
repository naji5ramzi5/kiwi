class CartItem {
  String id;
  String productId;
  String name;
  double price;
  double quantity;
  String unit;
  String? unitType;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1.0,
    this.unit = 'قطعة',
    this.unitType,
  });

  bool get isDecimalUnit {
    const decimalTypes = ['kilogram', 'kg', 'gram', 'g', 'liter', 'l', 'milliliter', 'ml'];
    return decimalTypes.contains(unitType);
  }

  double get stepSize => isDecimalUnit ? 0.5 : 1.0;

  double get total => price * quantity;

  String get displayQuantity {
    if (quantity == quantity.toInt()) return quantity.toInt().toString();
    return quantity.toStringAsFixed(1);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
    'unit': unit,
    'unit_type': unitType,
    'total': total,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] ?? '',
    productId: json['product_id'] ?? '',
    name: json['name'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    quantity: (json['quantity'] ?? 1).toDouble(),
    unit: json['unit'] ?? 'قطعة',
    unitType: json['unit_type'],
  );
}
