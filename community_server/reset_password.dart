import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  print('=== Password Reset Tool ===\n');
  
  // Open database
  final db = sqlite3.open('users.db');
  
  // Get user
  final stmt = db.prepare('SELECT email, username FROM users WHERE email = ?');
  final result = stmt.select(['vardhangaming08@gmail.com']);
  
  if (result.isEmpty) {
    print('❌ User not found!');
    db.dispose();
    return;
  }
  
  final user = result.first;
  print('Found user: ${user['email']}');
  
  // Ask for new password
  stdout.write('\nEnter new password: ');
  final newPassword = stdin.readLineSync() ?? '';
  
  if (newPassword.isEmpty) {
    print('❌ Password cannot be empty!');
    db.dispose();
    return;
  }
  
  // Hash the new password
  print('\n🔄 Hashing password...');
  final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
  
  // Update in database
  db.execute('''
    UPDATE users 
    SET password_hash = ? 
    WHERE email = ?
  ''', [hash, 'vardhangaming08@gmail.com']);
  
  print('✅ Password updated successfully!');
  print('\n📧 Email: vardhangaming08@gmail.com');
  print('🔑 New Password: $newPassword');
  print('\nYou can now sign in with this password.');
  
  db.dispose();
}
