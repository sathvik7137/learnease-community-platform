import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';

void main() {
  final db = sqlite3.open('users.db');
  
  const email = 'rayapureddyvardhan2004@gmail.com';
  const password = 'Rvav@2004';
  const username = 'Vardhan1';
  
  print('Creating user: $email');
  print('Password: $password');
  print('Username: $username');
  
  // Check if user already exists
  final existing = db.select('SELECT id FROM users WHERE email = ?', [email]);
  if (existing.isNotEmpty) {
    print('❌ User already exists! ID: ${existing.first['id']}');
    print('Updating password instead...');
    
    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    db.execute('UPDATE users SET password_hash = ? WHERE email = ?', [hash, email]);
    print('✅ Password updated');
  } else {
    print('User does not exist. Creating...');
    
    final id = const Uuid().v4();
    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    final now = DateTime.now().toIso8601String();
    
    db.execute(
      'INSERT INTO users (id, email, password_hash, username, created_at) VALUES (?, ?, ?, ?, ?)',
      [id, email, hash, username, now]
    );
    
    print('✅ User created successfully');
    print('   ID: $id');
    print('   Email: $email');
    print('   Username: $username');
    print('   Password Hash: ${hash.substring(0, 20)}...');
  }
  
  // Verify
  print('\n🔍 Verification:');
  final check = db.select('SELECT email, username FROM users WHERE email = ?', [email]);
  if (check.isNotEmpty) {
    print('✅ User found in database');
    print('   Email: ${check.first['email']}');
    print('   Username: ${check.first['username']}');
  } else {
    print('❌ User NOT found after creation!');
  }
  
  db.dispose();
}
