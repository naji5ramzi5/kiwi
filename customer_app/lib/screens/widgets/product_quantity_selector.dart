import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';

class ProductQuantitySelector extends StatelessWidget {
  final num quantity;
  final num maxStock;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ProductQuantitySelector({
    super.key,
    required this.quantity,
    required this.maxStock,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildQtyButton(LucideIcons.minus, onDecrement, isPrimary: false),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child:             Text(
              quantity == quantity.roundToDouble() ? '${quantity.toInt()}' : quantity.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeTextColor,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          _buildQtyButton(LucideIcons.plus, onIncrement, isPrimary: true),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isPrimary ? Colors.green : const Color(0xFFE8E8E8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: isPrimary ? Colors.white : Colors.black54),
      ),
    );
  }
}
