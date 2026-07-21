import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A prayer-bead (Tasbeh) styled circular loading indicator.
/// Usage: TasbehLoader(beadCount: 33, size: 120)
class TasbehLoader extends StatefulWidget {
  final int beadCount;
  final double size;
  final Color beadColor;
  final Color activeBeadColor;
  final Color stringColor;

  const TasbehLoader({
    super.key,
    this.beadCount = 33,
    this.size = 120,
    this.beadColor = AppColors.cardLight,
    this.activeBeadColor = AppColors.gold,
    this.stringColor = AppColors.textMuted,
  });

  @override
  State<TasbehLoader> createState() => _TasbehLoaderState();
}

class _TasbehLoaderState extends State<TasbehLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _TasbehPainter(
                  progress: _controller.value,
                  beadCount: widget.beadCount,
                  beadColor: widget.beadColor,
                  activeBeadColor: widget.activeBeadColor,
                  stringColor: widget.stringColor,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Loading...',
          style: TextStyle(
            color: widget.activeBeadColor.withValues(alpha: 0.8),
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TasbehPainter extends CustomPainter {
  final double progress;
  final int beadCount;
  final Color beadColor;
  final Color activeBeadColor;
  final Color stringColor;

  _TasbehPainter({
    required this.progress,
    required this.beadCount,
    required this.beadColor,
    required this.activeBeadColor,
    required this.stringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // String (circle outline connecting beads)
    final stringPaint = Paint()
      ..color = stringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, stringPaint);

    // Continuous active position moving around the circle
    final activePosition = progress * beadCount;

    for (int i = 0; i < beadCount; i++) {
      final angle = (2 * pi * i / beadCount) - pi / 2;
      final beadCenter = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      // Calculate distance for smooth transition (handles circular wrap-around)
      double distance = (i - activePosition).abs();
      if (distance > beadCount / 2) {
        distance = beadCount - distance;
      }

      // Smooth intensity based on distance
      double intensity = 0.0;
      if (distance < 2.0) {
        // Curve to make it very smooth
        intensity = 1.0 - (distance / 2.0);
        intensity = Curves.easeOut.transform(intensity);
      }

      // Base radius 4.0, max active radius 5.5 (smaller beads)
      final beadRadius = 4.0 + (1.5 * intensity);

      final paint = Paint()
        ..color = Color.lerp(beadColor, activeBeadColor, intensity)!
        ..style = PaintingStyle.fill;

      canvas.drawCircle(beadCenter, beadRadius, paint);

      // Softer, elegant glow
      if (intensity > 0.1) {
        final glowPaint = Paint()
          ..color = activeBeadColor.withValues(alpha: 0.2 * intensity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(beadCenter, beadRadius + (3.0 * intensity), glowPaint);
      }
    }

    // Center "Imam" bead (smaller than before)
    final imamPaint = Paint()..color = beadColor;
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius),
      7.5,
      imamPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TasbehPainter oldDelegate) => true;
}

// Example usage:
// class LoadingScreen extends StatelessWidget {
//   const LoadingScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(child: TasbehLoader()),
//     );
//   }
// }
