import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  print('🔧 Setting up admin user...\n');

  // Connect to the database
  final db = sqlite3.open('users.db');
  
  const String adminEmail = 'admin@learnease.com';
  const String adminPassword = 'admin@123';
  
  // Hash the password
  final passwordHash = BCrypt.hashpw(adminPassword, BCrypt.gensalt());
  
  print('Admin Email: $adminEmail');
  print('Admin Password: $adminPassword');
  print('Password Hash: ${passwordHash.substring(0, 30)}...\n');
  
  // Check if admin already exists
  try {
    final existing = db.select('SELECT id, email FROM users WHERE email = ?', [adminEmail]);
    if (existing.isNotEmpty) {
      print('⚠️  Admin user already exists');
      print('ID: ${existing.first['id']}');
      print('Email: ${existing.first['email']}');
      
      // Update the password
      print('\n🔄 Updating admin password...');
      db.execute('UPDATE users SET password_hash = ? WHERE email = ?', [passwordHash, adminEmail]);
      print('✅ Admin password updated!');
    } else {
      throw Exception('Admin user not found');
    }
  } catch (e) {
    print('⚠️  Creating new admin user...');
    try {
      db.execute('''
        INSERT INTO users (id, email, password_hash, created_at, username)
        VALUES (?, ?, ?, ?, ?)
      ''', [
        'admin-user-001',
        adminEmail,
        passwordHash,
        DateTime.now().toIso8601String(),
        'admin',
      ]);
      print('✅ Admin user created successfully!');
    } catch (createError) {
      print('❌ Error creating admin: $createError');
    }
  }
  
  // Verify the user exists and password works
  print('\n🔐 Verifying admin credentials...');
  try {
    final user = db.select('SELECT * FROM users WHERE email = ?', [adminEmail]);
    if (user.isNotEmpty) {
      final row = user.first;
      final storedHash = row['password_hash'] as String;
      final isValid = BCrypt.checkpw(adminPassword, storedHash);
      
      if (isValid) {
        print('✅ Admin credentials verified!');
        print('   Email: ${row['email']}');
        print('   ID: ${row['id']}');
        print('   Username: ${row['username']}');
      } else {
        print('❌ Password verification failed');
      }
    }
  } catch (e) {
    print('❌ Verification error: $e');
  }
  
  print('\n✅ Setup complete!');
  print('\nTo login as admin:');
  print('  Email: $adminEmail');
  print('  Password: $adminPassword');
  print('  Admin Secret: admin_secret_key');
}
