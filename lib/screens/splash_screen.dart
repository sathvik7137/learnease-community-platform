import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Main animation controllers
  late AnimationController _backgroundController;
  late AnimationController _logoFadeController;
  late AnimationController _logoScaleController;
  late AnimationController _logoGlowController;
  late AnimationController _ringController;
  late AnimationController _ringPulseController;
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  
  // Animations
  late Animation<double> _backgroundAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoGlowAnimation;
  late Animation<double> _ringAnimation;
  late Animation<double> _ringPulseAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _titleLetterSpacingAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<double> _shimmerAnimation;
  
  final List<FloatingParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    
    // Background gradient transition (0-500ms)
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );
    
    // Logo fade-in (200-800ms)
    _logoFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoFadeController, curve: Curves.easeOut),
    );
    
    // Logo scale-up (200-900ms)
    _logoScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoScaleController, curve: Curves.easeOutBack),
    );
    
    // Logo glow pulse (continuous)
    _logoGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoGlowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoGlowController, curve: Curves.easeInOut),
    );
    
    // Ring drawing animation (400-1400ms)
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _ringAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );
    
    // Ring pulse after complete (1400-1800ms)
    _ringPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _ringPulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ringPulseController, curve: Curves.easeOut),
    );
    
    // Title slide-up and fade (1000-1800ms)
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleSlideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
    );
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );
    _titleLetterSpacingAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );
    
    // Subtitle fade (1400-2000ms)
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 0.7).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut),
    );
    
    // Shimmer sweep (1800-2500ms)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    
    // Floating particles (continuous)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    
    // Generate floating particles
    _generateParticles();
    
    // Start animation sequence with faster timing for quicker startup
    _backgroundController.forward();
    _particleController.repeat();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _logoFadeController.forward();
        _logoScaleController.forward();
        _logoGlowController.repeat(reverse: true);
      }
    });
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ringController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _ringPulseController.forward().then((_) {
          if (mounted) _ringPulseController.reverse();
        });
      }
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _titleController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _subtitleController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _shimmerController.forward();
    });
    
    // Navigate to main screen after 1500ms (reduced for faster startup)
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        final Widget nextPage = MainNavigation(key: MainNavigation.globalKey);
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextPage,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              );
              return FadeTransition(
                opacity: fadeAnimation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }
  
  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(FloatingParticle(
        startX: random.nextDouble() * 400,
        startY: 800 + random.nextDouble() * 200,
        size: 2 + random.nextDouble() * 4,
        speed: 0.3 + random.nextDouble() * 0.5,
        opacity: 0.2 + random.nextDouble() * 0.4,
        random: random,
      ));
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoFadeController.dispose();
    _logoScaleController.dispose();
    _logoGlowController.dispose();
    _ringController.dispose();
    _ringPulseController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _backgroundController,
          _particleController,
          _logoFadeController,
          _logoScaleController,
          _logoGlowController,
          _ringController,
          _ringPulseController,
          _titleController,
          _subtitleController,
          _shimmerController,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Animated gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Color.lerp(
                        const Color(0xFF0D1117),
                        const Color(0xFF1B1F29),
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF1B1F29),
                        const Color(0xFF0D1117),
                        _backgroundAnimation.value,
                      )!,
                    ],
                  ),
                ),
              ),
              
              // Ambient glow - top left
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.15 * _backgroundAnimation.value),
                        const Color(0xFF06B6D4).withOpacity(0.08 * _backgroundAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Ambient glow - bottom right
              Positioned(
                bottom: -120,
                right: -120,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withOpacity(0.12 * _backgroundAnimation.value),
                        const Color(0xFF6366F1).withOpacity(0.06 * _backgroundAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Floating particles
              CustomPaint(
                painter: FloatingParticlesPainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
                size: size,
              ),
              
              // Main content - centered
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with all effects
                    _buildAnimatedLogo(),
                    
                    const SizedBox(height: 60),
                    
                    // Title "LearnEase"
                    _buildAnimatedTitle(),
                    
                    const SizedBox(height: 16),
                    
                    // Subtitle
                    _buildAnimatedSubtitle(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildAnimatedLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Multi-layer glow effects
        if (_logoGlowAnimation.value > 0)
          Container(
            width: 200 + (_logoGlowAnimation.value * 30),
            height: 200 + (_logoGlowAnimation.value * 30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.4 * _logoGlowAnimation.value * _logoFadeAnimation.value),
                  blurRadius: 60 + (_logoGlowAnimation.value * 20),
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.3 * _logoGlowAnimation.value * _logoFadeAnimation.value),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2 * _logoGlowAnimation.value * _logoFadeAnimation.value),
                  blurRadius: 80,
                  spreadRadius: 15,
                ),
              ],
            ),
          ),
        
        // Animated ring with pulse
        if (_ringAnimation.value > 0)
          Transform.scale(
            scale: _ringPulseAnimation.value,
            child: SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: NeonRingPainter(
                  progress: _ringAnimation.value,
                  opacity: _logoFadeAnimation.value,
                ),
              ),
            ),
          ),
        
        // Logo icon with fade and scale
        Opacity(
          opacity: _logoFadeAnimation.value,
          child: Transform.scale(
            scale: _logoScaleAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 3D depth shadow
                Transform.translate(
                  offset: const Offset(3, 3),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Main logo container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1E293B).withOpacity(0.8),
                        const Color(0xFF0F172A).withOpacity(0.9),
                      ],
                    ),
                    border: Border.all(
                      width: 2,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                
                // Shimmer sweep overlay
                if (_shimmerAnimation.value > -1.5 && _shimmerAnimation.value < 1.5)
                  ClipOval(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(_shimmerAnimation.value - 0.5, -1),
                          end: Alignment(_shimmerAnimation.value + 0.5, 1),
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnimatedTitle() {
    return Transform.translate(
      offset: Offset(0, _titleSlideAnimation.value),
      child: Opacity(
        opacity: _titleFadeAnimation.value,
        child: ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFE0E7FF),
                Color(0xFFFFFFFF),
              ],
            ).createShader(bounds);
          },
          child: Text(
            'LearnEase',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: _titleLetterSpacingAnimation.value,
              shadows: [
                Shadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.6 * _titleFadeAnimation.value),
                  offset: const Offset(0, 0),
                  blurRadius: 20,
                ),
                Shadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.4 * _titleFadeAnimation.value),
                  offset: const Offset(0, 0),
                  blurRadius: 30,
                ),
                const Shadow(
                  color: Colors.black45,
                  offset: Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedSubtitle() {
    return Opacity(
      opacity: _subtitleFadeAnimation.value,
      child: Text(
        'Java & DBMS Tutorials',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.7),
          letterSpacing: 2.0,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}


// Floating Particle Class
class FloatingParticle {
  final double startX;
  final double startY;
  final double size;
  final double speed;
  final double opacity;
  final double horizontalDrift;

  FloatingParticle({
    required this.startX,
    required this.startY,
    required this.size,
    required this.speed,
    required this.opacity,
    required math.Random random,
  }) : horizontalDrift = (random.nextDouble() - 0.5) * 30;
}

// Floating Particles Painter
class FloatingParticlesPainter extends CustomPainter {
  final List<FloatingParticle> particles;
  final double progress;

  FloatingParticlesPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate vertical position (looping)
      final totalDistance = size.height + 200;
      final traveled = (progress * particle.speed * totalDistance) % totalDistance;
      final y = particle.startY - traveled;
      
      // Calculate horizontal drift with sine wave
      final driftOffset = math.sin(progress * math.pi * 2 + particle.startX) * particle.horizontalDrift;
      final x = particle.startX + driftOffset;
      
      // Skip if out of bounds
      if (y < -20 || y > size.height + 20 || x < -20 || x > size.width + 20) continue;
      
      // Draw particle with blur effect
      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
      
      // Draw subtle glow
      final glowPaint = Paint()
        ..color = const Color(0xFF3B82F6).withOpacity(particle.opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size * 1.5,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(FloatingParticlesPainter oldDelegate) => true;
}

// Neon Ring Painter
class NeonRingPainter extends CustomPainter {
  final double progress;
  final double opacity;

  NeonRingPainter({required this.progress, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    
    // Background ring (subtle)
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, bgPaint);
    
    // Neon gradient ring
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradientPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          const Color(0xFF06B6D4).withOpacity(opacity), // Cyan
          const Color(0xFF3B82F6).withOpacity(opacity), // Electric blue
          const Color(0xFF8B5CF6).withOpacity(opacity), // Violet
          const Color(0xFF06B6D4).withOpacity(opacity), // Back to cyan
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    // Draw arc based on progress
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      2 * math.pi * progress,
      false,
      gradientPaint,
    );
    
    // Glow effect for completed ring
    if (progress > 0.95) {
      final glowPaint = Paint()
        ..shader = SweepGradient(
          colors: [
            const Color(0xFF06B6D4).withOpacity(0.4 * opacity),
            const Color(0xFF3B82F6).withOpacity(0.4 * opacity),
            const Color(0xFF8B5CF6).withOpacity(0.4 * opacity),
            const Color(0xFF06B6D4).withOpacity(0.4 * opacity),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
      canvas.drawCircle(center, radius, glowPaint);
    }
  }

  @override
  bool shouldRepaint(NeonRingPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}
