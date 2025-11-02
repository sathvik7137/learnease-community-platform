import 'package:flutter/material.dart';

class DynamicNotification extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final Duration duration;
  final VoidCallback? onDismiss;

  const DynamicNotification({
    Key? key,
    required this.message,
    this.isSuccess = true,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  }) : super(key: key);

  @override
  State<DynamicNotification> createState() => _DynamicNotificationState();
}

class _DynamicNotificationState extends State<DynamicNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Slide from top animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Opacity animation
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Start animation
    _animationController.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _animationController.reverse();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onDismiss?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeNotification() {
    _animationController.reverse();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  border: Border.all(
                    color: widget.isSuccess ? Colors.green.shade300 : Colors.red.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isSuccess ? Colors.green : Colors.red).withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Icon(
                      widget.isSuccess ? Icons.check_circle : Icons.error_outline,
                      color: widget.isSuccess ? Colors.green.shade600 : Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    // Message text
                    Flexible(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: widget.isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Close button
                    GestureDetector(
                      onTap: _closeNotification,
                      child: Icon(
                        Icons.close,
                        color: widget.isSuccess ? Colors.green.shade600 : Colors.red.shade600,
                        size: 18,
                      ),
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

// Helper function to show notification
void showDynamicNotification(
  BuildContext context, {
  required String message,
  bool isSuccess = true,
  Duration duration = const Duration(seconds: 3),
  VoidCallback? onDismiss,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.topCenter,
        child: DynamicNotification(
          message: message,
          isSuccess: isSuccess,
          duration: duration,
          onDismiss: onDismiss,
        ),
      );
    },
  );
}
