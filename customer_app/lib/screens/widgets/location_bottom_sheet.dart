import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../controllers/home_controller.dart';
import '../location_picker_screen.dart';

void showLocationBottomSheet(BuildContext context) {
  final controller = Get.find<HomeController>();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
  final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;
  final surfaceColor = isDark ? AppTheme.surfaceDark : Colors.white;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Obx(() {
          final String userLocation = controller.userAddress.value.isNotEmpty
              ? controller.userAddress.value
              : (controller.selectedBranch.value?['address'] ?? 'deliver_to_location'.tr);
          final bool inZone = controller.isInDeliveryZone.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'delivery_location'.tr,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: themeTextColor, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Current location card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                      ),
                      child: const Icon(LucideIcons.mapPin, size: 20, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('current_location'.tr, style: TextStyle(fontSize: 11, color: themeTextSecColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(userLocation, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: themeTextColor, fontFamily: 'Cairo'),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: inZone ? AppTheme.primary.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(inZone ? LucideIcons.checkCircle : LucideIcons.xCircle,
                        size: 16, color: inZone ? AppTheme.primary : Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Delivery status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: inZone ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(inZone ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                        size: 16, color: inZone ? AppTheme.primary : Colors.red.shade500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          inZone ? 'delivery_available'.tr : 'delivery_unavailable'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: inZone ? AppTheme.primaryDark : Colors.red.shade700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final result = await Get.to(() => const LocationPickerScreen(), transition: Transition.fadeIn);
                          if (result != null && result is Map<String, dynamic>) {
                            await controller.updateUserLocation(result['latitude'], result['longitude'], result['address']);
                          }
                        },
                        icon: const Icon(LucideIcons.map, size: 16),
                        label: Text('choose_from_map'.tr, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await controller.findBestBranchByLocation();
                        },
                        icon: const Icon(LucideIcons.navigation, size: 16),
                        label: Text('use_current_location'.tr, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        }),
      );
    },
  );
}
