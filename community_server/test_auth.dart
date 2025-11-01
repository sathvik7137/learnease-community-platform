import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final base = 'http://localhost:8080';
  
  print('Testing Authentication...\n');
  
  // Test 1: Check if server is running
  print('1. Testing server connection...');
  try {
    await http.get(Uri.parse('$base/'));
    print('✅ Server is running');
  } catch (e) {
    print('❌ Server connection failed: $e');
    return;
  }
  
  // Test 2: Try to register a new user
  print('\n2. Testing registration...');
  final email = 'test${DateTime.now().millisecondsSinceEpoch}@example.com';
  final password = 'testPassword123';
  
  try {
    final registerResponse = await http.post(
      Uri.parse('$base/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    if (registerResponse.statusCode == 200) {
      print('✅ Registration successful');
      final data = jsonDecode(registerResponse.body);
      print('Response: $data');
    } else {
      print('❌ Registration failed: ${registerResponse.body}');
    }
  } catch (e) {
    print('❌ Registration error: $e');
  }
  
  // Test 3: Try to login with the registered user
  print('\n3. Testing login with new user...');
  try {
    final loginResponse = await http.post(
      Uri.parse('$base/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    if (loginResponse.statusCode == 200) {
      print('✅ Login successful');
      final data = jsonDecode(loginResponse.body);
      print('Response: $data');
    } else {
      print('❌ Login failed: ${loginResponse.body}');
    }
  } catch (e) {
    print('❌ Login error: $e');
  }
  
  // Test 4: Try to login with existing user (the one in screenshot)
  print('\n4. Testing login with existing user...');
  try {
    final loginResponse = await http.post(
      Uri.parse('$base/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'vardhangaming08@gmail.com',
        'password': 'password123', // Common password to try
      }),
    );
    
    if (loginResponse.statusCode == 200) {
      print('✅ Login successful with existing user');
      final data = jsonDecode(loginResponse.body);
      print('Response: $data');
    } else {
      print('❌ Login failed with existing user: ${loginResponse.body}');
      print('Try different passwords like: password, 123456, password123, test123');
    }
  } catch (e) {
    print('❌ Login error with existing user: $e');
  }
}
