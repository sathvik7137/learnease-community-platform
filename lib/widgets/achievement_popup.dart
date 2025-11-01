import 'package:flutter/material.dart';
import '../models/achievement.dart';

class AchievementPopup extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onDismiss;

  const AchievementPopup({
    super.key,
    required this.achievement,
    this.onDismiss,
  });

  @override
  _AchievementPopupState createState() => _AchievementPopupState();

  // Show the popup
  static void show(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AchievementPopup(achievement: achievement),
    );
  }
}

class _AchievementPopupState extends State<AchievementPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _starController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _starAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for popup
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Star animation
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _starAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.easeOut),
    );

    // Start animations
    _scaleController.forward();
    _starController.forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Main card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF5C6BC0),
                    Color(0xFF7E57C2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 30),
                  
                  // Achievement title
                  const Text(
                    '🎉 Achievement Unlocked! 🎉',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Achievement icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.achievement.icon,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Achievement name
                  Text(
                    widget.achievement.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Achievement description
                  Text(
                    widget.achievement.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Close button
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDismiss?.call();
                    },
                    child: const Text(
                      'Awesome!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Animated stars
            ...List.generate(8, (index) {
              return AnimatedBuilder(
                animation: _starAnimation,
                builder: (context, child) {
                  final angle = (index * 45) * 3.14159 / 180;
                  final distance = _starAnimation.value * 120;
                  final opacity = 1.0 - _starAnimation.value;
                  
                  return Positioned(
                    left: 150 + distance * cos(angle),
                    top: 150 + distance * sin(angle),
                    child: Opacity(
                      opacity: opacity,
                      child: Text(
                        '⭐',
                        style: TextStyle(
                          fontSize: 20 * (1 - _starAnimation.value * 0.5),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
  
  double cos(double radians) => radians.cos();
  double sin(double radians) => radians.sin();
}

extension on double {
  double cos() {
    return (this * 180 / 3.14159).toInt() == 0 ? 1.0 
         : (this * 180 / 3.14159).toInt() == 90 ? 0.0
         : (this * 180 / 3.14159).toInt() == 180 ? -1.0
         : (this * 180 / 3.14159).toInt() == 270 ? 0.0
         : 0.707; // Approximate for 45°
  }
  
  double sin() {
    return (this * 180 / 3.14159).toInt() == 0 ? 0.0 
         : (this * 180 / 3.14159).toInt() == 90 ? 1.0
         : (this * 180 / 3.14159).toInt() == 180 ? 0.0
         : (this * 180 / 3.14159).toInt() == 270 ? -1.0
         : 0.707; // Approximate for 45°
  }
}
