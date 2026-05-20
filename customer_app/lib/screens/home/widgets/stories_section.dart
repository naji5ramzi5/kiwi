import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_theme.dart';
import '../../../controllers/home_controller.dart';

class StoriesSection extends StatelessWidget {
  StoriesSection({super.key});

  final HomeController controller = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingStories.value) {
        return _buildShimmerLoading();
      }

      if (controller.storyGroups.isEmpty) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        height: 110,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: controller.storyGroups.length,
          itemBuilder: (context, index) {
            final story = controller.storyGroups[index];
            final isNew = story['is_active'] == true;

            return GestureDetector(
              onTap: () {
                // Future: Navigate to story full view
                Get.snackbar('Coming Soon', 'نظام القصص سيتم تفعيله قريباً للعروض الحصرية', 
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppTheme.primaryDark,
                  colorText: Colors.white
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    // Story Ring (Apple/Insta Style)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isNew
                            ? const LinearGradient(
                                colors: [Color(0xFFf093fb), Color(0xFFf5576c), AppTheme.primary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [Colors.grey[300]!, Colors.grey[300]!],
                              ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: story['thumbnail_url'] ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=300&q=80',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[200]!,
                              highlightColor: Colors.white,
                              child: Container(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      story['title'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isNew ? FontWeight.w800 : FontWeight.w500,
                        color: isNew ? AppTheme.textPrimary : AppTheme.textSecondary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildShimmerLoading() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[200]!,
                highlightColor: Colors.white,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(height: 8),
              Shimmer.fromColors(
                baseColor: Colors.grey[200]!,
                highlightColor: Colors.white,
                child: Container(width: 50, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
