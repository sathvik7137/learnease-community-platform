import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late AnimationController _glowController;
  late AnimationController _confettiController;
  late AnimationController _textSlideController;
  late AnimationController _progressController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _progressAnimation;
  
  final List<ConfettiParticle> _confettiParticles = [];

  @override
  void initState() {
    super.initState();
    
    // Setup fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    // Setup bounce/scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // Setup shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    
    // Setup glow pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Setup confetti animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    // Setup text slide animation
    _textSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _textSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _textSlideController, curve: Curves.easeOutCubic),
    );
    
    // Setup progress ring animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    
    // Generate confetti particles
    _generateConfetti();
    
    // Start animations with stagger
    _fadeController.forward();
    _scaleController.forward();
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _shimmerController.repeat();
      _glowController.repeat(reverse: true);
      _confettiController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _textSlideController.forward();
      _progressController.forward();
    });
    
    // Navigate to home page after splash
    Timer(const Duration(milliseconds: 3500), () async {
      // Always navigate to MainNavigation (home page) first
      // Login/signup is accessible from Profile section
      const Widget nextPage = MainNavigation();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextPage,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.3);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(animation);
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    });
  }

  void _generateConfetti() {
    final random = math.Random();
    
    // Left corner confetti
    for (int i = 0; i < 12; i++) {
      _confettiParticles.add(ConfettiParticle(
        startX: random.nextDouble() * 80 - 40,
        startY: 800.0,
        color: _getRandomColor(random),
        random: random,
      ));
    }
    
    // Right corner confetti
    for (int i = 0; i < 12; i++) {
      _confettiParticles.add(ConfettiParticle(
        startX: 400 + random.nextDouble() * 80 - 40,
        startY: 800.0,
        color: _getRandomColor(random),
        random: random,
      ));
    }
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFFFECA57),
      const Color(0xFF48DBFB),
      const Color(0xFF1DD1A1),
      const Color(0xFFEE5A6F),
      const Color(0xFFC44569),
      const Color(0xFF4834DF),
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    _confettiController.dispose();
    _textSlideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF3F51B5),
                  Color(0xFF5C6BC0),
                  Color(0xFF7E57C2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Confetti Layer
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(
                  particles: _confettiParticles,
                  progress: _confettiController.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          
          // Main Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo with pulsing glow
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing glow behind logo
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 180 + (_glowAnimation.value * 40),
                              height: 180 + (_glowAnimation.value * 40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3 * _glowAnimation.value),
                                    blurRadius: 60 + (_glowAnimation.value * 20),
                                    spreadRadius: 20 + (_glowAnimation.value * 10),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        
                        // Progress Ring
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return SizedBox(
                              width: 170,
                              height: 170,
                              child: CustomPaint(
                                painter: ProgressRingPainter(
                                  progress: _progressAnimation.value,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        // Logo
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.school,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // App Name with slide animation
                  AnimatedBuilder(
                    animation: _textSlideAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: Opacity(
                          opacity: 1.0 - (_textSlideAnimation.value / 30),
                          child: child,
                        ),
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: const [
                                Colors.white60,
                                Colors.white,
                                Colors.white60,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              begin: Alignment(_shimmerAnimation.value - 1, 0),
                              end: Alignment(_shimmerAnimation.value + 1, 0),
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'LearnEase',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tagline with slide animation
                  AnimatedBuilder(
                    animation: _textSlideAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value + 10),
                        child: Opacity(
                          opacity: 1.0 - (_textSlideAnimation.value / 30),
                          child: child,
                        ),
                      );
                    },
                    child: const Text(
                      'Java & DBMS Tutorials',
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white70,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Confetti Particle Class
class ConfettiParticle {
  final double startX;
  final double startY;
  final Color color;
  final double size;
  final double endX;
  final double endY;
  final double rotation;

  ConfettiParticle({
    required this.startX,
    required this.startY,
    required this.color,
    required math.Random random,
  })  : size = 5 + random.nextDouble() * 3,
        endX = startX + (random.nextDouble() - 0.5) * 150,
        endY = random.nextDouble() * -500 - 100,
        rotation = random.nextDouble() * math.pi * 2;
}

// Confetti Painter
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = particle.startX + (particle.endX - particle.startX) * progress;
      final y = particle.startY + (particle.endY - particle.startY) * progress;
      
      final paint = Paint()
        ..color = particle.color.withOpacity((1.0 - progress) * 0.9)
        ..style = PaintingStyle.fill;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation * progress * 3);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

// Progress Ring Painter
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background circle
    final bgPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 2, bgPaint);
    
    // Progress arc with gradient effect
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.8),
          Colors.amber.shade200,
          Colors.white.withOpacity(0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) => oldDelegate.progress != progress;
}
