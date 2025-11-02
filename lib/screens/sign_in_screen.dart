import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_content_service.dart';
import '../main.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  final String? initialEmail;
  const SignInScreen({Key? key, this.initialEmail}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  int _step = 0; // 0: email+password, 1: OTP verification
  bool _showSignUpOption = false; // Show signup button when email not registered
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _email.text = widget.initialEmail!;
    }
  }

  void _sendOtpAndProceed() async {
    final email = _email.text.trim();
    final password = _password.text;
    
    if (email.isEmpty || !email.contains('@')) {
      _showTopNotification(
        'Invalid Email ⚠️',
        'Please enter a valid email address',
        Colors.orange,
      );
      return;
    }
    
    if (password.isEmpty || password.length < 6) {
      _showTopNotification(
        'Weak Password ⚠️',
        'Password must be at least 6 characters',
        Colors.orange,
      );
      return;
    }
    
    setState(() => _loading = true);
    final resp = await _authService.sendEmailOtp(email, password: password);
    setState(() => _loading = false);
    
    if (resp.containsKey('sent') && resp['sent'] == true) {
      setState(() {
        _step = 1;
        _otpSent = true;
        _showSignUpOption = false; // Reset signup option
      });
      
      // Show top notification for OTP sent
      _showTopNotification(
        'OTP Sent Successfully! 📧',
        'Check the server console for the OTP code.',
        Colors.green,
      );
    } else {
      final err = resp['error'] ?? 'Failed to send OTP';
      
      // Check if error indicates unregistered email
      final isUnregisteredEmail = err.toString().toLowerCase().contains('invalid credentials') ||
                                 err.toString().toLowerCase().contains('check your email');
      
      setState(() {
        _showSignUpOption = isUnregisteredEmail;
      });

      _showTopNotification(
        'OTP Send Failed ❌',
        err.toString(),
        Colors.red,
      );
    }
  }

  void _verifyOtpAndLogin() async {
    final email = _email.text.trim();
    final password = _password.text;
    final otp = _otp.text.trim();
    
    if (otp.isEmpty || otp.length < 4) {
      _showTopNotification(
        'Invalid OTP ⚠️',
        'Please enter a valid OTP (at least 4 digits)',
        Colors.orange,
      );
      return;
    }
    
    setState(() => _loading = true);
    final resp = await _authService.verifyEmailOtp(email, otp, password: password);
    setState(() => _loading = false);
    
    if (resp.containsKey('accessToken') || resp.containsKey('token')) {
      // Check if username is already set, if not set it from email
      final existingUsername = await UserContentService.getUsername();
      if (existingUsername == null || existingUsername.isEmpty) {
        // Extract username from email (part before @) as fallback
        final username = email.split('@')[0];
        await UserContentService.setUsername(username);
      }

      _showTopNotification(
        'Login Successful ✅',
        'Welcome back! Loading your account...',
        Colors.green,
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainNavigation()),
            (route) => false,
          );
        }
      });
    } else {
      final err = resp['error'] ?? 'Login failed. Please check your credentials and OTP.';
      _showTopNotification(
        'Login Failed ❌',
        err.toString(),
        Colors.red,
      );
    }
  }

  void _goBackToCredentials() {
    setState(() {
      _step = 0;
      _otpSent = false;
      _otp.clear();
      _showSignUpOption = false; // Reset signup option when going back
    });
  }
  
  void _navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignUpScreen(initialEmail: _email.text.trim()),
      ),
    );
  }

  void _showTopNotification(String title, String message, Color backgroundColor) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            color: backgroundColor,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1.5),
                      child: LinearProgressIndicator(
                        value: 1.0,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 0 ? 'Sign In' : 'Verify OTP'),
        leading: _step == 1 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBackToCredentials,
            )
          : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Step indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(0, 'Credentials', _step >= 0),
                  Container(width: 40, height: 2, color: _step >= 1 ? Colors.blue : Colors.grey[300]),
                  _buildStepIndicator(1, 'Verify OTP', _step >= 1),
                ],
              ),
              const SizedBox(height: 40),
              
              // Step 0: Email and Password
              if (_step == 0) ...[
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  enabled: !_loading,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _sendOtpAndProceed,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Continue with OTP Verification', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ForgotPasswordScreen()));
                  },
                  child: const Text('Forgot password?'),
                ),
                
                // Show signup button when email is not registered
                if (_showSignUpOption) ...[
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Email not registered?',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _navigateToSignUp,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Create Account'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 40),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              
              // Step 1: OTP Verification
              if (_step == 1) ...[
                Text(
                  'Enter the OTP sent to',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _email.text,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _otp,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    prefixIcon: Icon(Icons.verified_user),
                    border: OutlineInputBorder(),
                    hintText: 'Check server console for OTP',
                  ),
                  enabled: !_loading,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, letterSpacing: 2),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _verifyOtpAndLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verify & Sign In', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loading ? null : _sendOtpAndProceed,
                  child: const Text('Resend OTP'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
