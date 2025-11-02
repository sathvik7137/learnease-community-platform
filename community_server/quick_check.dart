import 'package:sqlite3/sqlite3.dart';
void main() {
  final db = sqlite3.open('users.db');
  // Get table info
  final result = db.select('PRAGMA table_info(users);');
  print('🔍 Users table schema:');
  for (final row in result) {
    print('  - +"${row['name']}"+ : +"${row['type']}"+"');
  }
  // Get user data
  print('\n👤 User vardhangaming08@gmail.com:');
  final user = db.select('SELECT * FROM users WHERE email = ?;', ['vardhangaming08@gmail.com']);
  if (user.isEmpty) {
    print('  NOT FOUND');
  } else {
    final row = user.first;
    print('  id: +"${row['id']}"+"');
    print('  email: +"${row['email']}"+"');
    print('  password_hash: +"${row['password_hash'] != null ? row['password_hash'].toString().substring(0, 30) + '...' : 'NULL'}"+"');
    print('  phone: +"${row['phone']}"+"');
    print('  username: +"${row['username']}"+"');
  }
}
