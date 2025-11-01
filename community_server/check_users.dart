import 'package:sqlite3/sqlite3.dart';

void main() {
  try {
    final db = sqlite3.open('users.db');
    print('📊 Checking users in database...\n');
    
    final rows = db.select('SELECT id, email, phone, username, created_at FROM users;');
    
    if (rows.isEmpty) {
      print('❌ No users found in database!');
    } else {
      print('✅ Found ${rows.length} user(s):\n');
      for (final row in rows) {
        print('─────────────────────────────────────');
        print('ID: ${row['id']}');
        print('Email: ${row['email']}');
        print('Phone: ${row['phone'] ?? 'N/A'}');
        print('Username: ${row['username'] ?? 'N/A'}');
        print('Created: ${row['created_at']}');
        print('');
      }
    }
    
    db.dispose();
  } catch (e) {
    print('❌ Error: $e');
  }
}
