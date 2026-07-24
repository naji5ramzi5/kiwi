import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';

class OrderProductsSection extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isDark;
  final Color textColor;
  final Color textSecColor;

  const OrderProductsSection({
    super.key,
    required this.items,
    required this.isDark,
    required this.textColor,
    required this.textSecColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.shoppingBag, size: 16, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Text('ordered_products'.tr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
              const Spacer(),
              Text('items_count'.trParams({'count': items.length.toString()}), style: TextStyle(fontSize: 11, color: textSecColor, fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildProductItem(item),
          )),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    final name = item['product_name']?.toString() ?? '';
    final qty = item['quantity'] ?? 0;
    final unitPrice = item['unit_price'] ?? 0;
    final totalPrice = item['total_price'] ?? 0;
    final imageUrl = item['image_url']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 52, height: 52,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: isDark ? Colors.grey[850] : Colors.grey[200]),
              errorWidget: (_, __, ___) => Container(
                color: AppTheme.primary.withOpacity(0.1),
                child: const Icon(LucideIcons.image, size: 20, color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo'),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('$qty × $unitPrice ${'currency_iqd'.tr}', style: TextStyle(fontSize: 11, color: textSecColor, fontFamily: 'Cairo')),
                  ],
                ),
              ],
            ),
          ),
          Text('$totalPrice ${'currency_iqd'.tr}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}

class OrderInvoiceSummary extends StatelessWidget {
  final dynamic totalAmount;
  final dynamic deliveryFee;
  final bool isDark;
  final Color textColor;
  final Color textSecColor;

  const OrderInvoiceSummary({
    super.key,
    required this.totalAmount,
    required this.deliveryFee,
    required this.isDark,
    required this.textColor,
    required this.textSecColor,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = (totalAmount is num ? totalAmount.toDouble() : double.tryParse(totalAmount.toString()) ?? 0) -
                     (deliveryFee is num ? deliveryFee.toDouble() : double.tryParse(deliveryFee.toString()) ?? 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.receipt, size: 16, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Text('invoice_summary'.tr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow('subtotal'.tr, '$subtotal ${'currency_iqd'.tr}'),
          const SizedBox(height: 8),
          _summaryRow('delivery_fee'.tr, '$deliveryFee ${'currency_iqd'.tr}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('final_total'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
              Text('$totalAmount ${'currency_iqd'.tr}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Cairo')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: textSecColor, fontFamily: 'Cairo')),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
      ],
    );
  }
}
