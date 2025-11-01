import 'package:sqlite3/sqlite3.dart';

void main() {
  try {
    final db = sqlite3.open('users.db');
    print('✅ Database opened\n');
    
    // Check tables
    print('📋 Available Tables:');
    final tables = db.select("SELECT name FROM sqlite_master WHERE type='table';");
    for (final row in tables) {
      print('  - ${row['name']}');
    }
    print('');
    
    // Check users table schema
    print('📊 Users Table Schema:');
    final schema = db.select('PRAGMA table_info(users);');
    for (final row in schema) {
      print('  Column: ${row['name']}, Type: ${row['type']}');
    }
    print('');
    
    // Count users
    print('🔍 User Count:');
    final count = db.select('SELECT COUNT(*) as cnt FROM users;');
    print('  Total: ${count.first['cnt']}');
    print('');
    
    // Show users if any
    print('👥 Users in Database:');
    final rows = db.select('SELECT id, email, phone, created_at FROM users LIMIT 10;');
    if (rows.isEmpty) {
      print('  ❌ No users found');
    } else {
      for (final row in rows) {
        print('  Email: ${row['email']}, Phone: ${row['phone']}');
      }
    }
    
    db.dispose();
  } catch (e) {
    print('❌ Error: $e');
    print('Stack: ${StackTrace.current}');
  }
}
