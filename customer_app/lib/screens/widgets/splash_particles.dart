import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashParticles extends StatelessWidget {
  final Animation<double> animation;
  final Size size;

  const SplashParticles({super.key, required this.animation, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: [
            ...List.generate(8, (i) {
              final angle = (i / 8) * 2 * math.pi;
              final phase = animation.value * 2 * math.pi + i * 0.8;
              final dist = 100 + 40 * math.sin(phase);
              return Positioned(
                left: size.width / 2 + dist * math.cos(angle) - 3,
                top: size.height / 2 - 140 + dist * math.sin(angle) - 3,
                child: Opacity(
                  opacity: 0.15 + 0.2 * math.sin(phase),
                  child: Container(
                    width: i % 2 == 0 ? 6 : 4,
                    height: i % 2 == 0 ? 6 : 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  final double animation;

  GridPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025 + 0.015 * animation)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final diagPaint = Paint()
      ..color = Colors.white.withOpacity(0.015 + 0.01 * animation)
      ..strokeWidth = 0.3;
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), diagPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), diagPaint);
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => oldDelegate.animation != animation;
}
