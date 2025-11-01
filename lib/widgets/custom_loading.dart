import 'package:flutter/material.dart';
import 'dart:math' as math;

// Typing dots loading animation
class TypingDotsLoader extends StatefulWidget {
  final Color color;
  final double size;

  const TypingDotsLoader({
    super.key,
    this.color = const Color(0xFF5C6BC0),
    this.size = 12.0,
  });

  @override
  _TypingDotsLoaderState createState() => _TypingDotsLoaderState();
}

class _TypingDotsLoaderState extends State<TypingDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final animValue = (_controller.value - delay).clamp(0.0, 1.0);
            final bounce = math.sin(animValue * math.pi);

            return Transform.translate(
              offset: Offset(0, -bounce * widget.size),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: widget.size * 0.3),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.4 + bounce * 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// Rotating logo loader
class RotatingLogoLoader extends StatefulWidget {
  final double size;

  const RotatingLogoLoader({
    super.key,
    this.size = 40.0,
  });

  @override
  _RotatingLogoLoaderState createState() => _RotatingLogoLoaderState();
}

class _RotatingLogoLoaderState extends State<RotatingLogoLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF5C6BC0),
                  Color(0xFF7E57C2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.school,
              color: Colors.white,
              size: widget.size * 0.6,
            ),
          ),
        );
      },
    );
  }
}

// Pulsing circle loader
class PulsingLoader extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingLoader({
    super.key,
    this.color = const Color(0xFF5C6BC0),
    this.size = 50.0,
  });

  @override
  _PulsingLoaderState createState() => _PulsingLoaderState();
}

class _PulsingLoaderState extends State<PulsingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: widget.size * 0.6,
                height: widget.size * 0.6,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool showTypingDots;

  const LoadingOverlay({
    super.key,
    this.message,
    this.showTypingDots = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showTypingDots)
                TypingDotsLoader(size: 14, color: Color(0xFF5C6BC0))
              else
                RotatingLogoLoader(size: 50),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
