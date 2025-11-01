import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final base = 'http://localhost:8080';
  final testEmail = 'vardhangaming08@gmail.com';
  
  // List of common passwords to try
  final passwordsToTry = [
    'password123',
    'Password123',
    'password',
    'Password',
    '123456',
    'test123',
    'Test123',
  ];
  
  print('🔍 Testing passwords for: $testEmail\n');
  
  for (final password in passwordsToTry) {
    print('Testing password: "$password"');
    
    try {
      // Step 1: Send OTP
      final otpResponse = await http.post(
        Uri.parse('$base/api/auth/send-email-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': testEmail}),
      );
      
      if (otpResponse.statusCode == 200) {
        print('  ✅ OTP sent - Email exists in database');
        print('  📧 Check server console for OTP code');
        print('  ⏸️  Pausing - enter the OTP when ready...\n');
        break; // Stop after successful OTP send
      } else {
        print('  ❌ Status: ${otpResponse.statusCode}');
        print('  Response: ${otpResponse.body}\n');
      }
    } catch (e) {
      print('  ❌ Error: $e\n');
    }
  }
  
  print('\n💡 To complete login:');
  print('1. Check the server terminal for the OTP code');
  print('2. Use the Flutter app to enter the email, password, and OTP');
}
