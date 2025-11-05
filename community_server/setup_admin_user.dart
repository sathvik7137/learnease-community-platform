import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  print('🔧 Setting up admin user...\n');

  // Connect to the database
  final db = sqlite3.open('users.db');
  
  const String adminEmail = 'admin@learnease.com';
  const String adminPassword = 'admin@123';
  const String adminPasskey = 'admin_secure_passkey_12345'; // Custom passkey
  
  // Hash the password and passkey
  final passwordHash = BCrypt.hashpw(adminPassword, BCrypt.gensalt());
  final passkeyHash = BCrypt.hashpw(adminPasskey, BCrypt.gensalt());
  
  print('Admin Email: $adminEmail');
  print('Admin Password: $adminPassword');
  print('Admin Passkey: $adminPasskey');
  print('Password Hash: ${passwordHash.substring(0, 30)}...');
  print('Passkey Hash: ${passkeyHash.substring(0, 30)}...\n');
  
  // Check if admin already exists
  try {
    final existing = db.select('SELECT id, email FROM users WHERE email = ?', [adminEmail]);
    if (existing.isNotEmpty) {
      print('⚠️  Admin user already exists');
      print('ID: ${existing.first['id']}');
      print('Email: ${existing.first['email']}');
      
      // Update the password and passkey
      print('\n🔄 Updating admin credentials...');
      db.execute('UPDATE users SET password_hash = ?, admin_passkey = ? WHERE email = ?', [passwordHash, passkeyHash, adminEmail]);
      print('✅ Admin credentials updated!');
    } else {
      throw Exception('Admin user not found');
    }
  } catch (e) {
    print('⚠️  Creating new admin user...');
    try {
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
      print('✅ Admin user created successfully!');
    } catch (createError) {
      print('❌ Error creating admin: $createError');
    }
  }
  
  // Verify the user exists and credentials work
  print('\n🔐 Verifying admin credentials...');
  try {
    final user = db.select('SELECT * FROM users WHERE email = ?', [adminEmail]);
    if (user.isNotEmpty) {
      final row = user.first;
      final storedHash = row['password_hash'] as String;
      final storedPasskeyHash = row['admin_passkey'] as String?;
      final isPasswordValid = BCrypt.checkpw(adminPassword, storedHash);
      final isPasskeyValid = storedPasskeyHash != null && BCrypt.checkpw(adminPasskey, storedPasskeyHash);
      
      if (isPasswordValid && isPasskeyValid) {
        print('✅ Admin credentials verified!');
        print('   Email: ${row['email']}');
        print('   ID: ${row['id']}');
        print('   Username: ${row['username']}');
        print('   Has Admin Passkey: true');
      } else {
        print('❌ Credential verification failed');
        print('   Password valid: $isPasswordValid');
        print('   Passkey valid: $isPasskeyValid');
      }
    }
  } catch (e) {
    print('❌ Verification error: $e');
  }
  
  print('\n✅ Setup complete!');
  print('\nTo login as admin:');
  print('  Email: $adminEmail');
  print('  Password: $adminPassword');
  print('  Passkey: $adminPasskey');
}
