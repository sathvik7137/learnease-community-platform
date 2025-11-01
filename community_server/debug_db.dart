import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('users.db');
  
  print('=== DATABASE DEBUG ===');
  print('');
  
  // List all users
  print('--- ALL USERS ---');
  final users = db.select('SELECT id, email, password_hash, username FROM users');
  for (var user in users) {
    print('ID: ${user['id']}');
    print('Email: ${user['email']}');
    print('Password Hash: ${(user['password_hash'] as String?)?.substring(0, 20)}...');
    print('Username: ${user['username']}');
    print('---');
  }
  
  print('');
  print('--- SEARCH FOR vardhangaming08@gmail.com ---');
  final result = db.select(
    'SELECT * FROM users WHERE LOWER(email) = LOWER(?)',
    ['vardhangaming08@gmail.com']
  );
  
  if (result.isEmpty) {
    print('❌ No user found with that email');
  } else {
    print('✅ User found!');
    for (var row in result) {
      print('  Email: ${row['email']}');
      print('  Password Hash exists: ${row['password_hash'] != null && (row['password_hash'] as String).isNotEmpty}');
    }
  }
  
  db.dispose();
}
