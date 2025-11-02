import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  final db = sqlite3.open('users.db');
  
  print('=== Testing User Password ===\n');
  
  final email = 'vardhangaming08@gmail.com';
  
  // Get user from database
  final result = db.select(
    'SELECT email, password_hash, username, created_at FROM users WHERE email = ?',
    [email]
  );
  
  if (result.isEmpty) {
    print('❌ User not found!');
    db.dispose();
    return;
  }
  
  final row = result.first;
  final passwordHash = row['password_hash'] as String;
  final username = row['username'] as String?;
  final createdAt = row['created_at'] as String;
  
  print('User found:');
  print('  Email: $email');
  print('  Username: ${username ?? "(empty)"}');
  print('  Created: $createdAt');
  print('  Password Hash: ${passwordHash.substring(0, 20)}...\n');
  
  // Test common passwords
  final testPasswords = [
    'password123',
    'Password123',
    'Vardhan@123',
    'vardhan123',
    '123456',
    'Rvav@2004',
    'test1234',
    'admin123',
    'Test123456'
  ];
  
  print('Testing passwords:');
  for (final pwd in testPasswords) {
    final isValid = BCrypt.checkpw(pwd, passwordHash);
    if (isValid) {
      print('✅ MATCH FOUND: "$pwd"');
      break;
    } else {
      print('❌ "$pwd" - no match');
    }
  }
  
  print('\nIf none matched, you need to remember or reset the password.');
  
  db.dispose();
}
