class Invoice {
  final String id;
  final String orderId;
  final String branchId;
  final String branchName;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final DateTime createdAt;
  final String? customerName;
  final String? cashierName;

  Invoice({
    required this.id,
    required this.orderId,
    required this.branchId,
    required this.branchName,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.total,
    this.paymentMethod = 'نقداً',
    DateTime? createdAt,
    this.customerName,
    this.cashierName,
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'branch_id': branchId,
    'branch_name': branchName,
    'items': items.map((e) => e.toJson()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'tax': tax,
    'total': total,
    'payment_method': paymentMethod,
    'created_at': createdAt.toIso8601String(),
    'customer_name': customerName,
    'cashier_name': cashierName,
  };

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: json['id'] ?? '',
    orderId: json['order_id'] ?? '',
    branchId: json['branch_id'] ?? '',
    branchName: json['branch_name'] ?? '',
    items: (json['items'] as List?)?.map((e) => InvoiceItem.fromJson(e)).toList() ?? [],
    subtotal: (json['subtotal'] ?? 0).toDouble(),
    discount: (json['discount'] ?? 0).toDouble(),
    tax: (json['tax'] ?? 0).toDouble(),
    total: (json['total'] ?? 0).toDouble(),
    paymentMethod: json['payment_method'] ?? 'نقداً',
    createdAt: DateTime.tryParse(json['created_at'] ?? ''),
    customerName: json['customer_name'],
    cashierName: json['cashier_name'],
  );
}

class InvoiceItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String unit;
  final double total;

  InvoiceItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.unit = 'قطعة',
    double? total,
  }) : total = total ?? price * quantity;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
    'unit': unit,
    'total': total,
  };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
    productId: json['product_id'] ?? '',
    name: json['name'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    quantity: json['quantity'] ?? 1,
    unit: json['unit'] ?? 'قطعة',
    total: (json['total'] ?? 0).toDouble(),
  );
}
