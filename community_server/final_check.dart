import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  final db = sqlite3.open('users.db');
  
  const testEmail = 'rayapureddyvardhan2004@gmail.com';
  const testPassword = 'Rvav@2004';
  
  print('🔍 Final Verification');
  print('=' * 60);
  
  final user = db.select(
    'SELECT email, password_hash FROM users WHERE email = ?',
    [testEmail]
  );
  
  if (user.isEmpty) {
    print('❌ User not found!');
  } else {
    final row = user.first;
    final email = row['email'];
    final hash = row['password_hash'];
    
    print('📧 Email found: $email');
    print('🔐 Hash: ${hash.toString().substring(0, 40)}...');
    print('\n🧪 Testing password...');
    
    final matches = BCrypt.checkpw(testPassword, hash);
    
    if (matches) {
      print('✅✅✅ PASSWORD MATCHES!');
      print('User is ready for login!');
    } else {
      print('❌ Password does NOT match');
    }
  }
  
  print('\n📊 All users in database:');
  final all = db.select('SELECT COUNT(*) as count FROM users;');
  print('Total users: ${all.first['count']}');
  
  db.dispose();
}
