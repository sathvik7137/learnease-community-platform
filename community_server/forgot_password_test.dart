import 'package:http/http.dart' as http;
import 'dart:convert';
void main() async {
  print('🔄 Testing Forgot Password Flow');
  // Step 1: Request password reset OTP
  print('\n📧 Step 1: Send reset OTP to existing user...');
  final sendResetUrl = Uri.parse('http://localhost:8080/api/auth/send-reset-otp');
  final sendResetBody = jsonEncode({'email': 'vardhangaming08@gmail.com'});
  final sendResetResponse = await http.post(
    sendResetUrl,
    headers: {'Content-Type': 'application/json'},
    body: sendResetBody,
  );
  print('  Status: ${sendResetResponse.statusCode}');
  print('  Response: ${sendResetResponse.body.substring(0, 100)}');
  if (sendResetResponse.statusCode == 200) {
    final resetData = jsonDecode(sendResetResponse.body);
    print('  OTP sent: ${resetData['sent']}');
    print('  OTP code: ${resetData['code']} (check server logs)');
  }
}
