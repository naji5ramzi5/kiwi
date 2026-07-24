import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';

class CartCheckoutPanel extends StatelessWidget {
  final bool isDark;
  final Color themeTextColor;
  final Color themeTextSecColor;
  final String subtotal;
  final String deliveryFee;
  final String discount;
  final String total;
  final bool isPlacingOrder;
  final bool hasActiveOrder;
  final VoidCallback onStartCountdown;
  final TextEditingController couponController;
  final VoidCallback onApplyCoupon;
  final VoidCallback onRemoveCoupon;
  final bool hasCoupon;
  final bool isApplyingCoupon;
  final String couponError;
  final String couponLabel;
  final bool belowMinOrder;
  final String minOrderHint;

  const CartCheckoutPanel({
    super.key,
    required this.isDark,
    required this.themeTextColor,
    required this.themeTextSecColor,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = '0',
    required this.total,
    required this.isPlacingOrder,
    required this.hasActiveOrder,
    required this.onStartCountdown,
    required this.couponController,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
    this.hasCoupon = false,
    this.isApplyingCoupon = false,
    this.couponError = '',
    this.couponLabel = '',
    this.belowMinOrder = false,
    this.minOrderHint = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow('subtotal'.tr, '$subtotal ${'currency_iqd'.tr}'),
            const SizedBox(height: 10),
            _buildSummaryRow('delivery_fee'.tr, '$deliveryFee ${'currency_iqd'.tr}'),
            const SizedBox(height: 10),
            if (discount != '0' && hasCoupon)
              _buildSummaryRow('discount_with_coupon'.trParams({'coupon': couponLabel}), '- $discount ${'currency_iqd'.tr}',
                  isDiscount: true),
            const SizedBox(height: 10),
            _buildCouponSection(),
            if (belowMinOrder)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  minOrderHint,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Row(
              children: [
                Icon(LucideIcons.creditCard, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'cash_on_delivery'.tr,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Cairo'),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(LucideIcons.leaf, size: 16, color: AppTheme.primary),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('grand_total'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: themeTextColor, fontFamily: 'Cairo')),
                Text('$total ${'currency_iqd'.tr}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(height: 24),
            _OrderConfirmButton(
              onConfirm: onStartCountdown,
              isLoading: isPlacingOrder,
              disabled: hasActiveOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: themeTextSecColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isDiscount ? Colors.red : themeTextColor, fontFamily: 'Cairo')),
      ],
    );
  }

  Widget _buildCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasCoupon) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: couponController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'coupon_hint'.tr,
                    hintStyle: TextStyle(fontSize: 12, color: themeTextSecColor),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              isApplyingCoupon
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : ElevatedButton(
                      onPressed: onApplyCoupon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text('apply'.tr, style: const TextStyle(fontFamily: 'Cairo')),
                    ),
            ],
          ),
          if (couponError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                couponError,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.badgeCheck, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'coupon_applied'.trParams({'code': couponLabel}),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onRemoveCoupon,
                  child: const Icon(Icons.close, size: 16, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

class _OrderConfirmButton extends StatelessWidget {
  final VoidCallback onConfirm;
  final bool isLoading;
  final bool disabled;

  const _OrderConfirmButton({required this.onConfirm, required this.isLoading, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(18)),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return ElevatedButton(
      onPressed: disabled ? null : onConfirm,
      style: ElevatedButton.styleFrom(
        backgroundColor: disabled ? Colors.grey : AppTheme.primary,
        disabledBackgroundColor: Colors.grey.shade300,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      child: Text(
        disabled ? 'active_order'.tr : 'confirm_order'.tr,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: disabled ? Colors.grey.shade600 : Colors.white, fontFamily: 'Cairo'),
      ),
    );
  }
}
