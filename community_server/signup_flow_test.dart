import 'package:http/http.dart' as http;
import 'dart:convert';
void main() async {
  // Test 1: Send OTP
  print('�� Test 1: Sending OTP...');
  final sendOtpUrl = Uri.parse('http://localhost:8080/api/auth/send-signup-otp');
  final sendOtpBody = jsonEncode({'email': 'newtest@example.com'});
  final sendResponse = await http.post(
    sendOtpUrl,
    headers: {'Content-Type': 'application/json'},
    body: sendOtpBody,
  );
  print('  Status: +"${sendResponse.statusCode}"+"');
  print('  Response: +"${sendResponse.body}"+"');
  if (sendResponse.statusCode == 200) {
    final responseData = jsonDecode(sendResponse.body);
    final code = responseData['code'];
    print('  ✅ OTP sent! Code: +"$code"+"');
    // Test 2: Verify OTP
    print('\n✅ Test 2: Verifying OTP...');
    final verifyUrl = Uri.parse('http://localhost:8080/api/auth/verify-signup-otp');
    final verifyBody = jsonEncode({
      'email': 'newtest@example.com',
      'code': code,
      'password': 'NewTest@1234'
    });
    final verifyResponse = await http.post(
      verifyUrl,
      headers: {'Content-Type': 'application/json'},
      body: verifyBody,
    );
    print('  Status: +"${verifyResponse.statusCode}"+"');
    print('  Response: +"${verifyResponse.body}"+"');
  }
}
