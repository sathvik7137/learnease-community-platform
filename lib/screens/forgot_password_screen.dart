import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0; // 0: email, 1: otp, 2: new password, 3: success
  String? _errorMsg;
  bool _showError = false;
  void _showErrorMsg(String msg) {
    setState(() {
      _errorMsg = msg;
      _showError = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showError = false);
    });
  }
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  bool _resetSuccess = false;

  // ...existing code...

  final AuthService _authService = AuthService();

  void _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showErrorMsg('Please enter a valid email');
      return;
    }
    setState(() => _loading = true);
    final resp = await _authService.sendResetOtp(email);
    setState(() {
      _loading = false;
      _otpSent = resp['sent'] == true;
    });
    if (_otpSent) {
      setState(() => _step = 1);
    } else {
      final err = resp['error'] ?? 'Failed to send OTP';
      _showErrorMsg(err.toString());
    }
  }

  void _resetPassword() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text;
    if (otp.isEmpty || newPassword.length < 6) {
      _showErrorMsg('Enter valid OTP and password (min 6 chars)');
      return;
    }
    setState(() => _loading = true);
    final resp = await _authService.verifyResetOtp(email, otp, newPassword);
    setState(() => _loading = false);
    if (resp['success'] == true) {
      setState(() {
        _resetSuccess = true;
        _step = 3;
      });
    } else {
      final err = resp['error'] ?? 'Reset failed';
      _showErrorMsg(err.toString());
    }
  }

  void _verifyOtpAndProceed() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      _showErrorMsg('Please enter the OTP');
      return;
    }
    setState(() => _loading = true);
    // Validate OTP first before proceeding to password step
    final resp = await _authService.validateResetOtp(email, otp);
    setState(() => _loading = false);
    if (resp['valid'] == true) {
      // OTP is valid, proceed to password entry
      setState(() => _step = 2);
    } else {
      final err = resp['error'] ?? 'OTP verification failed';
      _showErrorMsg(err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A82FB), Color(0xFFFC5C7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Branding/logo
                    Image.asset('assets/images/logo.png', height: 48),
                    const SizedBox(height: 16),
                    // Animated lock icon
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: _step == 3
                          ? Icon(Icons.check_circle, key: const ValueKey('check'), color: Colors.green, size: 56)
                          : Icon(Icons.lock_reset, key: const ValueKey('lock'), color: Theme.of(context).primaryColor, size: 56),
                    ),
                    const SizedBox(height: 12),
                    Text('Reset your password', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 18),
                    // Stepper progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _stepCircle(0, 'Email'),
                        _stepLine(),
                        _stepCircle(1, 'OTP'),
                        _stepLine(),
                        _stepCircle(2, 'New'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_showError && _errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_errorMsg!, style: GoogleFonts.poppins(color: Colors.red, fontSize: 14)),
                      ),
                    if (_step == 0) ...[
                      TextField(
                        controller: _emailCtrl,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _sendOtp,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            elevation: 2,
                            backgroundColor: Color(0xFF6A82FB),
                          ),
                          child: _loading ? const CircularProgressIndicator() : const Text('Send OTP'),
                        ),
                      ),
                    ],
                    if (_step == 1) ...[
                      TextField(
                        controller: _otpCtrl,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          labelText: 'OTP',
                          prefixIcon: const Icon(Icons.verified_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _verifyOtpAndProceed,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            elevation: 2,
                            backgroundColor: Color(0xFF6A82FB),
                          ),
                          child: _loading ? const CircularProgressIndicator() : const Text('Next'),
                        ),
                      ),
                    ],
                    if (_step == 2) ...[
                      TextField(
                        controller: _newPasswordCtrl,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            elevation: 2,
                            backgroundColor: Color(0xFF6A82FB),
                          ),
                          child: _loading ? const CircularProgressIndicator() : const Text('Reset Password'),
                        ),
                      ),
                    ],
                    if (_step == 3) ...[
                      const SizedBox(height: 24),
                      Text('Password reset! You can now log in with your new password.', style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            elevation: 2,
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Back to Login'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepCircle(int step, String label) {
    final active = _step == step || (_step > step);
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF6A82FB) : Colors.grey[300],
            shape: BoxShape.circle,
            border: Border.all(color: active ? const Color(0xFFFC5C7D) : Colors.grey, width: 2),
          ),
          child: Center(
            child: Text('${step + 1}', style: GoogleFonts.poppins(color: active ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: active ? const Color(0xFF6A82FB) : Colors.grey)),
      ],
    );
  }

  Widget _stepLine() {
    return Container(
      width: 32,
      height: 2,
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}
