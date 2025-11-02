import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  final db = sqlite3.open('users.db');
  
  final result = db.select(
    'SELECT email, password_hash FROM users WHERE email = ?',
    ['rayapureddyvardhan2004@gmail.com']
  );
  
  if (result.isEmpty) {
    print('❌ User not found');
  } else {
    final row = result.first;
    final email = row['email'];
    final hash = row['password_hash'];
    
    print('📧 Email: $email');
    print('🔐 Stored Hash: $hash');
    print('\n🧪 Testing password: Rvav@2004');
    
    final isMatch = BCrypt.checkpw('Rvav@2004', hash);
    print('✅ Match Result: $isMatch');
    
    if (!isMatch) {
      print('\n⚠️  Password does NOT match!');
      print('🔄 Testing other possible passwords...');
      
      final testPasswords = ['Test123456', 'Rvav22004', 'Rvav@20004', 'rvav@2004'];
      for (final pwd in testPasswords) {
        final test = BCrypt.checkpw(pwd, hash);
        print('   ✓ "$pwd": $test');
      }
    }
  }
  
  db.dispose();
}
