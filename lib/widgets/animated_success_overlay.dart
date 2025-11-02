import 'package:flutter/material.dart';

class AnimatedSuccessOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration displayDuration;

  const AnimatedSuccessOverlay({
    Key? key,
    required this.onComplete,
    this.displayDuration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<AnimatedSuccessOverlay> createState() => _AnimatedSuccessOverlayState();
}

class _AnimatedSuccessOverlayState extends State<AnimatedSuccessOverlay>
    with TickerProviderStateMixin {
  late AnimationController _checkmarkController;
  late AnimationController _fadeOutController;
  late AnimationController _streakController;
  late AnimationController _textSlideController;
  late AnimationController _progressController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();

    // Screen entrance animation (fade in + scale)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Checkmark animation with bounce
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    // Diagonal light streak animation
    _streakController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Text slide up animation
    _textSlideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Progress bar animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Fade out animation
    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Start all animations in sequence
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _checkmarkController.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _textSlideController.forward();
      }
    });

    // After display duration, trigger fade out and exit
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _fadeOutController.forward().then((_) {
          if (mounted) {
            widget.onComplete();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _fadeOutController.dispose();
    _streakController.dispose();
    _textSlideController.dispose();
    _progressController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeOutController),
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1))
            .animate(_fadeOutController),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0)
              .animate(_scaleController),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4ade80),
                  const Color(0xFF16a34a),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16a34a).withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 15),
                ),
                // Inner glow
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Stack(
                  children: [
                    // Animated diagonal light streak background
                    Positioned.fill(
                      child: ClipPath(
                        clipper: _DiagonalClipper(),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-2, -2),
                            end: const Offset(2, 2),
                          ).animate(_streakController),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Main content column
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated checkmark with scale and bounce
                        ScaleTransition(
                          scale: Tween<double>(begin: 0, end: 1)
                              .animate(
                                CurvedAnimation(
                                  parent: _checkmarkController,
                                  curve: Curves.elasticOut,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0, end: 1)
                                .animate(_checkmarkController),
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 54,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Main title - animated slide up with fade
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _textSlideController,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0, end: 1)
                                .animate(_textSlideController),
                            child: Text(
                              'Login Successful',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 32,
                                    letterSpacing: 0.3,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Subtitle - animated fade in with delay
                        FadeTransition(
                          opacity: Tween<double>(begin: 0, end: 1)
                              .animate(
                                CurvedAnimation(
                                  parent: _textSlideController,
                                  curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
                                ),
                              ),
                          child: Text(
                            'Welcome back! Loading your account...',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Gradient animated progress bar
                        FadeTransition(
                          opacity: Tween<double>(begin: 0, end: 1)
                              .animate(
                                CurvedAnimation(
                                  parent: _textSlideController,
                                  curve: const Interval(0.5, 1.0),
                                ),
                              ),
                          child: Column(
                            children: [
                              // Gradient progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Background gradient
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.blue[300]?.withOpacity(0.3) ?? Colors.blue,
                                              Colors.green[300]?.withOpacity(0.5) ?? Colors.green,
                                              Colors.lightGreen[300]?.withOpacity(0.3) ?? Colors.lightGreen,
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Animated progress fill
                                      AnimatedBuilder(
                                        animation: _progressController,
                                        builder: (context, child) {
                                          return Align(
                                            alignment: Alignment.centerLeft,
                                            child: FractionallySizedBox(
                                              widthFactor: _progressController.value,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                    colors: [
                                                      Colors.blue[400] ?? Colors.blue,
                                                      Colors.green[400] ?? Colors.green,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Circular loader with smooth rotation
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom clipper for diagonal light streak
class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.addPolygon(
      [
        Offset(0, 0),
        Offset(size.width * 0.3, 0),
        Offset(size.width, size.height * 0.7),
        Offset(size.width, size.height),
        Offset(size.width * 0.7, size.height),
        Offset(0, size.height * 0.3),
      ],
      true,
    );
    return path;
  }

  @override
  bool shouldReclip(_DiagonalClipper oldClipper) => false;
}

/// Animated checkmark with confetti-like effect
class AnimatedCheckmark extends StatefulWidget {
  final AnimationController controller;

  const AnimatedCheckmark({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with TickerProviderStateMixin {
  late List<AnimationController> _confettiControllers;

  @override
  void initState() {
    super.initState();
    _confettiControllers = List.generate(
      8,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    widget.controller.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        // Stagger confetti animations
        for (int i = 0; i < _confettiControllers.length; i++) {
          Future.delayed(Duration(milliseconds: 200 + i * 50), () {
            if (mounted) {
              _confettiControllers[i].forward();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _confettiControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti pieces
        ..._buildConfetti(),
        // Center checkmark
        ScaleTransition(
          scale: Tween<double>(begin: 0, end: 1)
              .animate(widget.controller),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildConfetti() {
    final angles = [0, 45, 90, 135, 180, 225, 270, 315];
    return List.generate(
      angles.length,
      (index) {
        final angle = angles[index] * 3.14159 / 180;
        final distance = 80.0;

        return Transform.translate(
          offset: Offset(
            distance * 0.5 * (1 - _confettiControllers[index].value),
            distance * 0.5 * (1 - _confettiControllers[index].value),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0)
                .animate(_confettiControllers[index]),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        );
      },
    );
  }
}
