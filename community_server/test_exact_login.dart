import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  // Test exact email from screenshot
  const email = 'vardhangaming08@gmail.com';
  const password = 'Test123456';
  
  print('🧪 Testing login with exact values from screenshot...\n');
  print('Email: $email');
  print('Password: $password');
  print('Password length: ${password.length}\n');
  
  // Step 1: Test send-email-otp endpoint
  print('Step 1: Testing /api/auth/send-email-otp');
  try {
    final uri = Uri.parse('http://localhost:8080/api/auth/send-email-otp');
    final body = jsonEncode({'email': email, 'password': password});
    
    print('  Request body: $body');
    
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 10));
    
    print('  Status: ${resp.statusCode}');
    print('  Response: ${resp.body}\n');
    
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    
    if (resp.statusCode == 200 && data['sent'] == true) {
      print('✅ OTP SENT SUCCESSFULLY');
      if (data['code'] != null) {
        print('OTP Code (for testing): ${data['code']}');
      }
    } else if (resp.statusCode >= 400) {
      print('❌ ERROR: ${data['error'] ?? 'Unknown error'}');
    }
  } catch (e) {
    print('❌ Network error: $e');
  }
}
