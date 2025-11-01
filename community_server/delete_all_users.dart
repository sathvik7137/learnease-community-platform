import 'package:sqlite3/sqlite3.dart';

void main() {
  try {
    final db = sqlite3.open('users.db');
    print('⚠️  Deleting all users from database...\n');
    
    // Get count before
    final beforeRows = db.select('SELECT COUNT(*) as count FROM users;');
    final countBefore = beforeRows.first['count'] as int;
    print('Users before deletion: $countBefore');
    
    // Delete all users
    db.execute('DELETE FROM users;');
    
    // Get count after
    final afterRows = db.select('SELECT COUNT(*) as count FROM users;');
    final countAfter = afterRows.first['count'] as int;
    print('Users after deletion: $countAfter');
    
    if (countAfter == 0) {
      print('\n✅ SUCCESS! All users have been deleted.');
      print('You can now register a new account with fresh credentials.');
    } else {
      print('\n❌ ERROR: Some users remain in the database');
    }
    
    db.dispose();
  } catch (e) {
    print('❌ Error: $e');
  }
}
