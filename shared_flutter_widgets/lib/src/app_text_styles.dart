import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shared text styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
      fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary);
  static const TextStyle heading2 = TextStyle(
      fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static const TextStyle heading3 = TextStyle(
      fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static const TextStyle heading4 = TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static const TextStyle body =
      TextStyle(fontSize: 14, color: AppColors.textPrimary);
  static const TextStyle bodySmall =
      TextStyle(fontSize: 12, color: AppColors.textSecondary);
  static const TextStyle caption =
      TextStyle(fontSize: 10, color: AppColors.textHint);
  static const TextStyle button =
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white);
  static const TextStyle badge =
      TextStyle(fontSize: 10, fontWeight: FontWeight.bold);
}
