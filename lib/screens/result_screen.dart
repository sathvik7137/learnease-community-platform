import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/course.dart';
import '../services/local_storage.dart';
import '../data/fill_blanks_data.dart';
import 'fill_blank_exercise_screen.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final Topic topic;

  const ResultScreen({
    Key? key,
    required this.score,
    required this.totalQuestions,
    required this.topic,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late AnimationController _confettiController;
  late AnimationController _ringController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _ringAnimation;
  
  final List<ConfettiParticle> _confettiParticles = [];

  @override
  void initState() {
    super.initState();
    
    // Save progress
    LocalStorageService.saveProgress(widget.topic.id, widget.score);
    
    // Fade-in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    
    // Trophy bounce animation
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    
    // Progress ring animation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ringAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic),
    );
    
    // Confetti animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    // Generate confetti particles
    _generateConfetti();
    
    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _bounceController.forward();
      _ringController.forward();
      _confettiController.forward();
    });
  }

  void _generateConfetti() {
    final random = math.Random();
    final screenWidth = 400.0; // Approximate
    
    // Left corner confetti
    for (int i = 0; i < 15; i++) {
      _confettiParticles.add(ConfettiParticle(
        startX: random.nextDouble() * 100 - 50,
        startY: 600.0,
        color: _getRandomColor(random),
        random: random,
      ));
    }
    
    // Right corner confetti
    for (int i = 0; i < 15; i++) {
      _confettiParticles.add(ConfettiParticle(
        startX: screenWidth + random.nextDouble() * 100 - 50,
        startY: 600.0,
        color: _getRandomColor(random),
        random: random,
      ));
    }
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bounceController.dispose();
    _confettiController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentage
    final percentage = (widget.score / widget.totalQuestions) * 100;
    String message;
    Color messageColor;
    IconData messageIcon;

    // Determine message and color based on score
    if (percentage >= 80) {
      message = "Excellent! You've mastered this topic!";
      messageColor = Colors.green;
      messageIcon = Icons.celebration;
    } else if (percentage >= 60) {
      message = "Good job! You're getting there!";
      messageColor = Colors.blue;
      messageIcon = Icons.thumb_up;
    } else if (percentage >= 40) {
      message = "Not bad, review this topic more.";
      messageColor = Colors.orange;
      messageIcon = Icons.lightbulb;
    } else {
      message = "You need to study this topic again.";
      messageColor = Colors.red;
      messageIcon = Icons.refresh;
    }

    const primaryColor = Color(0xFF5C6BC0);
    const accentColor = Color(0xFF7E57C2);

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.5),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Quiz Results',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade100.withOpacity(0.3),
                  Colors.blue.shade100.withOpacity(0.3),
                  Colors.indigo.shade50.withOpacity(0.4),
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
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Trophy with Progress Ring
                    ScaleTransition(
                      scale: _bounceAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated Progress Ring
                          AnimatedBuilder(
                            animation: _ringAnimation,
                            builder: (context, child) {
                              return SizedBox(
                                width: 160,
                                height: 160,
                                child: CustomPaint(
                                  painter: ProgressRingPainter(
                                    progress: _ringAnimation.value * (percentage / 100),
                                    color: messageColor,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Trophy Icon
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade300,
                                  Colors.amber.shade600,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Score Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Your Score',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${widget.score} / ${widget.totalQuestions}',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5C6BC0),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: messageColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Feedback Message Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            messageColor.withOpacity(0.2),
                            messageColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: messageColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(messageIcon, color: messageColor, size: 24),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: messageColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Fill in the Blanks Button
                    _buildGradientButton(
                      context,
                      onPressed: () {
                        final allQuestions = [...javaFillBlankQuestions, ...dbmsFillBlankQuestions];
                        final topicQuestions = allQuestions.where((q) => q.topicId == widget.topic.id).toList();
                        
                        if (topicQuestions.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No fill-in-the-blanks questions available for this topic yet.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FillBlankExerciseScreen(
                              topicName: widget.topic.title,
                              questions: topicQuestions,
                            ),
                          ),
                        );
                      },
                      icon: Icons.edit_note,
                      label: 'Take Fill in the Blanks Quiz',
                      gradientColors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Action Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Try Again Button
                        _buildActionButton(
                          context,
                          onPressed: () => Navigator.pop(context),
                          icon: Icons.refresh,
                          label: 'Try Again',
                          isPrimary: true,
                        ),
                        const SizedBox(width: 16),
                        // Back to Home Button
                        _buildActionButton(
                          context,
                          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                          icon: Icons.home,
                          label: 'Back to Home',
                          isPrimary: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          borderRadius: BorderRadius.circular(16),
          elevation: 6,
          shadowColor: gradientColors.first.withOpacity(0.4),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    const primaryColor = Color(0xFF5C6BC0);
    
    return Material(
      borderRadius: BorderRadius.circular(14),
      elevation: isPrimary ? 4 : 0,
      shadowColor: isPrimary ? primaryColor.withOpacity(0.3) : Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [primaryColor, Color(0xFF7E57C2)],
                  )
                : null,
            border: isPrimary ? null : Border.all(color: primaryColor, width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : primaryColor,
                ),
              ),
            ],
          ),
        ),
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
  })  : size = 6 + random.nextDouble() * 4,
        endX = startX + (random.nextDouble() - 0.5) * 200,
        endY = random.nextDouble() * -400 - 100,
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
        ..color = particle.color.withOpacity(1.0 - progress)
        ..style = PaintingStyle.fill;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation * progress * 4);
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
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius - 4, bgPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) => oldDelegate.progress != progress;
}
