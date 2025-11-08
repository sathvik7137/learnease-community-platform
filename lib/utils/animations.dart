import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

/// Advanced animation utilities for LearnEase app
class AnimationUtils {
  /// Creates a pulsing glow effect animation controller
  static AnimationController createPulseController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  /// Creates a shimmer effect animation controller
  static AnimationController createShimmerController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  /// Creates a wave effect animation controller
  static AnimationController createWaveController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  /// Builds a glassmorphic container with blur and glow
  static Widget buildGlassmorphicContainer({
    required Widget child,
    double blurAmount = 10,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    double opacity = 0.1,
    Color? glowColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: (backgroundColor ?? Colors.white).withOpacity(opacity),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: (glowColor ?? Colors.blue).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: child,
        ),
      ),
    );
  }

  /// Creates an animated gradient background
  static Widget buildAnimatedGradientBackground({
    required Animation<double> animation,
    required List<Color> colors,
    required AlignmentGeometry begin,
    required AlignmentGeometry end,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: begin,
              end: end,
              stops: [
                0.0,
                animation.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  /// Creates a ripple effect widget
  static Widget buildRippleEffect({
    required Animation<double> animation,
    required Color color,
    double maxRadius = 100,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: maxRadius * 2 * animation.value,
          height: maxRadius * 2 * animation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(1 - animation.value),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}

/// 3D Shimmer Particle for confetti effect
class ShimmerParticle {
  double x;
  double y;
  double z; // Depth
  final double size;
  final Color color;
  final double speedX;
  double speedY;
  double rotation;
  final double rotationSpeed;
  double opacity;
  final double gravity;
  double lifetime; // 0 to 1

  ShimmerParticle({
    required this.x,
    required this.y,
    this.z = 0,
    required this.size,
    required this.color,
    required this.speedX,
    required this.speedY,
    required this.rotation,
    required this.rotationSpeed,
    this.opacity = 1.0,
    this.gravity = 0.08,
    this.lifetime = 0.0,
  });

  void update() {
    // Update position
    x += speedX;
    y += speedY;
    speedY += gravity;
    rotation += rotationSpeed;
    
    // Update lifetime
    lifetime += 0.01;
    if (lifetime > 1.0) lifetime = 1.0;
    
    // Fade out based on lifetime
    opacity = 1.0 - (lifetime * 0.3);
  }
}

/// Custom painter for shimmer particles
class ShimmerParticlesPainter extends CustomPainter {
  final List<ShimmerParticle> particles;

  ShimmerParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Calculate scale based on depth (z)
      final scale = 1.0 + (particle.z * 0.3);
      final effectiveSize = particle.size * scale;
      
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.rotation);
      
      // Draw soft glow
      canvas.drawCircle(
        Offset.zero,
        effectiveSize * 1.5,
        Paint()
          ..color = particle.color.withOpacity(particle.opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      
      // Draw particle
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: effectiveSize,
            height: effectiveSize,
          ),
          Radius.circular(effectiveSize * 0.2),
        ),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ShimmerParticlesPainter oldDelegate) => true;
}

/// Pulsing glow effect painter
class PulsingGlowPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double size;

  PulsingGlowPainter({
    required this.animation,
    required this.color,
    this.size = 200,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final glowSize = size * (0.5 + animation.value * 0.5);
    
    // Multiple layers of glow
    for (int i = 3; i >= 0; i--) {
      final layerSize = glowSize * (1 + i * 0.3);
      final layerOpacity = (1 - i * 0.25) * animation.value * 0.3;
      
      canvas.drawCircle(
        center,
        layerSize,
        Paint()
          ..color = color.withOpacity(layerOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, layerSize * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(PulsingGlowPainter oldDelegate) => false;
}

/// Animated wave effect for buttons
class WaveEffect extends StatefulWidget {
  final Widget child;
  final Color waveColor;

  const WaveEffect({
    Key? key,
    required this.child,
    required this.waveColor,
  }) : super(key: key);

  @override
  State<WaveEffect> createState() => _WaveEffectState();
}

class _WaveEffectState extends State<WaveEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerWave() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _triggerWave(),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: WavePainter(
                  animation: _controller,
                  color: widget.waveColor,
                ),
                child: child,
              );
            },
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Wave painter for button hover effects
class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  WavePainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final currentRadius = maxRadius * animation.value;
    
    final paint = Paint()
      ..color = color.withOpacity(0.3 * (1 - animation.value))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => false;
}

/// Parallax effect widget
class ParallaxWidget extends StatefulWidget {
  final Widget child;
  final double intensity;

  const ParallaxWidget({
    Key? key,
    required this.child,
    this.intensity = 0.1,
  }) : super(key: key);

  @override
  State<ParallaxWidget> createState() => _ParallaxWidgetState();
}

class _ParallaxWidgetState extends State<ParallaxWidget> {
  double _offsetY = 0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          setState(() {
            _offsetY = notification.metrics.pixels * widget.intensity;
          });
        }
        return false;
      },
      child: Transform.translate(
        offset: Offset(0, -_offsetY),
        child: widget.child,
      ),
    );
  }
}
