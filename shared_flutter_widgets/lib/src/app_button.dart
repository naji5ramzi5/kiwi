import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Reusable primary button widget
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final txtColor = textColor ?? Colors.white;

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, valueColor: AlwaysStoppedAnimation(txtColor)))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: txtColor),
                const SizedBox(width: 8)
              ],
              Text(text,
                  style: TextStyle(
                      color: txtColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          );

    final style = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: bgColor,
            side: BorderSide(color: bgColor),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: txtColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
          );

    final button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed, style: style, child: child)
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: style,
            child: child);

    return width != null ? SizedBox(width: width, child: button) : button;
  }
}
