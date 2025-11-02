import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('users.db');
  
  print('🔍 All users in database:');
  print('=' * 80);
  
  final result = db.select('SELECT id, email, username, password_hash FROM users;');
  
  for (final row in result) {
    final email = row['email'];
    final emailLower = (email as String).toLowerCase();
    print('📧 Email: "$email"');
    print('   Lowercase: "$emailLower"');
    print('   Username: ${row['username']}');
    print('   Has Hash: ${(row['password_hash'] as String).isNotEmpty}');
    print('-' * 80);
  }
  
  print('\n🧪 Testing exact lookup:');
  final test1 = db.select('SELECT email FROM users WHERE email = ?;', ['rayapureddyvardhan2004@gmail.com']);
  print('Looking for "rayapureddyvardhan2004@gmail.com": ${test1.isEmpty ? '❌ NOT FOUND' : '✅ FOUND'}');
  
  final test2 = db.select('SELECT email FROM users WHERE LOWER(email) = ?;', ['rayapureddyvardhan2004@gmail.com']);
  print('Looking for LOWER(email) = "rayapureddyvardhan2004@gmail.com": ${test2.isEmpty ? '❌ NOT FOUND' : '✅ FOUND'}');
  
  db.dispose();
}
