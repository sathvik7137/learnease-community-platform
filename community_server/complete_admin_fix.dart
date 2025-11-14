import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔧 COMPLETE Admin Fix - Creating User from Scratch\n');
  
  final email = 'admin@learnease.com';
  final password = 'Admin@2024';
  final passkey = '052026';
  final username = 'admin';
  
  // First, try to register the admin user
  print('Step 1: Creating admin user via registration...');
  
  try {
    final registerResponse = await http.post(
      Uri.parse('https://learnease-community-platform.onrender.com/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'username': username,
      }),
    );
    
    print('Registration status: ${registerResponse.statusCode}');
    
    if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
      print('✅ User registered successfully\n');
    } else if (registerResponse.statusCode == 400) {
      print('ℹ️  User already exists (this is OK)\n');
    } else {
      print('Response: ${registerResponse.body}\n');
    }
    
    // Now set the passkey
    print('Step 2: Setting passkey for admin user...');
    
    final passkeyResponse = await http.post(
      Uri.parse('https://learnease-community-platform.onrender.com/api/admin/setup-passkey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': password,
        'passkey': passkey,
        'secret': 'learnease-setup-2024',
      }),
    );
    
    print('Passkey setup status: ${passkeyResponse.statusCode}');
    print('Response: ${passkeyResponse.body}\n');
    
    // Now test login
    print('Step 3: Testing admin login...');
    
    final loginResponse = await http.post(
      Uri.parse('https://learnease-community-platform.onrender.com/api/auth/admin-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'passkey': passkey,
      }),
    );
    
    print('Login status: ${loginResponse.statusCode}');
    
    if (loginResponse.statusCode == 200) {
      print('✅ LOGIN SUCCESSFUL!\n');
      print('=' * 60);
      print('Your admin credentials:');
      print('=' * 60);
      print('Email:    $email');
      print('Password: $password');
      print('Passkey:  $passkey');
      print('=' * 60);
      print('\n🎉 Admin login is now working!');
    } else {
      print('❌ Login failed: ${loginResponse.body}\n');
      print('🔍 Next steps:');
      print('1. Check Render logs at: https://dashboard.render.com');
      print('2. Look for [ADMIN_LOGIN] error messages');
      print('3. The admin user may not exist in MongoDB at all');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
