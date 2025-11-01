import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String phone;
  const OtpVerifyScreen({Key? key, required this.phone}) : super(key: key);

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  void _verify() async {
    setState(() => _loading = true);
  final resp = await AuthService().verifyOtp(widget.phone, _codeCtrl.text.trim());
    setState(() => _loading = false);
    if (resp.containsKey('accessToken') || resp.containsKey('token')) {
      // Tokens are already saved by AuthService
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final err = resp['error'] ?? 'OTP verification failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString())));
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the OTP sent to ${widget.phone}'),
            const SizedBox(height: 12),
            TextField(controller: _codeCtrl, decoration: const InputDecoration(labelText: 'OTP code')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loading ? null : _verify, child: _loading ? const CircularProgressIndicator() : const Text('Verify')),
          ],
        ),
      ),
    );
  }
}
