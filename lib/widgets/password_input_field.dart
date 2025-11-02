import 'package:flutter/material.dart';

class PasswordInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final InputDecoration? decoration;
  final int minLength;

  const PasswordInputField({
    Key? key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.decoration,
    this.minLength = 6,
  }) : super(key: key);

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField>
    with SingleTickerProviderStateMixin {
  late bool _obscureText;
  late AnimationController _eyeAnimationController;
  late Animation<double> _eyeAnimation;

  @override
  void initState() {
    super.initState();
    _obscureText = true;

    _eyeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _eyeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _eyeAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _eyeAnimationController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });

    if (_obscureText) {
      _eyeAnimationController.reverse();
    } else {
      _eyeAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      validator: widget.validator,
      decoration: (widget.decoration ?? InputDecoration()).copyWith(
        labelText: widget.labelText ?? 'Password',
        hintText: widget.hintText ?? 'Enter your password',
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
          fontSize: 14,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(
            Icons.lock_outline,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            size: 22,
          ),
        ),
        suffixIcon: GestureDetector(
          onTap: _togglePasswordVisibility,
          child: AnimatedBuilder(
            animation: _eyeAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.9 + (_eyeAnimation.value * 0.15),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: _obscureText
                        ? (isDarkMode ? Colors.grey[500] : Colors.grey[400])
                        : Colors.blue.shade500,
                    size: 22,
                  ),
                ),
              );
            },
          ),
        ),
        filled: true,
        fillColor: isDarkMode
            ? Colors.grey.shade900.withOpacity(0.5)
            : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.blue.shade500,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDarkMode ? Colors.white : Colors.black87,
        letterSpacing: 1.2,
      ),
    );
  }
}
