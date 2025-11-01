import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  final db = sqlite3.open('users.db');
  
  print('=== PASSWORD VERIFICATION TEST ===\n');
  
  // Get the user
  final result = db.select(
    'SELECT email, password_hash FROM users WHERE LOWER(email) = LOWER(?)',
    ['vardhangaming08@gmail.com']
  );
  
  if (result.isEmpty) {
    print('❌ User not found');
    return;
  }
  
  final user = result.first;
  final email = user['email'] as String;
  final passwordHash = user['password_hash'] as String?;
  
  print('Email: $email');
  print('Hash: ${passwordHash?.substring(0, 30) ?? "NO HASH"}...\n');
  
  // Test different passwords
  final testPasswords = ['Test123456', 'test123456', 'Rvav@2004', 'password'];
  
  for (var pwd in testPasswords) {
    if (passwordHash != null && passwordHash.isNotEmpty) {
      try {
        final valid = BCrypt.checkpw(pwd, passwordHash);
        print('Password "$pwd": ${valid ? "✅ VALID" : "❌ INVALID"}');
      } catch (e) {
        print('Password "$pwd": ⚠️ ERROR: $e');
      }
    }
  }
  
  db.dispose();
}
