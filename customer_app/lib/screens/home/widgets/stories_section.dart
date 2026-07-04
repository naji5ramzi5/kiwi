import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../controllers/home_controller.dart';

// Static fallback stories
const List<Map<String, String>> _staticStories = [
  {
    'name': 'خضروات',
    'imageUrl': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=200&q=80',
    'emoji': '🥦',
  },
  {
    'name': 'عروض',
    'imageUrl': 'https://images.unsplash.com/photo-1534483509719-3feaee7c30da?auto=format&fit=crop&w=200&q=80',
    'emoji': '🔥',
  },
  {
    'name': 'فواكه',
    'imageUrl': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=200&q=80',
    'emoji': '🍊',
  },
  {
    'name': 'جديد',
    'imageUrl': 'https://images.unsplash.com/photo-1488459716781-31db52582fe9?auto=format&fit=crop&w=200&q=80',
    'emoji': '✨',
  },
  {
    'name': 'تمور',
    'imageUrl': 'https://images.unsplash.com/photo-1596431989042-49764de3d037?auto=format&fit=crop&w=200&q=80',
    'emoji': '🌴',
  },
];

class StoriesSection extends StatelessWidget {
  StoriesSection({super.key});

  final HomeController controller = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoadingStories.value) {
        return _buildShimmer(isDark);
      }

      final dbStories = controller.storyGroups;
      final List<Map<String, String>> displayStories = dbStories.isNotEmpty
          ? dbStories
              .map((s) => {
                    'name': (s['name'] ?? s['title'] ?? 'قصة').toString(),
                    'imageUrl': (s['thumbnail_url'] ?? '').toString(),
                    'emoji': '',
                  })
              .toList()
          : _staticStories;

      return SizedBox(
        height: 105,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: displayStories.length,
          itemBuilder: (context, index) {
            final story = displayStories[index];
            final isFirst = index == 0; // Highlight first story
            return _buildStoryItem(story, isFirst, isDark);
          },
        ),
      );
    });
  }

  Widget _buildStoryItem(Map<String, String> story, bool isActive, bool isDark) {
    return GestureDetector(
      onTap: () {
        Get.snackbar(
          '🔔 قريباً',
          'نظام القصص والعروض سيتم تفعيله قريباً',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      },
      child: Container(
        width: 76,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            // Story Ring
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFf7971e),
                          Color(0xFFffd200),
                          Color(0xFF21b952),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          AppTheme.primary.withOpacity(0.5),
                          AppTheme.primaryDark.withOpacity(0.5),
                        ],
                      ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1C2B1E) : Colors.white,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: story['imageUrl']!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: story['imageUrl']!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildEmojiCenter(story['emoji'] ?? ''),
                          errorWidget: (context, url, error) => _buildEmojiCenter(story['emoji'] ?? ''),
                        )
                      : _buildEmojiCenter(story['emoji'] ?? ''),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story['name'] ?? '',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary)
                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary),
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiCenter(String emoji) {
    return Container(
      color: AppTheme.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          emoji.isNotEmpty ? emoji : '🛒',
          style: const TextStyle(fontSize: 26),
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return SizedBox(
      height: 105,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          width: 76,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
