import 'package:sqlite3/sqlite3.dart';

void main() {
  try {
    final db = sqlite3.open('users.db');
    
    final rows = db.select(
      'SELECT email, password_hash FROM users WHERE email = ?;',
      ['vardhangaming08@gmail.com']
    );
    
    if (rows.isNotEmpty) {
      final hash = rows.first['password_hash'] as String;
      print('Hash length: ${hash.length}');
      print('Hash starts with: ${hash.substring(0, 20)}...');
      print('Full hash: $hash');
      print('\nHash is valid BCrypt format: ${hash.startsWith('\$2a\$') || hash.startsWith('\$2b\$') || hash.startsWith('\$2y\$')}');
    }
    
    db.dispose();
  } catch (e) {
    print('Error: $e');
  }
}
