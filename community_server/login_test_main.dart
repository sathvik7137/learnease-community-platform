import 'package:http/http.dart' as http;
import 'dart:convert';
void main() async {
  print('Testing login with rayapureddyvardhan2004@gmail.com');
  final url = Uri.parse('http://localhost:8080/api/auth/login');
  final body = jsonEncode({
    'email': 'rayapureddyvardhan2004@gmail.com',
    'password': 'Rvav@2004'
  });
  print('Email: rayapureddyvardhan2004@gmail.com');
  print('Password: Rvav@2004');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('Status: +"${response.statusCode}"+"');
    print('Response: +"${response.body}"+"');
  } catch (e) {
    print('Error: +"$e"+"');
  }
}
