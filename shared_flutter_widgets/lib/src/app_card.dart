import 'package:flutter/material.dart';
import 'app_spacing.dart';

/// Reusable card container with shadow
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppSpacing.borderRadiusXl,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}
