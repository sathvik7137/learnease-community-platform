import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../providers/theme_provider.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  final Function() onLoginSuccess;

  const AdminLoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

enum AdminLoginStep { credentials, verify }

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passkeyController = TextEditingController();
  final TextEditingController _resetPasskeyController = TextEditingController();
  final TextEditingController _resetNewPasswordController = TextEditingController();
  final TextEditingController _resetConfirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscurePasskey = true;
  bool _obscureResetPasskey = true;
  bool _obscureResetNewPassword = true;
  bool _obscureResetConfirmPassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _passKeyFocused = false;
  bool _showBiometricOption = false;
  bool _showSuccessMessage = false;
  AdminLoginStep _currentStep = AdminLoginStep.credentials;
  String? _resetErrorMessage;

  // Animation controllers
  late AnimationController _fadeInController;
  late AnimationController _slideController;
  late AnimationController _buttonTapController;
  late AnimationController _glowController;
  late AnimationController _underlineController;
  late AnimationController _progressController;
  late AnimationController _biometricController;

  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _underlineAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _biometricAnimation;

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _buttonTapController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _underlineController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _biometricController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeInController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _buttonTapController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _underlineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _underlineController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic),
    );

    _biometricAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _biometricController, curve: Curves.easeInOut),
    );

    _fadeInController.forward();
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _showBiometricOption = true);
        _biometricController.forward();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passkeyController.dispose();
    _fadeInController.dispose();
    _slideController.dispose();
    _buttonTapController.dispose();
    _glowController.dispose();
    _underlineController.dispose();
    _progressController.dispose();
    _biometricController.dispose();
    _resetPasskeyController.dispose();
    _resetNewPasswordController.dispose();
    _resetConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyCredentials() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _slideController.reset();
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _currentStep = AdminLoginStep.verify;
        _isLoading = false;
      });
      _slideController.forward();
      _progressController.forward();
    }
  }

  Future<void> _handleAdminLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final passkey = _passkeyController.text.trim();

    if (passkey.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your admin passkey';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('[AdminLogin] Attempting login with email: $email');

      final result =
          await AuthService().adminLogin(email, password, passkey);

      if (result['success'] == true && result['isAdmin'] == true) {
        print('[AdminLogin] ✅ Admin login successful');

        await AuthService().saveUserRole(UserRole.admin);

        if (mounted) {
          setState(() {
            _isLoading = false;
            _showSuccessMessage = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin login successful!'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );

          print('[AdminLogin] ⏳ Waiting 800ms for token persistence...');
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            print('[AdminLogin] 🚀 Notifying parent via onLoginSuccess');
            widget.onLoginSuccess();
            Navigator.of(context).maybePop();
          }
        }
      } else {
        final error = result['error'] ?? 'Admin login failed';
        print('[AdminLogin] ❌ Login failed: $error');
        setState(() {
          _errorMessage = error;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[AdminLogin] ❌ Exception: $e');
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _backToCredentials() {
    setState(() {
      _currentStep = AdminLoginStep.credentials;
      _errorMessage = null;
      _passkeyController.clear();
      _progressController.reset();
    });
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isResetting = false;
            String? resetError;
            bool resetPasskeyObscure = true;
            bool resetNewPasswordObscure = true;
            bool resetConfirmPasswordObscure = true;

            return AlertDialog(
              backgroundColor: _getCardBackground(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Reset Admin Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _getPrimaryTextColor(),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (resetError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          resetError!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getSecondaryTextColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _getInputBackground(),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getInputBorder()),
                      ),
                      child: Text(
                        _emailController.text.isNotEmpty
                            ? _emailController.text
                            : 'admin@learnease.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: _getPrimaryTextColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Admin Passkey',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getSecondaryTextColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _resetPasskeyController,
                      obscureText: resetPasskeyObscure,
                      style: TextStyle(color: _getPrimaryTextColor()),
                      enabled: !isResetting,
                      decoration: InputDecoration(
                        hintText: 'Enter your passkey',
                        hintStyle: TextStyle(
                          color: _getSecondaryTextColor().withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: _getInputBackground(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _getInputBorder()),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _getInputBorder()),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _getAccentColor(), width: 2),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setModalState(() => resetPasskeyObscure = !resetPasskeyObscure);
                          },
                          child: Icon(
                            resetPasskeyObscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _getSecondaryTextColor(),
                            size: 18,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'New Password',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getSecondaryTextColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _resetNewPasswordController,
                      obscureText: resetNewPasswordObscure,
                      style: TextStyle(color: _getPrimaryTextColor()),
                      enabled: !isResetting,
                      decoration: InputDecoration(
                        hintText: 'Enter new password (min 6 chars)',
                        hintStyle: TextStyle(
                          color: _getSecondaryTextColor().withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: _getInputBackground(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _getInputBorder()),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _getInputBorder()),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _getAccentColor(), width: 2),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setModalState(() => resetNewPasswordObscure = !resetNewPasswordObscure);
                          },
                          child: Icon(
                            resetNewPasswordObscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _getSecondaryTextColor(),
                            size: 18,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getSecondaryTextColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _resetConfirmPasswordController,
                      obscureText: resetConfirmPasswordObscure,
                      style: TextStyle(color: _getPrimaryTextColor()),
                      enabled: !isResetting,
                      decoration: InputDecoration(
                        hintText: 'Confirm your new password',
                        hintStyle: TextStyle(
                          color: _getSecondaryTextColor().withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: _getInputBackground(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _getInputBorder()),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _getInputBorder()),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _getAccentColor(), width: 2),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setModalState(() => resetConfirmPasswordObscure = !resetConfirmPasswordObscure);
                          },
                          child: Icon(
                            resetConfirmPasswordObscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _getSecondaryTextColor(),
                            size: 18,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isResetting
                      ? null
                      : () {
                          _resetPasskeyController.clear();
                          _resetNewPasswordController.clear();
                          _resetConfirmPasswordController.clear();
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: _getAccentColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isResetting
                      ? null
                      : () async {
                          final passkey = _resetPasskeyController.text.trim();
                          final newPassword = _resetNewPasswordController.text;
                          final confirmPassword = _resetConfirmPasswordController.text;

                          if (passkey.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                            setModalState(() => resetError = 'Please fill all fields');
                            return;
                          }

                          if (newPassword.length < 6) {
                            setModalState(() => resetError = 'Password must be at least 6 characters');
                            return;
                          }

                          if (newPassword != confirmPassword) {
                            setModalState(() => resetError = 'Passwords do not match');
                            return;
                          }

                          setModalState(() {
                            isResetting = true;
                            resetError = null;
                          });

                          try {
                            final result = await AuthService().resetAdminPassword(
                              _emailController.text.trim().toLowerCase(),
                              passkey,
                              newPassword,
                            );

                            if (result['success'] == true) {
                              // Clear controllers
                              _resetPasskeyController.clear();
                              _resetNewPasswordController.clear();
                              _resetConfirmPasswordController.clear();

                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Password reset successfully! Logging you in...'),
                                    backgroundColor: Color(0xFF10B981),
                                    duration: Duration(seconds: 2),
                                  ),
                                );

                                // Auto-login with new password
                                await Future.delayed(const Duration(seconds: 1));
                                if (mounted) {
                                  _passwordController.text = newPassword;
                                  await _handleAdminLogin();
                                }
                              }
                            } else {
                              setModalState(() => resetError = result['error'] ?? 'Reset failed');
                            }
                          } catch (e) {
                            setModalState(() => resetError = 'Error: $e');
                          } finally {
                            if (mounted) {
                              setModalState(() => isResetting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isResetting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.9),
                            ),
                          ),
                        )
                      : const Text(
                          'Reset Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Theme-aware color methods
  bool get _isDarkMode {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _getBackgroundGradientStart() {
    return _isDarkMode
        ? const Color(0xFF0D1117)
        : const Color(0xFFEEF2FF);
  }

  Color _getBackgroundGradientEnd() {
    return _isDarkMode
        ? const Color(0xFF1B1F29)
        : const Color(0xFFF8FAFC);
  }

  Color _getAccentColor() => const Color(0xFF3B82F6);

  Color _getAccentColorSecondary() => const Color(0xFF8B5CF6);

  Color _getPrimaryTextColor() {
    return _isDarkMode
        ? const Color(0xFFE5E7EB)
        : const Color(0xFF111827);
  }

  Color _getSecondaryTextColor() {
    return _isDarkMode
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
  }

  Color _getInputBackground() {
    return _isDarkMode
        ? const Color(0xFF1F2937).withOpacity(0.8)
        : Colors.white.withOpacity(0.9);
  }

  Color _getInputBorder() {
    return _isDarkMode
        ? const Color(0xFF3F4655).withOpacity(0.6)
        : const Color(0xFFD1D5DB).withOpacity(0.5);
  }

  Color _getCardBackground() {
    return _isDarkMode
        ? const Color(0xFF111827).withOpacity(0.8)
        : Colors.white.withOpacity(0.95);
  }

  Color _getShadowColor() {
    return _isDarkMode
        ? Colors.black.withOpacity(0.4)
        : Colors.black.withOpacity(0.1);
  }

  Color _getGlowColor({bool isActive = true}) {
    if (!isActive) {
      return _isDarkMode
          ? const Color(0xFF374151)
          : const Color(0xFFE5E7EB);
    }
    return _getAccentColor();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = _isDarkMode;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Stack(
          children: [
            // Adaptive gradient background
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF0D1117),
                          const Color(0xFF161B22),
                          const Color(0xFF1B1F29),
                        ]
                      : [
                          const Color(0xFFEEF2FF),
                          const Color(0xFFF3F4F6),
                          const Color(0xFFF8FAFC),
                        ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Glowing ambient effects
            Positioned(
              top: -150,
              left: -120,
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF3B82F6).withOpacity(0.15),
                            const Color(0xFF06B6D4).withOpacity(0.08),
                            Colors.transparent,
                          ]
                        : [
                            const Color(0xFF3B82F6).withOpacity(0.08),
                            const Color(0xFF06B6D4).withOpacity(0.04),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -180,
              right: -140,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF8B5CF6).withOpacity(0.12),
                            const Color(0xFF6366F1).withOpacity(0.06),
                            Colors.transparent,
                          ]
                        : [
                            const Color(0xFF8B5CF6).withOpacity(0.08),
                            const Color(0xFF6366F1).withOpacity(0.04),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildExpandedHeader(),
                    SizedBox(height: screenHeight * 0.04),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _buildAnimatedStepIndicator(),
                    ),
                    SizedBox(height: screenHeight * 0.06),
                    if (_errorMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: _buildErrorBanner(),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeInAnimation,
                          child: _currentStep == AdminLoginStep.credentials
                              ? _buildCredentialsStep()
                              : _buildPasskeyStep(),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _buildActionButtons(),
                    ),
                    if (_showBiometricOption)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 16.0),
                        child: _buildBiometricOption(),
                      ),
                    SizedBox(height: screenHeight * 0.04),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [
                  const Color(0xFF1E293B).withOpacity(0.7),
                  const Color(0xFF0F172A).withOpacity(0.6),
                ]
              : [
                  const Color(0xFFF3F4F6).withOpacity(0.5),
                  const Color(0xFFE5E7EB).withOpacity(0.4),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getAccentColor().withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipPath(
        clipper: _CurvedBottomClipper(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 60),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDarkMode
                  ? [
                      const Color(0xFF1E293B).withOpacity(0.8),
                      const Color(0xFF0F172A).withOpacity(0.7),
                    ]
                  : [
                      const Color(0xFFF3F4F6).withOpacity(0.6),
                      const Color(0xFFE5E7EB).withOpacity(0.5),
                    ],
            ),
          ),
          child: Column(
            children: [
              // Title with glow
              FadeTransition(
                opacity: _fadeInAnimation,
                child: Column(
                  children: [
                    Text(
                      'Admin Access',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: _getPrimaryTextColor(),
                        shadows: [
                          Shadow(
                            color: _getAccentColor().withOpacity(0.4),
                            offset: const Offset(0, 0),
                            blurRadius: 30,
                          ),
                          Shadow(
                            color: _getAccentColorSecondary().withOpacity(0.2),
                            offset: const Offset(0, 0),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Animated gradient underline
                    CustomPaint(
                      painter: _AnimatedUnderlinePainter(
                        progress: _underlineAnimation.value,
                        primaryColor: _getAccentColor(),
                        secondaryColor: _getAccentColorSecondary(),
                      ),
                      size: const Size(120, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Subtitle
              FadeTransition(
                opacity: _fadeInAnimation,
                child: Text(
                  'Secure Enterprise Verification',
                  style: TextStyle(
                    fontSize: 16,
                    color: _getSecondaryTextColor(),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStepIndicator() {
    bool step1Complete = _currentStep == AdminLoginStep.verify;
    bool step2Active = _currentStep == AdminLoginStep.verify;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Step 1
            Expanded(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (step1Complete || _currentStep == AdminLoginStep.credentials)
                        ScaleTransition(
                          scale: _glowAnimation,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 2,
                                color: _getAccentColor().withOpacity(0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getAccentColor().withOpacity(0.6),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: (_currentStep == AdminLoginStep.credentials ||
                                  step1Complete)
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _getAccentColor(),
                                    _getAccentColor().withOpacity(0.8),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    const Color(0xFF374151),
                                    const Color(0xFF1F2937),
                                  ],
                                ),
                          boxShadow: (_currentStep == AdminLoginStep.credentials ||
                                  step1Complete)
                              ? [
                                  BoxShadow(
                                    color: _getAccentColor().withOpacity(0.5),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: step1Complete
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 32)
                              : Text(
                                  '1',
                                  style: TextStyle(
                                    color: (_currentStep ==
                                            AdminLoginStep.credentials ||
                                        step1Complete)
                                        ? Colors.white
                                        : const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 26,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Credentials',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: (_currentStep == AdminLoginStep.credentials ||
                              step1Complete)
                          ? _getAccentColor()
                          : _getSecondaryTextColor(),
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Progress line
            Expanded(
              flex: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (step1Complete)
                    Container(
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: _getAccentColor().withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: step1Complete
                          ? LinearGradient(
                              colors: [
                                _getAccentColor(),
                                const Color(0xFF06B6D4),
                                _getAccentColorSecondary(),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                const Color(0xFF374151),
                                const Color(0xFF374151),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            // Step 2
            Expanded(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (step2Active)
                        ScaleTransition(
                          scale: _glowAnimation,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 2,
                                color:
                                    _getAccentColorSecondary().withOpacity(0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getAccentColorSecondary()
                                      .withOpacity(0.6),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: step2Active
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _getAccentColorSecondary(),
                                    _getAccentColorSecondary()
                                        .withOpacity(0.8),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF374151),
                                    Color(0xFF1F2937),
                                  ],
                                ),
                          boxShadow: step2Active
                              ? [
                                  BoxShadow(
                                    color: _getAccentColorSecondary()
                                        .withOpacity(0.5),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            '2',
                            style: TextStyle(
                              color: step2Active
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Passkey',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: step2Active
                          ? _getAccentColorSecondary()
                          : _getSecondaryTextColor(),
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444).withOpacity(0.15),
            const Color(0xFFF59E0B).withOpacity(0.12),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFFEF4444),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Your Credentials',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _getPrimaryTextColor(),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your admin email and password to continue',
          style: TextStyle(
            fontSize: 14,
            color: _getSecondaryTextColor(),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        // Email field
        _buildInput(
          controller: _emailController,
          label: 'Admin Email',
          hint: 'Enter your admin email',
          icon: Icons.email_outlined,
          onFocusChange: (focused) {
            setState(() => _emailFocused = focused);
          },
        ),
        const SizedBox(height: 20),
        // Password field
        _buildInput(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your password',
          icon: Icons.lock_outlined,
          obscure: _obscurePassword,
          onObscureToggle: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          onFocusChange: (focused) {
            setState(() => _passwordFocused = focused);
          },
        ),
      ],
    );
  }

  Widget _buildPasskeyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Your Passkey',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _getPrimaryTextColor(),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the unique passkey set during your account creation',
          style: TextStyle(
            fontSize: 14,
            color: _getSecondaryTextColor(),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        // Verified email display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _getAccentColor().withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _getInputBackground(),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getAccentColor().withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: _getAccentColor(),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Email',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getSecondaryTextColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _emailController.text.isNotEmpty
                          ? _emailController.text
                          : 'admin@learnease.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getPrimaryTextColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Passkey field
        _buildInput(
          controller: _passkeyController,
          label: 'Admin Passkey',
          hint: 'Enter your passkey',
          icon: Icons.vpn_key_outlined,
          obscure: _obscurePasskey,
          onObscureToggle: () {
            setState(() => _obscurePasskey = !_obscurePasskey);
          },
          onFocusChange: (focused) {
            setState(() => _passKeyFocused = focused);
          },
        ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onObscureToggle,
    required Function(bool) onFocusChange,
  }) {
    final FocusNode focusNode = FocusNode();
    bool focused = false;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => focused = hasFocus);
        onFocusChange(hasFocus);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _getPrimaryTextColor(),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: _getAccentColor().withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: _getShadowColor(),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
            ),
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              obscureText: obscure,
              style: TextStyle(
                fontSize: 16,
                color: _getPrimaryTextColor(),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: _getSecondaryTextColor().withOpacity(0.6),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  icon,
                  color: focused
                      ? _getAccentColor()
                      : _getSecondaryTextColor(),
                  size: 20,
                ),
                suffixIcon: onObscureToggle != null
                    ? GestureDetector(
                        onTap: onObscureToggle,
                        child: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _getSecondaryTextColor(),
                          size: 20,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: _getInputBackground(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _getInputBorder(),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _getInputBorder(),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _getAccentColor(),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isCredentialsStep = _currentStep == AdminLoginStep.credentials;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main action button
        ScaleTransition(
          scale: _buttonScaleAnimation,
          child: GestureDetector(
            onTap: _isLoading
                ? null
                : (isCredentialsStep
                    ? _handleVerifyCredentials
                    : _handleAdminLogin),
            onTapDown: (_) {
              if (!_isLoading) {
                _buttonTapController.forward();
              }
            },
            onTapUp: (_) {
              _buttonTapController.reverse();
            },
            onTapCancel: () {
              _buttonTapController.reverse();
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _getAccentColor(),
                    _getAccentColorSecondary(),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getAccentColor().withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.9),
                          ),
                        ),
                      )
                    : Text(
                        isCredentialsStep ? 'Continue' : 'Verify & Login',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary button (Back) or Forgot Password link
        if (isCredentialsStep)
          Center(
            child: GestureDetector(
              onTap: _isLoading ? null : () {
                // Validate email before showing dialog
                final email = _emailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email address first'),
                      backgroundColor: Color(0xFFEF4444),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                _showForgotPasswordDialog();
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getAccentColor(),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          )
        else
          GestureDetector(
            onTap: _isLoading ? null : _backToCredentials,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getInputBorder(),
                  width: 1.5,
                ),
                color: _getCardBackground(),
              ),
              child: Center(
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _getPrimaryTextColor(),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBiometricOption() {
    return FadeTransition(
      opacity: _biometricAnimation,
      child: Column(
        children: [
          Divider(
            color: _getInputBorder(),
            height: 24,
          ),
          Text(
            'Or use biometric',
            style: TextStyle(
              fontSize: 13,
              color: _getSecondaryTextColor(),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBiometricButton(
                icon: Icons.fingerprint,
                label: 'Fingerprint',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fingerprint authentication coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildBiometricButton(
                icon: Icons.face,
                label: 'Face ID',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Face ID authentication coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getAccentColor().withOpacity(0.15),
              _getAccentColorSecondary().withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: _getAccentColor().withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _getAccentColor().withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: _getAccentColor(),
            size: 24,
          ),
        ),
      ),
    );
  }
}

// Custom painter for animated underline
class _AnimatedUnderlinePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _AnimatedUnderlinePainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor,
          secondaryColor,
          primaryColor,
        ],
        stops: [
          0.0,
          progress,
          1.0,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_AnimatedUnderlinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor;
}

// Curved clipper for header
class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_CurvedBottomClipper oldClipper) => false;
}
