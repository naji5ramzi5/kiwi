class CartItem {
  String id;
  String productId;
  String name;
  double price;
  int quantity;
  String unit;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.unit = 'قطعة',
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
    'unit': unit,
    'total': total,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] ?? '',
    productId: json['product_id'] ?? '',
    name: json['name'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    quantity: json['quantity'] ?? 1,
    unit: json['unit'] ?? 'قطعة',
  );
}
