import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../controllers/home_controller.dart';

// Static fallback banners - always shown even without DB data
const List<Map<String, String>> _staticBanners = [
  {
    'imageUrl': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=900&q=80',
    'title': 'خضروات طازجة يومياً',
    'subtitle': 'مباشرة من المزارع إلى بيتك',
    'color': '0xFF16A34A',
  },
  {
    'imageUrl': 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=900&q=80',
    'title': 'توصيل سريع خلال ساعة',
    'subtitle': 'اطلب الآن واستلم في أسرع وقت',
    'color': '0xFF0369A1',
  },
  {
    'imageUrl': 'https://images.unsplash.com/photo-1488459716781-31db52582fe9?auto=format&fit=crop&w=900&q=80',
    'title': 'عروض يومية حصرية',
    'subtitle': 'خصومات تصل إلى 40% على المنتجات المختارة',
    'color': '0xFFB45309',
  },
];

class BannersSection extends StatefulWidget {
  const BannersSection({super.key});

  @override
  State<BannersSection> createState() => _BannersSectionState();
}

class _BannersSectionState extends State<BannersSection> {
  int _currentIndex = 0;
  final HomeController controller = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.banners.isNotEmpty
          ? controller.banners
              .map((b) => _BannerItem(
                    imageUrl: b['image_url'] ?? '',
                    title: b['title'] ?? '',
                    subtitle: b['subtitle'] ?? '',
                    color: null,
                  ))
              .toList()
          : _staticBanners
              .map((b) => _BannerItem(
                    imageUrl: b['imageUrl'] ?? '',
                    title: b['title'] ?? '',
                    subtitle: b['subtitle'] ?? '',
                    color: Color(int.parse(b['color']!)),
                  ))
              .toList();

      return Column(
        children: [
          CarouselSlider.builder(
            itemCount: items.length,
            itemBuilder: (context, index, realIndex) {
              final item = items[index];
              return _buildBannerCard(item);
            },
            options: CarouselOptions(
              height: 190,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayCurve: Curves.easeInOutCubic,
              enlargeCenterPage: false,
              viewportFraction: 1.0,
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSmoothIndicator(
            activeIndex: _currentIndex,
            count: items.length,
            effect: ExpandingDotsEffect(
              dotHeight: 7,
              dotWidth: 7,
              expansionFactor: 3,
              spacing: 5,
              activeDotColor: AppTheme.primary,
              dotColor: Colors.grey.shade300,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBannerCard(_BannerItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          item.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: item.color?.withOpacity(0.2) ?? Colors.green.withOpacity(0.2),
                  ),
                  errorWidget: (context, url, error) => _buildGradientBg(item.color),
                )
              : _buildGradientBg(item.color),

          // Dark overlay gradient for text
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.black.withOpacity(0.65),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Text content (Right aligned - Arabic)
          Positioned(
            top: 0,
            bottom: 0,
            right: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🔥 عرض خاص',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (item.title.isNotEmpty)
                  Text(
                    item.title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      height: 1.2,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'اطلب الآن',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBg(Color? color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color ?? AppTheme.primary,
            (color ?? AppTheme.primary).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _BannerItem {
  final String imageUrl;
  final String title;
  final String subtitle;
  final Color? color;

  _BannerItem({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.color,
  });
}
