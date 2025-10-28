import 'package:flutter/material.dart';
import 'dart:math';
import '../data/course_content.dart';
import '../models/course.dart';
import '../services/local_storage.dart';
import 'quiz_screen.dart';
import 'package:flutter/services.dart';

// Confetti particle model
class ConfettiParticle {
  double x;
  double y;
  final double size;
  final Color color;
  final double speedX;
  double speedY;
  double rotation;
  final double rotationSpeed;
  double opacity;
  double gravity;
  bool hasLanded;
  double bounceVelocity;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speedX,
    required this.speedY,
    required this.rotation,
    required this.rotationSpeed,
    this.opacity = 1.0,
    this.gravity = 0.15,
    this.hasLanded = false,
    this.bounceVelocity = 0.0,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final Random _random = Random();
  
  // Multiple animation controllers for different elements
  late AnimationController _logoController;
  late AnimationController _logoGlowController;
  late AnimationController _welcomeController;
  late AnimationController _taglineController;
  late AnimationController _contentController;
  
  // Logo animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoGlowAnimation;
  
  // Welcome text animations with gradient shimmer
  late Animation<double> _welcomeScaleAnimation;
  late Animation<double> _welcomeFadeAnimation;
  
  // Tagline animations
  late Animation<double> _taglineSlideAnimation;
  late Animation<double> _taglineFadeAnimation;
  
  // Content fade animation
  late Animation<double> _contentFadeAnimation;
  
  // Button animations
  
  
  late String _selectedQuote;
  
  // Confetti particles list
  final List<ConfettiParticle> _confettiParticles = [];
  
  // Daily challenge state
  bool _isDailyChallengeExpanded = false;
  int _challengesCompletedThisWeek = 0;
  
  // Username for personalized greeting
  

  // List of motivational quotes
  final List<String> _quotes = [
    '"Every expert was once a beginner"',
    '"The only way to learn is to practice"',
    '"Code is like humor. When you have to explain it, it\'s bad"',
    '"First, solve the problem. Then, write the code"',
    '"Learning never exhausts the mind"',
    '"The best time to plant a tree was 20 years ago. The second best time is now"',
    '"Success is not final, failure is not fatal"',
    '"The expert in anything was once a beginner"',
    '"Practice makes progress, not perfection"',
    '"Small daily improvements lead to stunning results"',
    '"Don\'t watch the clock; do what it does. Keep going"',
    '"The secret of getting ahead is getting started"',
    '"Knowledge is power"',
    '"Stay curious, stay learning"',
    '"Every day is a learning opportunity"',
    '"Talk is cheap. Show me the code"',
    '"Make it work, make it right, make it fast"',
    '"Simplicity is the soul of efficiency"',
    '"The best way to predict the future is to invent it"',
    '"Any fool can write code that a computer can understand"',
    '"Good programmers write code. Great programmers rewrite code"',
    '"Programming isn\'t about what you know; it\'s about what you can figure out"',
    '"The most disastrous thing you can ever learn is your first programming language"',
    '"Experience is the name everyone gives to their mistakes"',
    '"Java is to JavaScript what car is to carpet"',
    '"Code never lies, comments sometimes do"',
    '"Fix the cause, not the symptom"',
    '"Debugging is like being a detective in a crime movie"',
    '"In programming, the hard part isn\'t solving problems"',
    '"The computer was born to solve problems that did not exist before"',
    '"Programs must be written for people to read"',
    '"Measuring programming progress by lines of code is like measuring aircraft building progress by weight"',
    '"The best error message is the one that never shows up"',
    '"Before software can be reusable it first has to be usable"',
    '"Walking on water and developing software are easy if both are frozen"',
    '"It\'s not a bug – it\'s an undocumented feature"',
    '"The most important property of a program is whether it accomplishes the intention of its user"',
    '"Deleted code is debugged code"',
    '"Programming is the art of telling another human what one wants the computer to do"',
    '"Sometimes it pays to stay in bed on Monday, rather than spending the rest of the week debugging Monday\'s code"',
    '"Perfection is achieved not when there is nothing more to add, but when there is nothing left to take away"',
    '"Don\'t comment bad code – rewrite it"',
    '"Without requirements or design, programming is the art of adding bugs to an empty text file"',
    '"The function of good software is to make the complex appear simple"',
    '"You might not think that programmers are artists, but programming is an extremely creative profession"',
    '"Learning to write programs stretches your mind"',
    '"Every great developer you know got there by solving problems they were unqualified to solve"',
    '"Be curious. Read widely. Try new things. What people call intelligence is really curiosity"',
    '"The only way to do great work is to love what you do"',
    '"Don\'t let yesterday take up too much of today"',
  ];

