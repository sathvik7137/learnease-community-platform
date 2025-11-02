import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';
void main() {
  final db = sqlite3.open('users.db');
  // Get user
  final user = db.select('SELECT * FROM users WHERE email = ?;', ['vardhangaming08@gmail.com']);
  if (user.isEmpty) {
    print('User not found');
    return;
  }
  final row = user.first;
  final storedHash = row['password_hash'] as String;
  final testPassword = 'Test123456';
  print('Testing BCrypt verification:');
  print('  Stored hash: +"${storedHash.substring(0, 30)}..."+"');
  print('  Test password: +"$testPassword"+"');
  print('  Trimmed stored hash: +"${storedHash.trim().substring(0, 30)}..."+"');
  // Try different approaches
  final match1 = BCrypt.checkpw(testPassword, storedHash);
  print('  Match (direct): +"$match1"+"');
  final match2 = BCrypt.checkpw(testPassword, storedHash.trim());
  print('  Match (trimmed): +"$match2"+"');
  // Check if password was stored as hash
  try {
    final testHash = BCrypt.hashpw(testPassword, BCrypt.gensalt());
    print('  Generated hash for test password: +"${testHash.substring(0, 30)}..."+"');
    print('  Hashes match: +"${testHash == storedHash}"+"');
  } catch (e) {
    print('  Hash generation error: +"$e"+"');
  }
}
