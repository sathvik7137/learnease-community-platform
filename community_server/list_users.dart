import 'package:sqlite3/sqlite3.dart';

void main() {
  try {
    final db = sqlite3.open('users.db');
    print('✅ Database opened successfully\n');
    
    print('📋 Registered Users:');
    print('================================');
    
    final rows = db.select('SELECT id, email, phone, created_at FROM users;');
    
    if (rows.isEmpty) {
      print('❌ No users found in database');
    } else {
      print('Total users: ${rows.length}\n');
      for (final row in rows) {
        print('ID: ${row['id']}');
        print('Email: ${row['email'] ?? 'N/A'}');
        print('Phone: ${row['phone'] ?? 'N/A'}');
        print('Created: ${row['created_at'] ?? 'N/A'}');
        print('---');
      }
    }
    
    db.dispose();
  } catch (e) {
    print('❌ Error: $e');
  }
}
