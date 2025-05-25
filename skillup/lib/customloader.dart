import 'package:flutter/material.dart';
import 'dart:math';

class CustomSpinner extends StatefulWidget {
  const CustomSpinner({super.key});

  @override
  _CustomSpinnerState createState() => _CustomSpinnerState();
}

class _CustomSpinnerState extends State<CustomSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Transform.rotate(
          angle: _controller.value * 2 * pi,
          child: CustomPaint(
            size: const Size(44, 44),
            painter: SpinnerPainter(_controller.value),
          ),
        ),
      ),
    );
  }
}

class SpinnerPainter extends CustomPainter {
  final double value;
  SpinnerPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final Paint paint = Paint()
      ..shader = SweepGradient(
        colors: [Colors.blue, Colors.purple, Colors.red, Colors.orange],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final angle = pi / 4 * i;
      final length = radius * (0.6 + 0.3 * sin(value * pi * 2 + angle));
      canvas.drawLine(
        center + Offset(radius * cos(angle), radius * sin(angle)),
        center + Offset(length * cos(angle), length * sin(angle)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
