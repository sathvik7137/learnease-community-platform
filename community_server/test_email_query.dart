import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('users.db');
  
  print('Test 1: SELECT with exact email');
  var result = db.select('SELECT email FROM users WHERE email = ?;', ['rayapureddyvardhan2004@gmail.com']);
  print('Result: ${result.isEmpty ? "NOT FOUND" : result.first['email']}');
  
  print('\nTest 2: SELECT with lowercase email');
  result = db.select('SELECT email FROM users WHERE email = ?;', ['rayapureddyvardhan2004@gmail.com']);
  print('Result: ${result.isEmpty ? "NOT FOUND" : result.first['email']}');
  
  print('\nTest 3: SELECT all users');
  result = db.select('SELECT email FROM users;');
  for (final row in result) {
    print('Email in DB: "${row['email']}"');
  }
  
  db.dispose();
}
