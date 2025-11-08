import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing Admin System');
  print('========================\n');

  const String baseUrl = 'http://localhost:8080';
  const String adminEmail = 'admin@learnease.com';
  const String adminPassword = 'admin@123';
  const String adminSecret = 'admin_secret_key';

  // Step 1: Try to login as admin
  print('Step 1: Testing admin login...');
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/admin-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': adminEmail,
        'password': adminPassword,
        'adminSecret': adminSecret,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}\n');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      
      if (token != null) {
        print('✅ Admin login successful!');
        print('Token: ${token.substring(0, 20)}...\n');

        // Step 2: Try to get pending contributions
        print('Step 2: Fetching pending contributions...');
        final pendingResponse = await http.get(
          Uri.parse('$baseUrl/api/contributions/pending'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('Response status: ${pendingResponse.statusCode}');
        if (pendingResponse.statusCode == 200) {
          final pending = jsonDecode(pendingResponse.body) as List<dynamic>;
          print('✅ Found ${pending.length} pending contributions\n');
          
          if (pending.isNotEmpty) {
            print('Sample pending contribution:');
            print(jsonEncode((pending.first as Map<String, dynamic>)));
          }
        } else {
          print('❌ Failed to fetch pending contributions');
          print('Response: ${pendingResponse.body}');
        }
      }
    } else {
      print('❌ Admin login failed');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      print('Error: ${data['error']}');
    }
  } catch (e) {
    print('❌ Exception: $e');
  }

  print('\n✅ Test completed!');
}
