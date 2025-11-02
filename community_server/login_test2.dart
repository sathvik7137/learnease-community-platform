import 'package:http/http.dart' as http;
import 'dart:convert';
void main() async {
  final url = Uri.parse('http://localhost:8080/api/auth/login');
  final body = jsonEncode({
    'email': 'vardhangaming08@gmail.com',
    'password': 'Test123456'
  });
  print('🔐 Sending login request...');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('✅ Response status: +"${response.statusCode}"+"');
    print('✅ Response body: +"${response.body}"+"');
  } catch (e) {
    print('❌ Error: +"$e"+"');
  }
}
