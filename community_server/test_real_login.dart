import 'package:http/http.dart' as http;
import 'dart:convert';
void main() async {
  // Test with the actual user credentials  
  const email = 'rayapureddyvardhan2004@gmail.com';
  const password = 'Rvav@2004';
  // Test Direct Login
  print('Testing:  / \n');
  final resp = await http.post(
    Uri.parse('http://localhost:8080/api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  print('Direct Login: Status +"${resp.statusCode}"+"'');
  if (resp.statusCode == 200) {
    print('SUCCESS - Token issued');
    final data = jsonDecode(resp.body);
    if (data['user'] != null) {
      print('User: +"${data['user']['email']}"+"'');
    }
  } else {
    print('FAILED: +"${resp.body}"+"'');
  }
}
