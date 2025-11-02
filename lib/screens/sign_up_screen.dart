import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_content_service.dart';
import '../widgets/username_setup_dialog.dart';
import '../widgets/theme_toggle_widget.dart';
import '../widgets/dynamic_notification.dart';
import '../widgets/password_input_field.dart';
import 'otp_verify_screen.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  final String? initialEmail;
  const SignUpScreen({Key? key, this.initialEmail}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  final _otp = TextEditingController();
  bool _loading = false;
  bool _usernameTaken = false;
  List<String> _usernameSuggestions = [];
  bool _emailTaken = false;
  int _step = 0; // 0: credentials, 1: OTP verification
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _email.text = widget.initialEmail!;
    }
  }

  void _showNotification(String message, {bool isSuccess = true}) {
    showDynamicNotification(
      context,
      message: message,
      isSuccess: isSuccess,
      duration: const Duration(seconds: 3),
    );
  }

  void _validateAndSendOtp() async {
    setState(() => _loading = true);
    
    final email = _email.text.trim();
    final username = _username.text.trim();
    final password = _password.text;
    
    // Validation
    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() => _loading = false);
      _showNotification('All fields are required', isSuccess: false);
      return;
    }
    
    if (!email.contains('@')) {
      setState(() => _loading = false);
      _showNotification('Please enter a valid email address', isSuccess: false);
      return;
    }
    
    if (password.length < 6) {
      setState(() => _loading = false);
      _showNotification('Password must be at least 6 characters', isSuccess: false);
      return;
    }
    
    // Check if email is already registered
    final emailTaken = await UserContentService.isEmailTaken(email);
    if (emailTaken) {
      setState(() {
        _loading = false;
        _emailTaken = true;
      });
      _showNotification('Email is already registered', isSuccess: false);
      return;
    }
    
    // Check if username is taken
    final usernameTaken = await UserContentService.isUsernameTaken(username);
    if (usernameTaken) {
      setState(() => _loading = false);
      _showNotification('Username is already taken. Please choose another.', isSuccess: false);
      return;
    }
    
    // Send OTP for signup (registration)
    final otpResp = await _authService.sendSignupOtp(email);
    setState(() => _loading = false);
    
    if (otpResp['sent'] == true) {
      setState(() => _step = 1);
      _showNotification('OTP sent to your email! Please check the server console for the OTP code.', isSuccess: true);
    } else {
      final err = otpResp['error'] ?? 'Failed to send OTP';
      _showNotification(err.toString(), isSuccess: false);
    }
  }

  void _verifyOtpAndRegister() async {
    final email = _email.text.trim();
    final username = _username.text.trim();
    final password = _password.text;
    final otp = _otp.text.trim();
    
    if (otp.isEmpty || otp.length < 4) {
      _showNotification('Please enter a valid OTP', isSuccess: false);
      return;
    }
    
    setState(() => _loading = true);
    final verifyResp = await _authService.verifyEmailOtp(email, otp, password: password, username: username);
    setState(() => _loading = false);
    
    if (verifyResp.containsKey('token') || verifyResp.containsKey('accessToken')) {
      // Save username locally as well
      await UserContentService.setUsername(username);
      _showNotification('Registration successful!', isSuccess: true);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SignInScreen(initialEmail: email)),
        (route) => false,
      );
    } else {
      final err = verifyResp['error'] ?? 'Registration failed. Please check your OTP.';
      _showNotification(err.toString(), isSuccess: false);
    }
  }

  void _goBackToCredentials() {
    setState(() {
      _step = 0;
      _otp.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 0 ? 'Sign Up' : 'Verify OTP'),
        leading: _step == 1 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBackToCredentials,
            )
          : null,
        actions: const [ThemeToggleWidget()],
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
                  _buildStepIndicator(0, 'Details', _step >= 0),
                  Container(width: 40, height: 2, color: _step >= 1 ? Colors.green : Colors.grey[300]),
                  _buildStepIndicator(1, 'Verify OTP', _step >= 1),
                ],
              ),
              const SizedBox(height: 40),
              
              // Step 0: Registration Details
              if (_step == 0) ...[
                TextField(
                  controller: _email,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: const OutlineInputBorder(),
                    errorText: _emailTaken ? 'Email is already registered' : null,
                  ),
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _username,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                    errorText: _usernameTaken ? 'Username is already taken' : null,
                  ),
                  enabled: !_loading,
                  onChanged: (value) async {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty) {
                      setState(() {
                        _usernameTaken = false;
                        _usernameSuggestions = [];
                      });
                      return;
                    }
                    final taken = await UserContentService.isUsernameTaken(trimmed);
                    List<String> suggestions = [];
                    if (taken) {
                      // Suggest alternatives
                      for (int i = 1; i <= 3; i++) {
                        suggestions.add(trimmed + i.toString());
                      }
                      suggestions.add(trimmed + '_official');
                      suggestions.add(trimmed + '_dev');
                    }
                    setState(() {
                      _usernameTaken = taken;
                      _usernameSuggestions = suggestions;
                    });
                  },
                ),
                if (_usernameTaken && _usernameSuggestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Suggestions:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: _usernameSuggestions.map((s) => GestureDetector(
                            onTap: () {
                              _username.text = s;
                              setState(() {
                                _usernameTaken = false;
                                _usernameSuggestions = [];
                              });
                            },
                            child: Builder(
                              builder: (context) {
                                final isDark = Theme.of(context).brightness == Brightness.dark;
                                return Chip(
                                  label: Text(
                                    s,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  backgroundColor: isDark 
                                    ? Colors.blue.shade700 
                                    : Colors.blue.shade100,
                                  side: BorderSide(
                                    color: isDark ? Colors.blue.shade500 : Colors.blue.shade300,
                                    width: 1,
                                  ),
                                );
                              }
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                PasswordInputField(
                  controller: _password,
                  labelText: 'Password',
                  hintText: 'Enter your password (min 6 characters)',
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _validateAndSendOtp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Continue with OTP Verification', style: TextStyle(fontSize: 16)),
                ),
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
                  onPressed: _loading ? null : _verifyOtpAndRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verify & Create Account', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loading ? null : _validateAndSendOtp,
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
            color: isActive ? Colors.green : Colors.grey[300],
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
            color: isActive ? Colors.green : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
