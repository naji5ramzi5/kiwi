import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_button.dart';

/// Reusable error state widget with retry button
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(
                  text: 'إعادة المحاولة',
                  onPressed: onRetry,
                  icon: Icons.refresh),
            ],
          ],
        ),
      ),
    );
  }
}
