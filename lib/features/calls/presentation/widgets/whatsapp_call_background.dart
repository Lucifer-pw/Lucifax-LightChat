import 'package:flutter/material.dart';

class WhatsAppCallBackground extends StatelessWidget {
  final Widget child;

  const WhatsAppCallBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C161C),
      child: CustomPaint(
        painter: _DoodlePatternPainter(),
        child: child,
      ),
    );
  }
}

class _DoodlePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Draw repeating pattern of subtle icons/doodles
    const double stepX = 80;
    const double stepY = 80;

    for (double y = 20; y < size.height; y += stepY) {
      for (double x = 20; x < size.width; x += stepX) {
        final int index = ((x / stepX).floor() + (y / stepY).floor()) % 6;
        _drawIcon(canvas, paint, Offset(x, y), index);
      }
    }
  }

  void _drawIcon(Canvas canvas, Paint paint, Offset offset, int type) {
    switch (type) {
      case 0: // Chat bubble
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: offset, width: 22, height: 16),
          const Radius.circular(4),
        );
        canvas.drawRRect(r, paint);
        final path = Path()
          ..moveTo(offset.dx - 4, offset.dy + 8)
          ..lineTo(offset.dx - 8, offset.dy + 13)
          ..lineTo(offset.dx, offset.dy + 8);
        canvas.drawPath(path, paint);
        break;
      case 1: // Heart
        final path = Path();
        path.moveTo(offset.dx, offset.dy + 5);
        path.cubicTo(offset.dx - 8, offset.dy - 5, offset.dx - 8, offset.dy + 7, offset.dx, offset.dy + 12);
        path.cubicTo(offset.dx + 8, offset.dy + 7, offset.dx + 8, offset.dy - 5, offset.dx, offset.dy + 5);
        canvas.drawPath(path, paint);
        break;
      case 2: // Phone receiver
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: offset, width: 14, height: 20),
          const Radius.circular(3),
        );
        canvas.drawRRect(r, paint);
        canvas.drawCircle(Offset(offset.dx, offset.dy + 6), 1.5, paint);
        break;
      case 3: // Musical note
        canvas.drawCircle(Offset(offset.dx - 3, offset.dy + 4), 3, paint);
        canvas.drawLine(Offset(offset.dx, offset.dy + 4), Offset(offset.dx, offset.dy - 6), paint);
        canvas.drawLine(Offset(offset.dx, offset.dy - 6), Offset(offset.dx + 5, offset.dy - 4), paint);
        break;
      case 4: // Smiley face
        canvas.drawCircle(offset, 9, paint);
        canvas.drawCircle(Offset(offset.dx - 3, offset.dy - 2), 1, paint);
        canvas.drawCircle(Offset(offset.dx + 3, offset.dy - 2), 1, paint);
        final arcRect = Rect.fromCircle(center: Offset(offset.dx, offset.dy + 1), radius: 4);
        canvas.drawArc(arcRect, 0.2, 2.7, false, paint);
        break;
      case 5: // Star
        final path = Path()
          ..moveTo(offset.dx, offset.dy - 8)
          ..lineTo(offset.dx + 2.5, offset.dy - 2.5)
          ..lineTo(offset.dx + 8, offset.dy - 2.5)
          ..lineTo(offset.dx + 3.5, offset.dy + 1.5)
          ..lineTo(offset.dx + 5.5, offset.dy + 7.5)
          ..lineTo(offset.dx, offset.dy + 3.5)
          ..lineTo(offset.dx - 5.5, offset.dy + 7.5)
          ..lineTo(offset.dx - 3.5, offset.dy + 1.5)
          ..lineTo(offset.dx - 8, offset.dy - 2.5)
          ..lineTo(offset.dx - 2.5, offset.dy - 2.5)
          ..close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
