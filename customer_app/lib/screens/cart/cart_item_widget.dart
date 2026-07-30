import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';

class CartItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDark;
  final Color themeTextColor;
  final Color themeTextSecColor;
  final VoidCallback onRemove;
  final VoidCallback onRemoveAll;
  final VoidCallback onAdd;
  final num quantity;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.isDark,
    required this.themeTextColor,
    required this.themeTextSecColor,
    required this.onRemove,
    required this.onRemoveAll,
    required this.onAdd,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final String id = item['id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CachedNetworkImage(
              imageUrl: item['image'],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: isDark ? Colors.grey[850] : Colors.grey[100]),
              errorWidget: (_, __, ___) => const Icon(LucideIcons.image, size: 30, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['title'],
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: themeTextColor, fontFamily: 'Cairo'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: onRemoveAll,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(LucideIcons.x, size: 14, color: Colors.red.shade400),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${item['unit'] ?? 'unit_kg'.tr}',
                      style: TextStyle(fontSize: 11, color: themeTextSecColor, fontFamily: 'Cairo'),
                    ),
                    const SizedBox(width: 6),
                    Builder(builder: (context) {
                      final unitType = item['unit_type']?.toString() ?? 'kilogram';
                      final isDecimal = ['kilogram', 'kg', 'gram', 'g', 'liter', 'l', 'milliliter', 'ml'].contains(unitType.toLowerCase());
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isDecimal ? Colors.blue.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['unit']?.toString() ?? (isDecimal ? 'unit_kg'.tr : 'unit_piece'.tr),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDecimal ? Colors.blue : Colors.amber.shade800, fontFamily: 'Cairo'),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item['price']} ${'currency_iqd'.tr}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppTheme.primaryBright : AppTheme.primaryDark,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Row(
                      children: [
                        _buildQuantityBtn(LucideIcons.minus, onTap: onRemove),
                        const SizedBox(width: 12),
                        Text(
                          quantity == quantity.roundToDouble() ? '${quantity.toInt()}' : quantity.toStringAsFixed(1),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: themeTextColor, fontFamily: 'Cairo'),
                        ),
                        const SizedBox(width: 12),
                        _buildQuantityBtn(LucideIcons.plus, isPrimary: true, onTap: onAdd),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityBtn(IconData icon, {bool isPrimary = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primary : (isDark ? Colors.grey.shade800 : AppTheme.background),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isPrimary
              ? Colors.white
              : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary),
        ),
      ),
    );
  }
}