  @override
  void initState() {
    super.initState();
    
    // Select a random quote
    _selectedQuote = _quotes[_random.nextInt(_quotes.length)];
    
    // Logo scale animation with elastic bounce
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _logoScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Logo pulsing glow animation (continuous)
    _logoGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _logoGlowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
        parent: _logoGlowController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Welcome text bounce animation
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _welcomeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Curves.easeOut,
      ),
    );
    
    _welcomeFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Curves.easeIn,
      ),
    );
    
    // Tagline slide-in animation (staggered after welcome text)
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    
    _taglineSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _taglineController,
        curve: Curves.easeOut,
      ),
    );
    
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _taglineController,
        curve: Curves.easeIn,
      ),
    );
    
    // Content fade animation
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeIn,
      ),
    );
    
    // Start animations in sequence
    _startWelcomeSequence();
    
    // Initialize confetti particles
    _initializeConfetti();
    
    // Load weekly challenge progress
    _loadWeeklyChallenges();
    
    // Optional: Play a gentle welcoming sound
    Future.delayed(const Duration(milliseconds: 300), () {
      HapticFeedback.lightImpact();
    });
  }
  
  void _startWelcomeSequence() async {
    // Logo appears with bounce
    _logoController.forward();
    
    // Start continuous glow animation
    _logoGlowController.repeat(reverse: true);
    
    // Wait 400ms, then show welcome text
    await Future.delayed(const Duration(milliseconds: 400));
    _welcomeController.forward();
    
    // Wait 300ms, then slide in tagline
    await Future.delayed(const Duration(milliseconds: 300));
    _taglineController.forward();
    
    // Finally, fade in the rest of content
    await Future.delayed(const Duration(milliseconds: 200));
    _contentController.forward();
  }
  
  Future<void> _loadWeeklyChallenges() async {
    // Calculate challenges completed this week (simulated with completed topics count)
    int completed = 0;
    for (final course in courses) {
      for (final topic in course.topics) {
        final score = await LocalStorageService.getTopicProgress(topic.id);
        if (score > 0) {
          completed++;
        }
      }
    }
    if (mounted) {
      setState(() {
        _challengesCompletedThisWeek = (completed / 2).floor();
        if (_challengesCompletedThisWeek > 7) _challengesCompletedThisWeek = 7;
      });
    }
  }
  
  void _initializeConfetti() {
    final confettiColors = [
      Colors.blue.shade300,
      Colors.orange.shade300,
      Colors.yellow.shade300,
      Colors.pink.shade300,
      Colors.green.shade300,
      Colors.purple.shade300,
      Colors.teal.shade300,
    ];
    
    // Create confetti particles from bottom-left and bottom-right
    for (int i = 0; i < 30; i++) {
      final isLeft = i % 2 == 0;
      _confettiParticles.add(
        ConfettiParticle(
          x: isLeft ? _random.nextDouble() * 150 : 250 + _random.nextDouble() * 150,
          y: 600 + _random.nextDouble() * 100,
          size: 8 + _random.nextDouble() * 8,
          color: confettiColors[_random.nextInt(confettiColors.length)],
          speedX: (isLeft ? 1 : -1) * (0.3 + _random.nextDouble() * 0.5),
          speedY: -2 - _random.nextDouble() * 2,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
          opacity: 1.0,
        ),
      );
    }
    
    // Start confetti animation
    _animateConfetti();
  }
  
  void _animateConfetti() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) return false;
      
      setState(() {
        for (var particle in _confettiParticles) {
          particle.x += particle.speedX;
          particle.y += particle.speedY;
          particle.rotation += particle.rotationSpeed;
          
          // Fade out as it rises
          if (particle.y < 300) {
            particle.opacity -= 0.01;
          }
        }
        
        // Remove fully faded particles
        _confettiParticles.removeWhere((p) => p.opacity <= 0);
      });
      
      // Stop animation when all confetti is gone
      return _confettiParticles.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _logoGlowController.dispose();
    _welcomeController.dispose();
    _taglineController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Get a random topic for the daily challenge
  Topic _getRandomTopic() {
    final randomCourse = courses[_random.nextInt(courses.length)];
    return randomCourse.topics[_random.nextInt(randomCourse.topics.length)];
  }
  
  // Build interactive daily challenge section
  Widget _buildDailyChallengeSection(Topic randomTopic) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: [
          // Main challenge button/card
          GestureDetector(
            onTap: () {
              setState(() {
                _isDailyChallengeExpanded = !_isDailyChallengeExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.all(_isDailyChallengeExpanded ? 20 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_isDailyChallengeExpanded ? 20 : 30),
                color: _isDailyChallengeExpanded ? Colors.white : Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Challenge button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5C6BC0), Color(0xFF7E57C2)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(
                                topic: randomTopic,
                                isMockTest: false,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flash_on, color: Colors.white),
                              const SizedBox(width: 8),
                              const Text(
                                'Daily Challenge',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isDailyChallengeExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Expanded content
                  if (_isDailyChallengeExpanded) ...[
                    const SizedBox(height: 20),
                    
                    // Today's challenge info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.today, color: Colors.indigo, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Today\'s Topic: ${randomTopic.title}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade900,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Complete today\'s challenge to maintain your streak!',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Weekly progress
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'This Week\'s Progress',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$_challengesCompletedThisWeek/7 days',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        
                        // Weekly dots indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (index) {
                            final isCompleted = index < _challengesCompletedThisWeek;
                            return Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted ? Colors.green : Colors.grey.shade300,
                                boxShadow: isCompleted ? [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ] : [],
                              ),
                              child: Center(
                                child: isCompleted
                                    ? Icon(Icons.check, color: Colors.white, size: 18)
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                              ),
                            );
                          }),
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _challengesCompletedThisWeek / 7,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content with enhanced gradient background
          Container(
            // Enhanced gradient background (light lavender → sky blue)
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE8EAF6), // Light lavender
                  Color(0xFFE1F5FE), // Sky blue  
                  Color(0xFFF3E5F5), // Light purple
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false, // Don't add padding at bottom for floating nav
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        
                        // Animated Logo with pulsing glow
                        AnimatedBuilder(
                          animation: _logoGlowAnimation,
                          builder: (context, child) {
                            return ScaleTransition(
                              scale: _logoScaleAnimation,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF5C6BC0).withOpacity(_logoGlowAnimation.value),
                                      blurRadius: 40 + (_logoGlowAnimation.value * 20),
                                      spreadRadius: 8 + (_logoGlowAnimation.value * 8),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 140,
                                  height: 140,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF5C6BC0), Color(0xFF7E57C2)],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.school,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Welcome text with bounce animation
                        FadeTransition(
                          opacity: _welcomeFadeAnimation,
                          child: ScaleTransition(
                            scale: _welcomeScaleAnimation,
                            child: const Text(
                              'Welcome to LearnEase!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Tagline with slide-in animation
                        FadeTransition(
                          opacity: _taglineFadeAnimation,
                          child: AnimatedBuilder(
                            animation: _taglineSlideAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _taglineSlideAnimation.value),
                                child: child,
                              );
                            },
                            child: const Text(
                              'Learn Java & DBMS through\ninteractive lessons',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Rest of content with fade animation
                        FadeTransition(
                          opacity: _contentFadeAnimation,
                          child: Column(
                            children: [
                              // Motivational quote
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade200, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _selectedQuote,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // Interactive Daily Challenge Section
                              _buildDailyChallengeSection(_getRandomTopic()),
                              
                              const SizedBox(height: 40),
                              
                              // Add extra space for floating nav bar
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Confetti overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ConfettiPainter(_confettiParticles),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Confetti painter
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.rotation);
      
      // Draw confetti as small rectangles
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size * 1.5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(particle.size * 0.2)),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
