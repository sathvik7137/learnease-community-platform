import 'package:sqlite3/sqlite3.dart';

void main() {
  try {
    final db = sqlite3.open('users.db');
    
    print('📋 All emails in database (with metadata):');
    final rows = db.select('SELECT id, email, LOWER(email) as email_lower FROM users;');
    
    for (final row in rows) {
      final email = row['email'] as String?;
      final emailLower = row['email_lower'] as String?;
      final id = row['id'] as String?;
      print('   ID: $id');
      print('   Email: $email');
      print('   Lower: $emailLower');
      print('   Match with vardhangaming08@gmail.com: ${emailLower == "vardhangaming08@gmail.com"}');
      print('   ---');
    }
    
    db.dispose();
  } catch (e) {
    print('Error: $e');
  }
}
