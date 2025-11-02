import 'package:http/http.dart' as http;
import 'dart:convert';
void main() async {
  print('=== COMPLETE LOGIN FLOW TEST ===\n');
  // Step 1: Send OTP (with email + password validation)
  print('STEP 1: Send Email OTP (sendEmailOtp)');
  print('-' * 50);
  final email = 'rayapureddyvardhan2004@gmail.com';
  final password = 'Rvav@2004';
  final step1url = Uri.parse('http://localhost:8080/api/auth/send-email-otp');
  final step1body = jsonEncode({'email': email, 'password': password});
  print('Request: POST /api/auth/send-email-otp');
  print('Body: email=, password=');
  final step1resp = await http.post(
    step1url,
    headers: {'Content-Type': 'application/json'},
    body: step1body,
  );
  print('Response Status: +"${step1resp.statusCode}"+"');
  print('Response Body: +"${step1resp.body}"+"');
  if (step1resp.statusCode != 200) {
    print('\n❌ STEP 1 FAILED - Stopping here');
    return;
  }
  final step1data = jsonDecode(step1resp.body) as Map<String, dynamic>;
  final otp = step1data['code'];
  if (otp == null) {
    print('\n❌ NO OTP CODE IN RESPONSE - Stopping here');
    return;
  }
  print('✅ OTP received: \n');
  // Step 2: Verify OTP
  print('STEP 2: Verify Email OTP (verifyEmailOtp)');
  print('-' * 50);
  final step2url = Uri.parse('http://localhost:8080/api/auth/verify-email-otp');
  final step2body = jsonEncode({
    'email': email,
    'code': otp,
    'password': password
  });
  print('Request: POST /api/auth/verify-email-otp');
  print('Body: email=, code=, password=');
  final step2resp = await http.post(
    step2url,
    headers: {'Content-Type': 'application/json'},
    body: step2body,
  );
  print('Response Status: +"${step2resp.statusCode}"+"');
  print('Response Body: +"${step2resp.body.substring(0, 200)}"+"');
  final step2data = jsonDecode(step2resp.body) as Map<String, dynamic>;
  if (step2data.containsKey('token') || step2data.containsKey('accessToken')) {
    print('\n✅ LOGIN SUCCESSFUL - Token received');
  } else {
    print('\n❌ LOGIN FAILED - No token in response');
  }
}
