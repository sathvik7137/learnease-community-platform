import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('users.db');
  
  print('🔍 Looking for: rayapureddyvardhan2004@gmail.com');
  final result = db.select('SELECT * FROM users WHERE email LIKE ?;', ['%rayapureddyvardhan%']);
  
  if (result.isEmpty) {
    print('❌ NOT FOUND\n');
    print('📊 Current users in database:');
    final allUsers = db.select('SELECT email, username FROM users;');
    for (final row in allUsers) {
      print('  • ${row['email']} (username: ${row['username']})');
    }
  } else {
    print('✅ FOUND:');
    for (final row in result) {
      print('  Email: ${row['email']}');
      print('  Username: ${row['username']}');
      print('  Password Hash: ${(row['password_hash'] as String).substring(0, 20)}...');
    }
  }
  
  db.dispose();
}
