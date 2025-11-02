import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/auth_service.dart';

// Shared accent color palette (works on both light and dark)
class LearnEaseColors {
  static const Color primaryAccent = Color(0xFF6366F1); // Indigo
  static const Color secondaryAccent = Color(0xFF3B82F6); // Blue
  static const Color tertiaryAccent = Color(0xFF60A5FA); // Light blue
  
  // Light mode colors
  static const Color lightBg1 = Color(0xFFEEF2FF);
  static const Color lightBg2 = Color(0xFFE0E7FF);
  static const Color lightCardBg = Color(0xFFFAFBFF);
  static const Color lightText = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);
  
  // Dark mode colors
  static const Color darkBg1 = Color(0xFF0F172A);
  static const Color darkBg2 = Color(0xFF1E293B);
  static const Color darkCardBg = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFE2E8F0);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkBorder = Color(0xFF475569);
}

class EditProfileScreen extends StatefulWidget {
  final String currentUsername;
  final String email;

  const EditProfileScreen({
    super.key,
    required this.currentUsername,
    required this.email,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.currentUsername;
    _usernameController.addListener(_checkForChanges);

    // Scale animation for profile avatar
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Fade animation for page entry
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Start animations
    _scaleController.forward();
    _fadeController.forward();
  }

  void _checkForChanges() {
    setState(() {
      _hasChanges = _usernameController.text.trim() != widget.currentUsername;
    });
  }

  @override
  void dispose() {
    _usernameController.removeListener(_checkForChanges);
    _usernameController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final newUsername = _usernameController.text.trim();
    
    // If username hasn't changed, just go back
    if (newUsername == widget.currentUsername) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService().updateUserProfile(username: newUsername);

      if (!mounted) return;

      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.red,
          ),
        );
      } else if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Return true to indicate profile was updated
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.indigo.withOpacity(0.5),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      LearnEaseColors.darkBg1,
                      LearnEaseColors.darkBg2,
                      LearnEaseColors.darkBg1,
                    ]
                  : [
                      LearnEaseColors.lightBg1,
                      LearnEaseColors.lightBg2,
                      LearnEaseColors.lightBg1,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Adaptive glow effects
              Positioned(
                top: 80,
                left: -30,
                right: -30,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              Colors.cyan.withOpacity(0.08),
                              Colors.indigo.withOpacity(0.04),
                              Colors.transparent,
                            ]
                          : [
                              LearnEaseColors.tertiaryAccent
                                  .withOpacity(0.08),
                              LearnEaseColors.primaryAccent
                                  .withOpacity(0.04),
                              Colors.transparent,
                            ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -50,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              Colors.indigo.withOpacity(0.05),
                              Colors.transparent,
                            ]
                          : [
                              LearnEaseColors.primaryAccent.withOpacity(0.03),
                              Colors.transparent,
                            ],
                    ),
                  ),
                ),
              ),
              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Picture with Edit Button (Animated)
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Center(
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.cyan.withOpacity(0.2)
                                            : LearnEaseColors.primaryAccent
                                                .withOpacity(0.15),
                                        blurRadius: Theme.of(context)
                                                    .brightness ==
                                                Brightness.dark
                                            ? 25
                                            : 12,
                                        spreadRadius: Theme.of(context)
                                                    .brightness ==
                                                Brightness.dark
                                            ? 8
                                            : 2,
                                      ),
                                      if (Theme.of(context).brightness ==
                                          Brightness.dark)
                                        BoxShadow(
                                          color: Colors.indigo.withOpacity(0.15),
                                          blurRadius: 15,
                                          spreadRadius: 3,
                                        )
                                      else
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Theme.of(context)
                                                .brightness ==
                                            Brightness.dark
                                        ? LearnEaseColors.darkCardBg
                                        : LearnEaseColors.lightCardBg,
                                    child: Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF93c5fd)
                                          : LearnEaseColors.primaryAccent,
                                    ),
                                  ),
                                ),
                                // Camera Icon Button with Ripple
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Photo upload coming soon!',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      customBorder: const CircleBorder(),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [
                                              LearnEaseColors.primaryAccent,
                                              LearnEaseColors.secondaryAccent,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.cyan
                                                      .withOpacity(0.4)
                                                  : LearnEaseColors
                                                      .primaryAccent
                                                      .withOpacity(0.3),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Email Field (Read-only/Disabled)
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? LearnEaseColors.darkTextSecondary
                                      : LearnEaseColors.lightTextSecondary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? LearnEaseColors.darkCardBg
                                          .withOpacity(0.6)
                                      : Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? LearnEaseColors.darkBorder
                                            .withOpacity(0.3)
                                        : LearnEaseColors.lightBorder
                                            .withOpacity(0.5),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.black.withOpacity(0.2)
                                          : Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.email,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade500,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        widget.email,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                                      .brightness ==
                                                  Brightness.dark
                                              ? LearnEaseColors.darkText
                                              : LearnEaseColors.lightText,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  '(Cannot be changed)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Username Field (Editable)
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Username',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? LearnEaseColors.darkTextSecondary
                                      : LearnEaseColors.lightTextSecondary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? LearnEaseColors.darkCardBg
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? LearnEaseColors.darkBorder
                                            .withOpacity(0.4)
                                        : LearnEaseColors.lightBorder,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.indigo.withOpacity(0.1)
                                          : LearnEaseColors.primaryAccent
                                              .withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TextFormField(
                                  controller: _usernameController,
                                  enabled: !_isLoading,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? LearnEaseColors.darkText
                                        : LearnEaseColors.lightText,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your username',
                                    hintStyle: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400,
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF93c5fd)
                                          : LearnEaseColors.primaryAccent,
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 45,
                                      minHeight: 45,
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Username cannot be empty';
                                    }
                                    if (value.trim().length < 3) {
                                      return 'Username must be at least 3 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Save Button with Adaptive Gradient
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: _hasChanges && !_isLoading
                                  ? const LinearGradient(
                                      colors: [
                                        LearnEaseColors.primaryAccent,
                                        LearnEaseColors.secondaryAccent,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey.shade600,
                                        Colors.grey.shade700,
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                if (_hasChanges && !_isLoading)
                                  BoxShadow(
                                    color: LearnEaseColors.primaryAccent
                                        .withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  )
                                else
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                  ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed:
                                  (_isLoading || !_hasChanges) ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _hasChanges
                                          ? 'Save Changes'
                                          : 'No Changes',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Adaptive Info Box with Glassmorphism
                        SizedBox(
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 10,
                                sigmaY: 10,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.cyan.withOpacity(0.3)
                                        : LearnEaseColors.lightBorder
                                            .withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.cyan.withOpacity(0.15)
                                          : Colors.black.withOpacity(0.05),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.cyan.shade300
                                          : LearnEaseColors.secondaryAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your username will be visible to other users in the community.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                                      .brightness ==
                                                  Brightness.dark
                                              ? Colors.grey.shade100
                                              : LearnEaseColors.lightText,
                                          height: 1.4,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
