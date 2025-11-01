import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  try {
    final db = sqlite3.open('users.db');
    print('✅ Database opened\n');
    
    const testEmail = 'vardhangaming08@gmail.com';
    const testPassword = 'Test123456';
    
    print('🔍 Testing login flow for: $testEmail\n');
    
    // Step 1: Test query (case-insensitive)
    print('Step 1️⃣ : Testing email query...');
    
    // Query as app sends it (lowercase)
    final lowerEmail = testEmail.toLowerCase();
    print('   Query email (lowercase): $lowerEmail');
    
    final rows = db.select(
      'SELECT * FROM users WHERE email = ?;',
      [lowerEmail]
    );
    
    if (rows.isEmpty) {
      print('   ❌ NO ROWS FOUND');
      
      // Debug: show all emails in DB
      print('\n   📋 All emails in database:');
      final allRows = db.select('SELECT id, email FROM users;');
      if (allRows.isEmpty) {
        print('      ❌ Database is empty!');
      } else {
        for (final row in allRows) {
          final dbEmail = row['email'] as String?;
          print('      - "$dbEmail"');
        }
      }
      db.dispose();
      return;
    }
    
    print('   ✅ Found ${rows.length} user(s)');
    final row = rows.first;
    
    // Step 2: Extract password hash
    print('\nStep 2️⃣ : Extracting password hash...');
    final storedHash = row['password_hash'] as String?;
    if (storedHash == null || storedHash.isEmpty) {
      print('   ❌ Password hash is null or empty!');
      db.dispose();
      return;
    }
    
    print('   ✅ Hash found');
    
    // Step 3: Validate hash format
    print('\nStep 3️⃣ : Validating hash format...');
    final isBcrypt = storedHash.startsWith('\$2a\$') ||
                     storedHash.startsWith('\$2b\$') ||
                     storedHash.startsWith('\$2y\$');
    print('   Is valid BCrypt: ${isBcrypt ? "✅ YES" : "❌ NO"}');
    
    if (!isBcrypt) {
      print('   Hash appears corrupted');
      db.dispose();
      return;
    }
    
    // Step 4: Test password verification
    print('\nStep 4️⃣ : Testing password verification...');
    print('   Test password: $testPassword');
    
    try {
      final isValid = BCrypt.checkpw(testPassword, storedHash);
      print('   Result: ${isValid ? "✅ PASSWORD MATCH" : "❌ PASSWORD MISMATCH"}');
    } catch (e) {
      print('   ❌ BCrypt error: $e');
    }
    
    // Step 5: Display full user record
    print('\nStep 5️⃣ : Full user record:');
    print('   ID: ${row['id']}');
    print('   Email: ${row['email']}');
    print('   Username: ${row['username'] ?? "N/A"}');
    print('   Phone: ${row['phone'] ?? "N/A"}');
    print('   Created: ${row['created_at']}');
    
    db.dispose();
    print('\n✅ Diagnostic complete');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
