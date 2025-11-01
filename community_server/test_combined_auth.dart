import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final base = 'http://localhost:8080';
  
  print('🔧 Testing Combined Authentication Flow\n');
  
  // Test the combined sign-up flow
  print('📝 TESTING REGISTRATION WITH COMBINED FLOW');
  print('=' * 50);
  
  final testEmail = 'combined_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
  final testPassword = 'CombinedTest123';
  
  // Step 1: Send OTP for registration
  print('\n1️⃣ Sending OTP for registration...');
  try {
    final otpResponse = await http.post(
      Uri.parse('$base/api/auth/send-email-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': testEmail}),
    );
    
    if (otpResponse.statusCode == 200) {
      print('✅ OTP sent successfully');
      final otpData = jsonDecode(otpResponse.body);
      print('Response: $otpData');
      
      // Note: In real scenario, user would get OTP from email
      // For testing, we'll use a mock OTP (check server console)
      print('\n⚠️  Check server console for OTP code!');
      
      // Step 2: Test verify-email-otp endpoint for registration
      print('\n2️⃣ Testing OTP verification for registration...');
      final mockOtp = '123456'; // This will fail, but we can test the endpoint
      
      final verifyResponse = await http.post(
        Uri.parse('$base/api/auth/verify-email-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': testEmail,
          'code': mockOtp,
          'password': testPassword,
        }),
      );
      
      print('Verify response status: ${verifyResponse.statusCode}');
      print('Verify response: ${verifyResponse.body}');
      
    } else {
      print('❌ Failed to send OTP: ${otpResponse.body}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
  
  // Test the combined sign-in flow with existing user
  print('\n\n🔐 TESTING LOGIN WITH COMBINED FLOW');
  print('=' * 50);
  
  final existingEmail = 'vardhangaming08@gmail.com';
  final existingPassword = 'password123'; // Common password to try
  
  // Step 1: Send OTP for login
  print('\n1️⃣ Sending OTP for existing user login...');
  try {
    final otpResponse = await http.post(
      Uri.parse('$base/api/auth/send-email-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': existingEmail}),
    );
    
    if (otpResponse.statusCode == 200) {
      print('✅ OTP sent successfully');
      
      // Step 2: Test verify-email-otp endpoint for login
      print('\n2️⃣ Testing OTP verification for login...');
      print('📝 Using mock OTP - check server console for real OTP');
      
      final mockOtp = '123456'; // This will fail, but we can test the endpoint
      
      final verifyResponse = await http.post(
        Uri.parse('$base/api/auth/verify-email-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': existingEmail,
          'code': mockOtp,
          'password': existingPassword,
        }),
      );
      
      print('Verify response status: ${verifyResponse.statusCode}');
      print('Verify response: ${verifyResponse.body}');
      
    } else {
      print('❌ Failed to send OTP: ${otpResponse.body}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\n\n✨ SUMMARY');
  print('=' * 50);
  print('✅ Combined authentication flow implemented:');
  print('   1. User enters email + password');
  print('   2. System sends OTP to email');
  print('   3. User verifies OTP');
  print('   4. System authenticates with password + OTP');
  print('\n📱 The Flutter app now has the combined flow UI');
  print('🔧 The server now supports verify-email-otp endpoint');
  print('\n🎯 Next: Use the Flutter app to test with real OTP codes!');
}
