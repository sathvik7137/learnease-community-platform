import 'package:flutter/material.dart';
import '../utils/performance_config.dart';

/// Ultra-responsive button with instant feedback
class FastResponseButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const FastResponseButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<FastResponseButton> createState() => _FastResponseButtonState();
}

class _FastResponseButtonState extends State<FastResponseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PerformanceConfig.buttonFeedback,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: PerformanceConfig.buttonCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton(
          onPressed: null, // Disable default onPressed since we handle it with GestureDetector
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            elevation: widget.elevation,
            padding: widget.padding,
            shape: RoundedRectangleBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Fast icon button with instant visual feedback
class FastIconButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? color;
  final double iconSize;
  final String? tooltip;
  final Color? splashColor;

  const FastIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.iconSize = 24.0,
    this.tooltip,
    this.splashColor,
  }) : super(key: key);

  @override
  State<FastIconButton> createState() => _FastIconButtonState();
}

class _FastIconButtonState extends State<FastIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PerformanceConfig.buttonFeedback,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePressed() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: _controller, curve: PerformanceConfig.buttonCurve),
      ),
      child: IconButton(
        onPressed: _handlePressed,
        icon: Icon(widget.icon),
        color: widget.color,
        iconSize: widget.iconSize,
        tooltip: widget.tooltip,
        splashRadius: 28,
        highlightColor: Colors.transparent,
        splashColor: widget.splashColor?.withOpacity(0.2),
      ),
    );
  }
}

/// Fast ink well with snappy feedback
class FastInkWell extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color? splashColor;
  final Color? highlightColor;
  final BorderRadius? borderRadius;

  const FastInkWell({
    Key? key,
    this.onTap,
    required this.child,
    this.splashColor,
    this.highlightColor,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<FastInkWell> createState() => _FastInkWellState();
}

class _FastInkWellState extends State<FastInkWell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PerformanceConfig.buttonFeedback,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.98).animate(
        CurvedAnimation(parent: _controller, curve: PerformanceConfig.buttonCurve),
      ),
      child: InkWell(
        onTap: widget.onTap != null
            ? () {
                _controller.forward().then((_) {
                  _controller.reverse();
                });
                widget.onTap!();
              }
            : null,
        splashColor: widget.splashColor?.withOpacity(0.3),
        highlightColor: widget.highlightColor?.withOpacity(0.1),
        borderRadius: widget.borderRadius,
        child: widget.child,
      ),
    );
  }
}
