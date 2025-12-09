import 'dart:math';

import 'package:flutter/material.dart';

/// Confetti particle for celebration animation
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final Animation<double> animation;

  ConfettiPainter({required this.particles, required this.animation})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update(animation.value);
      particle.draw(canvas);
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

class ConfettiParticle {
  double x;
  double y;
  final double initialX;
  final double initialY;
  final double speedX;
  final double speedY;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.initialX,
    required this.initialY,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  }) : x = initialX,
       y = initialY;

  void update(double progress) {
    x = initialX + speedX * progress;
    y = initialY + speedY * progress + (progress * progress * 500);
  }

  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: size, height: size),
      paint,
    );
    canvas.restore();
  }
}

/// Confetti overlay widget
class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool show;

  const ConfettiOverlay({super.key, required this.child, required this.show});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _generateParticles();
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _generateParticles();
      _controller.forward(from: 0);
    }
  }

  void _generateParticles() {
    _particles = List.generate(50, (index) {
      final colors = [
        Colors.blue,
        Colors.purple,
        Colors.pink,
        Colors.orange,
        Colors.yellow,
        Colors.green,
      ];

      return ConfettiParticle(
        initialX: _random.nextDouble() * 400 - 200,
        initialY: -50,
        speedX: _random.nextDouble() * 200 - 100,
        speedY: _random.nextDouble() * 300 + 200,
        size: _random.nextDouble() * 10 + 5,
        color: colors[_random.nextInt(colors.length)],
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: _random.nextDouble() * 4 - 2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.show)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ConfettiPainter(
                  particles: _particles,
                  animation: _controller,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
