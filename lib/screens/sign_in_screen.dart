import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_content_service.dart';
import '../main.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';
import '../widgets/dynamic_notification.dart';
import '../widgets/password_input_field.dart';
import '../widgets/theme_toggle_button.dart';

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
      _showNotification('Invalid email address');
      return;
    }
    
    if (password.isEmpty || password.length < 6) {
      _showNotification('Password must be at least 6 characters');
      return;
    }
    
    setState(() => _loading = true);
    final resp = await _authService.sendEmailOtp(email, password: password);
    setState(() => _loading = false);
    
    if (resp.containsKey('sent') && resp['sent'] == true) {
      setState(() {
        _step = 1;
        _otpSent = true;
        _showSignUpOption = false;
      });
      
      _showNotification('OTP sent to your email', isSuccess: true);
    } else {
      final err = resp['error'] ?? 'Failed to send OTP';
      final isUnregisteredEmail = err.toString().toLowerCase().contains('invalid credentials') ||
                                 err.toString().toLowerCase().contains('check your email') ||
                                 err.toString().toLowerCase().contains('not registered') ||
                                 err.toString().toLowerCase().contains('sign up');
      
      setState(() {
        _showSignUpOption = isUnregisteredEmail;
      });

      _showNotification(err.toString(), isSuccess: false);
    }
  }

  void _verifyOtpAndLogin() async {
    final email = _email.text.trim();
    final password = _password.text;
    final otp = _otp.text.trim();
    
    if (otp.isEmpty || otp.length < 4) {
      _showNotification('Please enter a valid OTP');
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

      _showNotification('Login successful! Welcome back', isSuccess: true);

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainNavigation(key: MainNavigation.globalKey)),
            (route) => false,
          );
        }
      });
    } else {
      final err = resp['error'] ?? 'Login failed. Please check your credentials and OTP.';
      _showNotification(err.toString(), isSuccess: false);
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

  void _showNotification(String message, {bool isSuccess = false}) {
    showDynamicNotification(
      context,
      message: message,
      isSuccess: isSuccess,
      duration: const Duration(seconds: 3),
    );
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
        actions: const [
          ThemeToggleButton(size: 24, padding: EdgeInsets.only(right: 16)),
        ],
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
                PasswordInputField(
                  controller: _password,
                  labelText: 'Password',
                  hintText: 'Enter your password',
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
                
                // Always visible Register button
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: _navigateToSignUp,
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Show signup button when email is not registered
                if (_showSignUpOption) ...[
                  const SizedBox(height: 8),
                  Card(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue.shade900.withOpacity(0.3)
                        : Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Email not registered?',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
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
