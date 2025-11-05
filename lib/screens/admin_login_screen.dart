import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
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

class _AdminLoginScreenState extends State<AdminLoginScreen> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passkeyController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscurePasskey = true;
  AdminLoginStep _currentStep = AdminLoginStep.credentials;
  
  // Animation controllers
  late AnimationController _fadeInController;
  late AnimationController _slideController;
  late AnimationController _buttonTapController;
  late AnimationController _glowController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _buttonTapController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeInController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _buttonTapController, curve: Curves.elasticOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _fadeInController.forward();
    _slideController.forward();
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

    // Move to next step with slide animation
    _slideController.reset();
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      setState(() {
        _currentStep = AdminLoginStep.verify;
        _isLoading = false;
      });
      _slideController.forward();
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
      
      final result = await AuthService().adminLogin(email, password, passkey);

      if (result['success'] == true && result['isAdmin'] == true) {
        print('[AdminLogin] ✅ Admin login successful');
        
        // Save the admin role
        await AuthService().saveUserRole(UserRole.admin);
        
        // Show success message
        if (mounted) {
          // Reset loading state first
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin login successful!'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
          
          // Allow persistence then notify and close only this screen
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Stack(
          children: [
            // Dark gradient background - Deep charcoal to indigo
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D1117), // Deep charcoal
                    Color(0xFF161B22), // Dark slate
                    Color(0xFF1B1F29), // Dark indigo
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Glowing ambient light effect - top-left (electric blue)
            Positioned(
              top: -150,
              left: -120,
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.15), // Electric blue
                      const Color(0xFF06B6D4).withOpacity(0.08), // Cyan
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Glowing ambient light effect - bottom-right (violet/purple)
            Positioned(
              bottom: -180,
              right: -140,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.12), // Violet
                      const Color(0xFF6366F1).withOpacity(0.06), // Indigo
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
                    // Header - expanded and curved
                    _buildExpandedHeader(),
                    
                    SizedBox(height: screenHeight * 0.04),

                    // Animated Step Indicator with glowing progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _buildAnimatedStepIndicatorWithProgress(),
                    ),
                    
                    SizedBox(height: screenHeight * 0.06),

                    // Error Banner
                    if (_errorMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: _buildErrorBanner(),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                    ],

                    // Animated Step Content - vertically centered
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

                    // Action Buttons - positioned lower
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _buildActionButtons(),
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
          colors: [
            const Color(0xFF1E293B).withOpacity(0.7), // Dark slate with transparency
            const Color(0xFF0F172A).withOpacity(0.6), // Darker slate
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.2), // Electric blue glow
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
              colors: [
                const Color(0xFF1E293B).withOpacity(0.8),
                const Color(0xFF0F172A).withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            children: [
              // Glowing title with neon effect
              Container(
                child: Column(
                  children: [
                    Text(
                      'Admin Access',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.6), // Electric blue glow
                            offset: const Offset(0, 0),
                            blurRadius: 30,
                          ),
                          Shadow(
                            color: const Color(0xFF06B6D4).withOpacity(0.4), // Cyan glow
                            offset: const Offset(0, 0),
                            blurRadius: 20,
                          ),
                          const Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Animated neon underline
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1500),
                      height: 3,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF3B82F6), // Electric blue
                            Color(0xFF06B6D4), // Cyan
                            Color(0xFF8B5CF6), // Violet
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Secure Enterprise Verification',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStepIndicator() {
    bool step1Active = _currentStep == AdminLoginStep.credentials;
    bool step1Complete = _currentStep == AdminLoginStep.verify;
    
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Step 1
            Expanded(
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _glowAnimation,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: step1Active || step1Complete
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue.shade400,
                                  Colors.blue.shade600,
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey[300]!,
                                  Colors.grey[200]!,
                                ],
                              ),
                        boxShadow: step1Active || step1Complete
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                      ),
                      child: Center(
                        child: step1Complete
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 30)
                            : Text(
                                '1',
                                style: TextStyle(
                                  color: step1Active || step1Complete
                                      ? Colors.white
                                      : Colors.grey[500],
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Credentials',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: step1Active || step1Complete
                          ? Colors.blue.shade600
                          : Colors.grey[600],
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Connector Line with glow effect
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glowing effect
                    if (step1Complete)
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade400.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    // Main line
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: step1Complete
                            ? LinearGradient(
                                colors: [
                                  Colors.blue.shade400,
                                  Colors.blue.shade400,
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey[300]!,
                                  Colors.grey[300]!,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Step 2
            Expanded(
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _currentStep == AdminLoginStep.verify ? _glowAnimation : AlwaysStoppedAnimation(1.0),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _currentStep == AdminLoginStep.verify
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.purple.shade400,
                                  Colors.purple.shade600,
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey[300]!,
                                  Colors.grey[200]!,
                                ],
                              ),
                        boxShadow: _currentStep == AdminLoginStep.verify
                            ? [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                      ),
                      child: Center(
                        child: Text(
                          '2',
                          style: TextStyle(
                            color: _currentStep == AdminLoginStep.verify
                                ? Colors.white
                                : Colors.grey[500],
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Passkey',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _currentStep == AdminLoginStep.verify
                          ? Colors.purple.shade600
                          : Colors.grey[600],
                      letterSpacing: 0.2,
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

  Widget _buildAnimatedStepIndicatorWithProgress() {
    bool step1Active = _currentStep == AdminLoginStep.credentials;
    bool step1Complete = _currentStep == AdminLoginStep.verify;
    
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
                      // Outer glowing ring
                      if (step1Active || step1Complete)
                        ScaleTransition(
                          scale: _glowAnimation,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 2,
                                color: const Color(0xFF3B82F6).withOpacity(0.5), // Electric blue
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.6),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Inner circle
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: step1Active || step1Complete
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF3B82F6), // Electric blue
                                    Color(0xFF2563EB), // Deeper blue
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    const Color(0xFF374151), // Dark gray
                                    const Color(0xFF1F2937), // Darker gray
                                  ],
                                ),
                          boxShadow: step1Active || step1Complete
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withOpacity(0.5),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: step1Complete
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 32)
                              : Text(
                                  '1',
                                  style: TextStyle(
                                    color: step1Active || step1Complete
                                        ? Colors.white
                                        : const Color(0xFF6B7280), // Gray text
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
                      color: step1Active || step1Complete
                          ? const Color(0xFF60A5FA) // Light blue
                          : const Color(0xFF6B7280), // Gray
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Glowing animated progress bar
            Expanded(
              flex: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow layer
                  if (step1Complete)
                    Container(
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  // Main progress line
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: step1Complete
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF3B82F6), // Electric blue
                                Color(0xFF06B6D4), // Cyan
                                Color(0xFF8B5CF6), // Violet
                              ],
                            )
                          : const LinearGradient(
                              colors: [
                                Color(0xFF374151), // Dark gray
                                Color(0xFF374151),
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
                      // Outer glowing ring
                      if (_currentStep == AdminLoginStep.verify)
                        ScaleTransition(
                          scale: _glowAnimation,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 2,
                                color: const Color(0xFF8B5CF6).withOpacity(0.5), // Violet
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.6),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Inner circle
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _currentStep == AdminLoginStep.verify
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF8B5CF6), // Violet
                                    Color(0xFF7C3AED), // Deeper violet
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF374151), // Dark gray
                                    Color(0xFF1F2937), // Darker gray
                                  ],
                                ),
                          boxShadow: _currentStep == AdminLoginStep.verify
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.5),
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
                              color: _currentStep == AdminLoginStep.verify
                                  ? Colors.white
                                  : const Color(0xFF6B7280), // Gray text
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
                      color: _currentStep == AdminLoginStep.verify
                          ? const Color(0xFFA78BFA) // Light violet
                          : const Color(0xFF6B7280), // Gray
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
            const Color(0xFFEF4444).withOpacity(0.15), // Red with transparency
            const Color(0xFFF59E0B).withOpacity(0.12), // Orange with transparency
          ],
        ),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEF4444).withOpacity(0.2),
            ),
            child: const Icon(Icons.error_outline, color: Color(0xFFFCA5A5), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFFCA5A5), // Light red
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
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
        const Text(
          'Enter Your Credentials',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enter your admin email and password to continue',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        // Email Field
        _buildModernTextField(
          controller: _emailController,
          hint: 'Enter admin email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 20),
        // Password Field
        _buildModernTextField(
          controller: _passwordController,
          hint: 'Enter password',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscurePassword,
          onToggleVisibility: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildPasskeyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify Your Passkey',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enter your admin passkey to complete verification',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        // Frosted glass verified email card
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E293B).withOpacity(0.6), // Semi-transparent dark slate
                    const Color(0xFF0F172A).withOpacity(0.5), // Semi-transparent darker slate
                  ],
                ),
                border: Border.all(
                  width: 1.5,
                  color: const Color(0xFF3B82F6).withOpacity(0.3), // Electric blue border
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withOpacity(0.3),
                          const Color(0xFF06B6D4).withOpacity(0.2),
                        ],
                      ),
                      border: Border.all(
                        width: 2,
                        color: const Color(0xFF3B82F6).withOpacity(0.5),
                      ),
                    ),
                    child: const Icon(Icons.check_circle, color: Color(0xFF60A5FA), size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Email',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF60A5FA).withOpacity(0.9), // Light blue
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _emailController.text.isEmpty ? 'Not provided' : _emailController.text,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        // Passkey Field
        _buildModernTextField(
          controller: _passkeyController,
          hint: 'Enter your passkey',
          icon: Icons.vpn_key_outlined,
          isPassword: true,
          obscureText: _obscurePasskey,
          onToggleVisibility: () {
            setState(() => _obscurePasskey = !_obscurePasskey);
          },
          isLoading: _isLoading,
        ),
        const SizedBox(height: 14),
        Text(
          '🔐 Your unique passkey set during account creation',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: !isLoading,
        obscureText: isPassword && obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          filled: true,
          fillColor: const Color(0xFF1E293B).withOpacity(0.6), // Semi-transparent dark slate
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFF374151).withOpacity(0.5), // Dark gray
              width: 1.2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFF374151).withOpacity(0.5),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF3B82F6), // Electric blue
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFF374151).withOpacity(0.3),
              width: 1.2,
            ),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              icon,
              color: const Color(0xFF60A5FA), // Light blue
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: isPassword
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF9CA3AF), // Gray
                      size: 22,
                    ),
                    onPressed: onToggleVisibility,
                    splashRadius: 24,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentStep == AdminLoginStep.credentials) {
      return _buildGradientButton(
        label: 'Continue',
        onPressed: _isLoading ? null : _handleVerifyCredentials,
        isLoading: _isLoading,
      );
    } else {
      return Column(
        children: [
          _buildGradientButton(
            label: 'Verify & Login',
            onPressed: _isLoading ? null : _handleAdminLogin,
            isLoading: _isLoading,
            isPrimary: true,
          ),
          const SizedBox(height: 16),
          _buildGradientButton(
            label: 'Back',
            onPressed: _isLoading ? null : _backToCredentials,
            isLoading: false,
            isPrimary: false,
          ),
        ],
      );
    }
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
    bool isPrimary = true,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        if (onPressed != null) {
          _buttonTapController.forward();
        }
      },
      onTapUp: (_) {
        _buttonTapController.reverse();
      },
      onTapCancel: () {
        _buttonTapController.reverse();
      },
      child: ScaleTransition(
        scale: _buttonScaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.4), // Electric blue glow
                      blurRadius: 28,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3), // Violet glow
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                gradient: isPrimary
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF3B82F6), // Electric blue
                          Color(0xFF8B5CF6), // Violet
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          const Color(0xFF374151), // Matte gray
                          const Color(0xFF1F2937), // Darker gray
                        ],
                      ),
                borderRadius: BorderRadius.circular(28),
                border: isPrimary
                    ? Border.all(
                        width: 1,
                        color: Colors.white.withOpacity(0.1),
                      )
                    : Border.all(
                        width: 1.5,
                        color: const Color(0xFF4B5563), // Medium gray
                      ),
              ),
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading)
                        const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2.5,
                          ),
                        )
                      else
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom clipper for curved header bottom
class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Start from top-left
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.7);
    
    // Create smooth curve for bottom
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      0,
      size.height * 0.7,
    );
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

