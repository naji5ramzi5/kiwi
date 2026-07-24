import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';

class LocationSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onBack;
  final VoidCallback onSearch;

  const LocationSearchBar({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.surfaceDark : Colors.white).withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.grey),
            onPressed: onBack,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: 'search_neighborhood'.tr,
                hintStyle: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppTheme.primary),
            onPressed: onSearch,
          ),
        ],
      ),
    );
  }
}
