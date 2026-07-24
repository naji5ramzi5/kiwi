import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../controllers/main_screen_controller.dart';

/// Shows the "added to cart" popup dialog.
/// Extracted from CartController for separation of UI and business logic.
void showAddedToCartDialog(Map<String, dynamic> product, int qty, String formattedPrice) {
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1C2B1E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'added_to_cart'.tr,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.network(
                        product['image'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.primary.withOpacity(0.1),
                          child: Icon(Icons.shopping_bag, color: AppTheme.primary, size: 28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['title'] ?? '',
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w900,
                            color: Get.isDarkMode ? Colors.white : const Color(0xFF1F2937),
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'quantity_label'.trParams({'qty': qty.toString()}),
                              style: TextStyle(fontSize: 12, color: Get.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600, fontFamily: 'Cairo'),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$formattedPrice ${'currency_iqd'.tr}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.emeraldDark, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.withOpacity(0.2), height: 1),
            const SizedBox(height: 16),
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Get.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'continue_shopping'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.emeraldDark, fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                        Get.find<MainScreenController>().switchTab(2);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.emeraldDeep, AppTheme.emeraldDark]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: AppTheme.emeraldDark.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Text(
                          'go_to_cart'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
