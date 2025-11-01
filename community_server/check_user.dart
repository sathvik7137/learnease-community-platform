import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  try {
    final db = sqlite3.open('users.db');
    print('✅ Database opened\n');
    
    print('🔍 User Details:');
    final rows = db.select(
      'SELECT id, email, phone, password_hash, google_id, created_at, username FROM users WHERE email = ?;',
      ['vardhangaming08@gmail.com']
    );
    
    if (rows.isEmpty) {
      print('❌ User not found');
    } else {
      final row = rows.first;
      print('Email: ${row['email']}');
      print('Username: ${row['username'] ?? 'N/A'}');
      print('Phone: ${row['phone'] ?? 'N/A'}');
      print('Password Hash: ${row['password_hash']}');
      print('Google ID: ${row['google_id'] ?? 'N/A'}');
      print('Created: ${row['created_at']}');
      print('ID: ${row['id']}\n');
      
      // Test password verification
      final testPasswords = [
        'Test123456',  // NEW PASSWORD
        'password123',
        '123456',
        'test123',
      ];
      
      print('🔑 Testing passwords:');
      final hash = row['password_hash'] as String;
      for (final pwd in testPasswords) {
        try {
          final isValid = BCrypt.checkpw(pwd, hash);
          print('  "$pwd": ${isValid ? '✅ MATCH' : '❌ no match'}');
        } catch (e) {
          print('  "$pwd": ❌ Error - $e');
        }
      }
    }
    
    db.dispose();
  } catch (e) {
    print('❌ Error: $e');
  }
}
