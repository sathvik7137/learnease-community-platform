import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  print('🔧 Quick Admin Setup\n');

  // Connect to the database
  final db = sqlite3.open('users.db');
  
  const String adminEmail = 'admin@learnease.com';
  const String adminPassword = 'admin@123';
  const String adminPasskey = '052026';
  
  print('Adding admin_passkey column if missing...');
  try {
    db.execute('ALTER TABLE users ADD COLUMN admin_passkey TEXT;');
    print('✅ Column added');
  } catch (e) {
    print('✅ Column already exists or error: $e');
  }
  
  // Hash credentials
  final passwordHash = BCrypt.hashpw(adminPassword, BCrypt.gensalt());
  final passkeyHash = BCrypt.hashpw(adminPasskey, BCrypt.gensalt());
  
  // Update existing admin or create new one
  try {
    final existing = db.select('SELECT id FROM users WHERE email = ?', [adminEmail]);
    if (existing.isNotEmpty) {
      print('\n🔄 Updating existing admin user...');
      db.execute('UPDATE users SET password_hash = ?, admin_passkey = ? WHERE email = ?', 
        [passwordHash, passkeyHash, adminEmail]);
      print('✅ Admin credentials updated!');
    } else {
      print('\n➕ Creating new admin user...');
      db.execute('''
        INSERT INTO users (id, email, password_hash, created_at, username, admin_passkey)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        'admin-user-001',
        adminEmail,
        passwordHash,
        DateTime.now().toIso8601String(),
        'admin',
        passkeyHash,
      ]);
      print('✅ Admin user created!');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
  
  // Verify
  print('\n🔐 Verifying...');
  final user = db.select('SELECT * FROM users WHERE email = ?', [adminEmail]);
  if (user.isNotEmpty) {
    final row = user.first;
    final pwValid = BCrypt.checkpw(adminPassword, row['password_hash'] as String);
    final pkValid = row['admin_passkey'] != null && 
                    BCrypt.checkpw(adminPasskey, row['admin_passkey'] as String);
    
    print('✅ Admin Email: $adminEmail');
    print('✅ Password Valid: $pwValid');
    print('✅ Passkey Valid: $pkValid');
    print('✅ admin_passkey column exists: ${row['admin_passkey'] != null}');
  }
  
  print('\n✅ Setup Complete!\n');
  print('Login with:');
  print('  Email: $adminEmail');
  print('  Password: $adminPassword');
  print('  Passkey: $adminPasskey');
  
  // db.close(); // SQLite3 doesn't have close() method
}
