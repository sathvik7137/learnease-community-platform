import 'package:sqlite3/sqlite3.dart';

void main() {
  print('=== CHECKING ROOT users.db ===\n');
  
  try {
    final db = sqlite3.open('C:\\Users\\CyberBot\\Desktop\\Projects\\Intermediate -Flutter\\users.db');
    
    print('✅ Root users.db opened');
    
    // Check tables
    print('\n--- Tables in root users.db ---');
    final tables = db.select('SELECT name FROM sqlite_master WHERE type="table"');
    for (var t in tables) {
      print('  - ${t['name']}');
    }
    
    // Check users
    print('\n--- Users in root users.db ---');
    final users = db.select('SELECT email, password_hash FROM users LIMIT 5');
    if (users.isEmpty) {
      print('  ❌ NO USERS in root database');
    } else {
      for (var u in users) {
        final hash = (u['password_hash'] as String?)?.substring(0, 20) ?? 'NO HASH';
        print('  - ${u['email']}: $hash...');
      }
    }
    
    db.dispose();
  } catch (e) {
    print('❌ Error: $e');
  }
}
