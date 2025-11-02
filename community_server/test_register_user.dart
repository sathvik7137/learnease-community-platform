import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';

void main() {
  final db = sqlite3.open('users.db');
  
  // Test email and password
  const testEmail = 'test@example.com';
  const testPassword = 'password123';
  const testUsername = 'testuser';
  
  try {
    // Check if user already exists
    final existing = db.select('SELECT email FROM users WHERE email = ?', [testEmail]);
    if (existing.isNotEmpty) {
      print('❌ User already exists: $testEmail');
      return;
    }
    
    // Hash password
    final hash = BCrypt.hashpw(testPassword, BCrypt.gensalt());
    final userId = const Uuid().v4();
    final createdAt = DateTime.now().toIso8601String();
    
    // Insert user
    final stmt = db.prepare(
      'INSERT INTO users (id, email, password_hash, username, created_at) VALUES (?, ?, ?, ?, ?)'
    );
    stmt.execute([userId, testEmail, hash, testUsername, createdAt]);
    stmt.dispose();
    
    print('✅ Test user created successfully!');
    print('📧 Email: $testEmail');
    print('🔑 Password: $testPassword');
    print('👤 Username: $testUsername');
    print('');
    print('You can now login with these credentials in the Flutter app');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
