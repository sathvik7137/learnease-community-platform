import 'package:http/http.dart' as http;
import 'dart:convert';
void main() async {
  print('Testing sendEmailOtp endpoint (Step 1 of login flow)');
  print('=' * 50);
  final url = Uri.parse('http://localhost:8080/api/auth/send-email-otp');
  final body = jsonEncode({
    'email': 'rayapureddyvardhan2004@gmail.com',
    'password': 'Rvav@2004'
  });
  print('POST /api/auth/send-email-otp');
  print('Body: email=rayapureddyvardhan2004@gmail.com, password=Rvav@2004');
  print('');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('Status: +"${response.statusCode}"+"');
    print('Response: +"${response.body}"+"');
    if (response.statusCode == 200) {
      print('\n✅ SUCCESS - OTP sent');
    } else {
      print('\n❌ FAILED - ');
    }
  } catch (e) {
    print('Error: +"$e"+"');
  }
}
