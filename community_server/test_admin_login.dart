import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Testing Admin Login Directly\n');
  
  final email = 'admin@learnease.com';
  final password = 'Admin@2024';
  final passkey = '052026';
  
  print('Attempting login with:');
  print('  Email: $email');
  print('  Password: $password');
  print('  Passkey: $passkey\n');
  
  try {
    print('📡 Sending login request to Render...');
    final response = await http.post(
      Uri.parse('https://learnease-community-platform.onrender.com/api/auth/admin-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'passkey': passkey,
      }),
    );
    
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}\n');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ LOGIN SUCCESSFUL!\n');
      print('Token: ${data['token']?.substring(0, 20)}...');
      print('User: ${data['user']}');
    } else {
      print('❌ LOGIN FAILED\n');
      final data = jsonDecode(response.body);
      print('Error: ${data['error']}');
      
      print('\n📋 Possible issues:');
      print('1. Admin user does not exist in MongoDB');
      print('2. Password/passkey fields are null or wrong');
      print('3. Field names mismatch (password_hash vs passwordHash)');
      
      print('\n🔍 Check Render logs for:');
      print('   [ADMIN_LOGIN] lines to see exact error');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
