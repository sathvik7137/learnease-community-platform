import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';

void main() {
  final db = sqlite3.open('users.db');
  
  const email = 'rayapureddyvardhan2004@gmail.com';
  const password = 'Rvav@2004';
  const username = 'Vardhan1';
  
  print('🔧 Creating user in database');
  print('📧 Email: $email');
  print('🔑 Password: $password');
  print('👤 Username: $username');
  
  try {
    final id = const Uuid().v4();
    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    final now = DateTime.now().toIso8601String();
    
    print('\n🔐 Hash generated: ${hash.substring(0, 30)}...');
    
    // Use a simple INSERT statement
    final stmt = db.prepare(
      'INSERT INTO users (id, email, password_hash, username, created_at) VALUES (?, ?, ?, ?, ?)'
    );
    
    stmt.execute([id, email, hash, username, now]);
    stmt.dispose();
    
    print('✅ User inserted');
    
    // Verify immediately
    final verify = db.select('SELECT id, email, username FROM users WHERE email = ?', [email]);
    
    if (verify.isNotEmpty) {
      final row = verify.first;
      print('\n✅✅✅ USER CREATED SUCCESSFULLY!');
      print('ID: ${row['id']}');
      print('Email: ${row['email']}');
      print('Username: ${row['username']}');
    } else {
      print('\n❌ User not found after insert!');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
  
  db.dispose();
}
