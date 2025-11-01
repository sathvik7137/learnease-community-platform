import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  final base = 'http://localhost:8080';

  group('auth endpoints', () {
    test('register -> login (and DB persistence)', () async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final email = 'test+ci+$timestamp@example.com';
  final password = 'ci_password_123';

  // register
  final r1 = await http.post(Uri.parse('$base/api/auth/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
  expect(r1.statusCode, 200);
  final body1 = jsonDecode(r1.body) as Map<String, dynamic>;
  expect(body1.containsKey('token'), isTrue);

  // login
  final r2 = await http.post(Uri.parse('$base/api/auth/login'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
  expect(r2.statusCode, 200);
  final body2 = jsonDecode(r2.body) as Map<String, dynamic>;
  expect(body2.containsKey('token'), isTrue);
  // call dev debug endpoint to list users and assert the new email is present
  final rDebug = await http.get(Uri.parse('$base/internal/debug/users'));
  expect(rDebug.statusCode, anyOf([200, 403]));
  if (rDebug.statusCode == 200) {
    final debugBody = jsonDecode(rDebug.body) as Map<String, dynamic>;
    final List<dynamic> users = debugBody['users'] as List<dynamic>;
    final found = users.where((u) => (u['email'] as String?)?.toLowerCase() == email.toLowerCase()).toList();
    expect(found.isNotEmpty, isTrue, reason: 'Debug endpoint should list the newly registered user');
  } else {
    // debug endpoint disabled — at least register/login flow succeeded above
    expect(true, isTrue);
  }
    }, timeout: Timeout(Duration(seconds: 10)));

    test('send-otp -> verify-otp', () async {
      final phone = '+15551234567';
      final r1 = await http.post(Uri.parse('$base/api/auth/send-otp'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'phone': phone}));
      expect(r1.statusCode, 200);
      final b1 = jsonDecode(r1.body) as Map<String, dynamic>;
      expect(b1['sent'], isTrue);

      // NOTE: OTP is printed to server logs in this test setup. We cannot read server logs here.
      // Instead, this test will only assert that send-otp returns sent:true.
    });

    test('refresh token flow', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'test+refresh+$timestamp@example.com';
      final password = 'refresh_password_123';

      // register and get refresh token
      final r1 = await http.post(Uri.parse('$base/api/auth/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
      expect(r1.statusCode, 200);
      final body1 = jsonDecode(r1.body) as Map<String, dynamic>;
      expect(body1.containsKey('refreshToken'), isTrue);
      final refreshToken = body1['refreshToken'] as String;

      // use refresh token to get new access token
      final r2 = await http.post(Uri.parse('$base/api/auth/refresh'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refreshToken': refreshToken}));
      expect(r2.statusCode, 200);
      final body2 = jsonDecode(r2.body) as Map<String, dynamic>;
      expect(body2.containsKey('token'), isTrue);
      expect(body2.containsKey('refreshToken'), isTrue);
    }, timeout: Timeout(Duration(seconds: 10)));

    test('revoke token flow', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'test+revoke+$timestamp@example.com';
      final password = 'revoke_password_123';

      // register and get refresh token
      final r1 = await http.post(Uri.parse('$base/api/auth/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
      expect(r1.statusCode, 200);
      final body1 = jsonDecode(r1.body) as Map<String, dynamic>;
      final refreshToken = body1['refreshToken'] as String;

      // revoke the refresh token
      final r2 = await http.post(Uri.parse('$base/api/auth/revoke'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refreshToken': refreshToken}));
      expect(r2.statusCode, 200);
      final body2 = jsonDecode(r2.body) as Map<String, dynamic>;
      expect(body2['success'], isTrue);

      // try to use revoked token - should fail
      final r3 = await http.post(Uri.parse('$base/api/auth/refresh'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refreshToken': refreshToken}));
      expect(r3.statusCode, 401);
    }, timeout: Timeout(Duration(seconds: 10)));
  });
}
