import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  print('🔍 Checking stored passkey hash...\n');
  
  final db = sqlite3.open('users.db');
  
  const String passkey = '052026';
  const String adminEmail = 'admin@learnease.com';
  
  try {
    final result = db.select('SELECT admin_passkey FROM users WHERE email = ?', [adminEmail]);
    if (result.isEmpty) {
      print('❌ User not found');
      return;
    }
    
    final hash = result.first['admin_passkey'] as String?;
    print('Hash from DB: "$hash"');
    print('Hash length: ${hash?.length}');
    
    if (hash == null) {
      print('❌ Passkey hash is NULL');
      return;
    }
    
    print('Attempting BCrypt.checkpw...');
    try {
      final isValid = BCrypt.checkpw(passkey, hash);
      print('✅ checkpw result: $isValid');
      
      if (!isValid) {
        print('\n❌ Passkey does not match hash!');
        print('Creating new hash for debugging...');
        final newHash = BCrypt.hashpw(passkey, BCrypt.gensalt());
        print('New hash: $newHash');
        
        // Update the database with the new hash
        db.execute('UPDATE users SET admin_passkey = ? WHERE email = ?', [newHash, adminEmail]);
        print('✅ Database updated with new hash');
        
        // Verify
        final verifyResult = db.select('SELECT admin_passkey FROM users WHERE email = ?', [adminEmail]);
        final updatedHash = verifyResult.first['admin_passkey'] as String?;
        print('Updated hash in DB: "$updatedHash"');
        
        final finalCheck = BCrypt.checkpw(passkey, updatedHash!);
        print('Final verification: $finalCheck');
      }
    } catch (e) {
      print('❌ Error during checkpw: $e');
      print('Hash might be corrupted. Regenerating...');
      
      final newHash = BCrypt.hashpw(passkey, BCrypt.gensalt());
      print('New hash: $newHash');
      
      db.execute('UPDATE users SET admin_passkey = ? WHERE email = ?', [newHash, adminEmail]);
      print('✅ Database updated with new hash');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
