import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const email = 'vardhangaming08@gmail.com';
  const password = 'Test123456';
  
  final uri = Uri.parse('http://localhost:8080/api/auth/send-email-otp');
  
  final body = jsonEncode({
    'email': email,
    'password': password,
  });
  
  print('📤 Sending request to send-email-otp...');
  print('   URL: $uri');
  print('   Body: $body');
  
  try {
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 10));
    
    print('\n📥 Response:');
    print('   Status: ${resp.statusCode}');
    print('   Body: ${resp.body}');
    
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (data.containsKey('error')) {
      print('\n❌ Error: ${data['error']}');
    } else if (data.containsKey('sent')) {
      print('\n✅ OTP sent: ${data['sent']}');
    }
  } catch (e) {
    print('❌ Request error: $e');
  }
}
