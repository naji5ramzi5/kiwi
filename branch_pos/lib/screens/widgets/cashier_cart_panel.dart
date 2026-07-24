import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/cart_item.dart';

class CashierCartPanel extends StatelessWidget {
  final List<CartItem> cart;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final bool isCheckingOut;
  final void Function(int index, int delta) onUpdateQuantity;
  final ValueChanged<int> onRemoveFromCart;
  final VoidCallback onClearCart;
  final ValueChanged<double> onDiscountChanged;
  final ValueChanged<String> onPaymentMethodChanged;
  final VoidCallback onCheckout;

  const CashierCartPanel({
    super.key,
    required this.cart,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.isCheckingOut,
    required this.onUpdateQuantity,
    required this.onRemoveFromCart,
    required this.onClearCart,
    required this.onDiscountChanged,
    required this.onPaymentMethodChanged,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cart header
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.teal[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السلة (${cart.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, color: Colors.red),
                onPressed: cart.isEmpty ? null : onClearCart,
              ),
            ],
          ),
        ),

        // Cart items
        Expanded(
          child: cart.isEmpty
              ? const Center(
                  child: Text(
                    'السلة فارغة',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          item.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          '${item.price.toStringAsFixed(0)} د.ع / ${item.unit}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 18,
                              ),
                              onPressed: () => onUpdateQuantity(index, -1),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 18,
                              ),
                              onPressed: () => onUpdateQuantity(index, 1),
                            ),
                            Text(
                              '${item.total.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red,
                              ),
                              onPressed: () => onRemoveFromCart(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Totals + Checkout
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المجموع الفرعي:', style: TextStyle(fontSize: 14)),
                  Text(
                    '${subtotal.toStringAsFixed(0)} د.ع',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              if (discount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الخصم:',
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                    Text(
                      '-${discount.toStringAsFixed(0)} د.ع',
                      style: const TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ],
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الإجمالي:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    '${total.toStringAsFixed(0)} د.ع',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('خصم: '),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: '0',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) =>
                          onDiscountChanged(double.tryParse(v) ?? 0),
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: paymentMethod,
                    items: ['نقداً', 'بطاقة', 'محفظة']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => onPaymentMethodChanged(v ?? 'نقداً'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  icon: isCheckingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(LucideIcons.receipt),
                  label: Text(
                    isCheckingOut
                        ? 'جاري...'
                        : 'إتمام البيع (${total.toStringAsFixed(0)} د.ع)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: isCheckingOut ? null : onCheckout,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
