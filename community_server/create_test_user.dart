import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';

void main() {
  try {
    final db = sqlite3.open('users.db');
    print('🔧 Creating test user...\n');
    
    final testEmail = 'test@example.com';
    const testPassword = 'Test@1234';
    const testUsername = 'TestUser';
    
    // Check if user already exists
    final existing = db.select('SELECT email FROM users WHERE email = ?;', [testEmail]);
    if (existing.isNotEmpty) {
      print('⚠️  User already exists: $testEmail');
      print('   Try logging in with password: $testPassword');
      db.dispose();
      return;
    }
    
    // Hash the password
    final hashedPassword = BCrypt.hashpw(testPassword, BCrypt.gensalt());
    final userId = const Uuid().v4();
    
    // Insert the user
    db.execute(
      'INSERT INTO users (id, email, password_hash, username, created_at) VALUES (?, ?, ?, ?, ?);',
      [userId, testEmail, hashedPassword, testUsername, DateTime.now().toIso8601String()],
    );
    
    print('✅ Test user created successfully!\n');
    print('📧 Email: $testEmail');
    print('🔐 Password: $testPassword');
    print('👤 Username: $testUsername');
    print('\n💡 Use these credentials to log in to the app.');
    
    db.dispose();
  } catch (e) {
    print('❌ Error: $e');
  }
}
