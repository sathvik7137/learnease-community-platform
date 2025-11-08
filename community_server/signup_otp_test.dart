import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  // Test 1: Send Signup OTP
  print('📧 Test 1: Sending signup OTP...');
  final email = 'newuser+"${DateTime.now().millisecondsSinceEpoch}"+"@example.com';
  final sendOtpUrl = Uri.parse('http://localhost:8080/api/auth/send-signup-otp');
  final sendOtpBody = jsonEncode({'email': email});
  final sendResponse = await http.post(
    sendOtpUrl,
    headers: {'Content-Type': 'application/json'},
    body: sendOtpBody,
  );
  print('  Status: ${sendResponse.statusCode}');
  print('  Email: $email');
  if (sendResponse.statusCode == 200) {
    final responseData = jsonDecode(sendResponse.body);
    print('  Response: $responseData');
    print('  ✅ OTP sent!');
    // Wait a moment
    await Future.delayed(Duration(seconds: 1));
    // Check the server logs manually to get OTP code
    print('\n📝 Please check server logs for OTP code...');
    print('Then we can verify the signup');
  } else {
    print('  ❌ Error: ${sendResponse.body}');
  }
}
