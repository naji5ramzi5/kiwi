import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ProductsShimmerGrid extends StatelessWidget {
  final bool isDark;

  const ProductsShimmerGrid({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.64,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}
