import 'package:sqlite3/sqlite3.dart';

void main() {
  try {
    final db = sqlite3.open('users.db');
    print('🔍 Checking password for vardhangaming08@gmail.com...\n');
    
    final rows = db.select(
      'SELECT id, email, password_hash FROM users WHERE email = ?;',
      ['vardhangaming08@gmail.com']
    );
    
    if (rows.isEmpty) {
      print('❌ User not found');
    } else {
      final row = rows.first;
      print('Email: ${row['email']}');
      print('Password Hash: ${row['password_hash']}');
      
      if (row['password_hash'] == null) {
        print('\n⚠️ PROBLEM: Password hash is NULL!');
        print('This means the password was never saved during registration.');
      } else {
        print('\n✅ Password hash exists!');
        print('Hash starts with: ${row['password_hash'].toString().substring(0, 20)}...');
      }
    }
    
    db.dispose();
  } catch (e) {
    print('❌ Error: $e');
  }
}
