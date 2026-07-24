import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';

class ProductImageHero extends StatelessWidget {
  final String image;
  final String heroTag;
  final double screenHeight;
  final double overlap;
  final double curveRadius;

  const ProductImageHero({
    super.key,
    required this.image,
    required this.heroTag,
    required this.screenHeight,
    required this.overlap,
    required this.curveRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipPath(
      clipper: _CurvedBottomClipper(curveHeight: curveRadius, overlap: overlap),
      child: Container(
        height: screenHeight * 0.50,
        width: double.infinity,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              color: isDark ? const Color(0xFF0F2D1A) : const Color(0xFFF0FDF4),
              child: Hero(
                tag: heroTag,
                child: CachedNetworkImage(
                  imageUrl: image,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark ? const Color(0xFF1C2B1E) : const Color(0xFFF0FDF4),
                    child: const Center(
                      child: SizedBox(
                        width: 40, height: 40,
                        child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: AppTheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvedBottomClipper extends CustomClipper<Path> {
  final double curveHeight;
  final double overlap;

  _CurvedBottomClipper({this.curveHeight = 45, this.overlap = 25});

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - curveHeight)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height - curveHeight + overlap,
        size.width,
        size.height - curveHeight,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
