import 'dart:math';
import 'package:flutter/material.dart';

class InteractiveTasbeh extends StatelessWidget {
  final int count;
  final int target;
  final int beadCount;
  final double size;
  final Color beadColor;
  final Color activeBeadColor;
  final Color stringColor;
  final Color textColor;
  final VoidCallback onTap;

  const InteractiveTasbeh({
    super.key,
    required this.count,
    required this.target,
    required this.onTap,
    this.beadCount = 33,
    this.size = 180,
    required this.beadColor,
    required this.activeBeadColor,
    required this.stringColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _InteractiveTasbehPainter(
            count: count,
            beadCount: beadCount,
            beadColor: beadColor,
            activeBeadColor: activeBeadColor,
            stringColor: stringColor,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '/ $target',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveTasbehPainter extends CustomPainter {
  final int count;
  final int beadCount;
  final Color beadColor;
  final Color activeBeadColor;
  final Color stringColor;

  _InteractiveTasbehPainter({
    required this.count,
    required this.beadCount,
    required this.beadColor,
    required this.activeBeadColor,
    required this.stringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12; // padding for beads

    // String (circle outline connecting beads)
    final stringPaint = Paint()
      ..color = stringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, stringPaint);

    final currentBeadIndex = count % beadCount;
    // If count > 0 and currentBeadIndex == 0, it means we completed a full circle.
    // We will light up beads up to currentBeadIndex. 
    // If we want to show completed beads, we light up beads where i < currentBeadIndex.
    // But since it's a circular tasbeh, we just light up `currentBeadIndex` beads.

    for (int i = 0; i < beadCount; i++) {
      final angle = (2 * pi * i / beadCount) - pi / 2;
      final beadCenter = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      // Determine if this bead is "completed" or "active"
      // Let's say all beads up to currentBeadIndex are filled
      // Wait, a better logic:
      // If count is 0, none are filled.
      // If count is 1, bead 0 is filled.
      // If count is 33, all 33 are filled.
      // If count is 34, bead 0 of the next round is filled.
      
      bool isFilled = false;
      if (count > 0) {
        if (count % beadCount == 0) {
          isFilled = true; // all filled
        } else {
          isFilled = i < (count % beadCount);
        }
      }

      final isJustTapped = (count > 0 && (count % beadCount == 0 ? i == beadCount - 1 : i == (count % beadCount) - 1));

      final beadRadius = isJustTapped ? 8.0 : 6.0;

      final paint = Paint()
        ..color = isFilled ? activeBeadColor : beadColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(beadCenter, beadRadius, paint);

      if (isJustTapped) {
        final glowPaint = Paint()
          ..color = activeBeadColor.withOpacity(0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(beadCenter, beadRadius + 4, glowPaint);
      }
    }

    // Center "Imam" bead (the marker bead at the top)
    final imamPaint = Paint()..color = (count >= beadCount) ? activeBeadColor : beadColor;
    // Draw an elongated pill-like shape at the top
    final imamRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - radius - 4),
      width: 10,
      height: 20,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(imamRect, const Radius.circular(5)), imamPaint);
  }

  @override
  bool shouldRepaint(covariant _InteractiveTasbehPainter oldDelegate) {
    return oldDelegate.count != count ||
           oldDelegate.beadColor != beadColor ||
           oldDelegate.activeBeadColor != activeBeadColor;
  }
}
