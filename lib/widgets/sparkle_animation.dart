import 'dart:math';
import 'package:flutter/material.dart';

class SparkleAnimation extends StatefulWidget {
  const SparkleAnimation({super.key, this.trigger = false});
  final bool trigger;

  @override
  State<SparkleAnimation> createState() => _SparkleAnimationState();
}

class _SparkleAnimationState extends State<SparkleAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    if (widget.trigger) {
      _spawnParticles();
    }
  }

  @override
  void didUpdateWidget(covariant SparkleAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _spawnParticles();
    }
  }

  void _spawnParticles() {
    _particles.clear();
    // Spawn 18 particles around the center
    for (int i = 0; i < 18; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 40.0 + _random.nextDouble() * 60.0;
      final size = 4.0 + _random.nextDouble() * 5.0;
      _particles.add(
        _Particle(
          angle: angle,
          speed: speed,
          size: size,
          color: _random.nextBool()
              ? const Color(0xFFCFAE68) // Gold
              : Colors.white,
          maxLife: 0.6 + _random.nextDouble() * 0.4,
        ),
      );
    }
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isAnimating) return const SizedBox.shrink();

    return CustomPaint(
      size: Size.infinite,
      painter: _SparklePainter(
        particles: _particles,
        progress: _controller.value,
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.maxLife,
  });

  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double maxLife;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.particles, required this.progress});
  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final lifeFactor = progress / p.maxLife;
      if (lifeFactor > 1.0) continue;

      final distance = p.speed * progress;
      final x = center.dx + cos(p.angle) * distance;
      final y = center.dy + sin(p.angle) * distance;

      final alpha = (1.0 - lifeFactor).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: alpha);

      // Draw diamond star shape or circle
      final path = Path()
        ..moveTo(x, y - p.size * (1.0 - lifeFactor))
        ..lineTo(x + p.size * 0.5 * (1.0 - lifeFactor), y)
        ..lineTo(x, y + p.size * (1.0 - lifeFactor))
        ..lineTo(x - p.size * 0.5 * (1.0 - lifeFactor), y)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}
