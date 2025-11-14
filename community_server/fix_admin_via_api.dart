import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔧 Admin Credentials Fix Tool\n');
  print('This will set admin credentials via Render API\n');
  
  final password = 'Admin@2024';
  final passkey = '052026';
  final secret = 'learnease-setup-2024';
  
  print('Setting credentials:');
  print('  Password: $password');
  print('  Passkey: $passkey\n');
  
  try {
    print('📡 Sending request to Render...');
    final response = await http.post(
      Uri.parse('https://learnease-community-platform.onrender.com/api/admin/setup-passkey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': password,
        'passkey': passkey,
        'secret': secret,
      }),
    );
    
    print('Status code: ${response.statusCode}\n');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        print('✅ SUCCESS!\n');
        print('=' * 60);
        print('Admin credentials have been set:');
        print('=' * 60);
        print('Email:    admin@learnease.com');
        print('Password: ${data['password']}');
        print('Passkey:  ${data['passkey']}');
        print('=' * 60);
        print('\n🎉 You can now login with these credentials!');
      } else {
        print('❌ Failed: ${data['message'] ?? 'Unknown error'}');
      }
    } else {
      print('❌ HTTP Error ${response.statusCode}');
      print('Response: ${response.body}');
      
      if (response.statusCode == 404) {
        print('\n💡 The setup endpoint may not be deployed yet.');
        print('   Check Render dashboard for deployment status.');
      }
    }
  } catch (e) {
    print('❌ Error: $e');
    print('\n💡 Make sure:');
    print('   1. Render deployment is complete (commit 1133ff0)');
    print('   2. Your internet connection is working');
    print('   3. The Render service is running');
  }
}
