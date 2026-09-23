import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SegmentedStatusCircle extends StatelessWidget {
  final int totalCount;
  final int unviewedCount;
  final Widget child;
  final double size;

  const SegmentedStatusCircle({
    super.key,
    required this.totalCount,
    required this.unviewedCount,
    required this.child,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCount <= 0) {
      return SizedBox(
        width: size,
        height: size,
        child: child,
      );
    }

    return CustomPaint(
      painter: _StatusCirclePainter(
        totalCount: totalCount,
        unviewedCount: unviewedCount,
      ),
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(3.5),
        child: ClipOval(child: child),
      ),
    );
  }
}

class _StatusCirclePainter extends CustomPainter {
  final int totalCount;
  final int unviewedCount;

  _StatusCirclePainter({
    required this.totalCount,
    required this.unviewedCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalCount == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 2.5;

    final viewedPaint = Paint()
      ..color = AppColors.textMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final unviewedPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (totalCount == 1) {
      final paint = unviewedCount > 0 ? unviewedPaint : viewedPaint;
      canvas.drawCircle(center, radius - (strokeWidth / 2), paint);
      return;
    }

    // Multiple segments with gap
    final gapAngle = (totalCount > 1 ? 8.0 : 0.0) * (pi / 180);
    final totalGapAngle = gapAngle * totalCount;
    final arcAngle = ((2 * pi) - totalGapAngle) / totalCount;

    double startAngle = -pi / 2; // Start from 12 o'clock

    final viewedCount = totalCount - unviewedCount;

    for (int i = 0; i < totalCount; i++) {
      // Unviewed items first or ordered
      final isUnviewed = i >= viewedCount;
      final paint = isUnviewed ? unviewedPaint : viewedPaint;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
        startAngle,
        arcAngle,
        false,
        paint,
      );

      startAngle += arcAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusCirclePainter oldDelegate) {
    return oldDelegate.totalCount != totalCount ||
        oldDelegate.unviewedCount != unviewedCount;
  }
}
