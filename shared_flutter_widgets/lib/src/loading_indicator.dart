import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable loading indicator
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingIndicator({super.key, this.message, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
              color: color ?? AppColors.primary, strokeWidth: 3),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ],
      ),
    );
  }
}
