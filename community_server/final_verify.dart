import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  final db = sqlite3.open('users.db');
  
  print('🔍 Credential Verification Report');
  print('=' * 80);
  print('📧 Email: rayapureddyvardhan2004@gmail.com');
  print('🔑 Password to verify: Rvav@2004');
  print('=' * 80);
  
  // Get the user
  final result = db.select(
    'SELECT email, password_hash FROM users WHERE email = ?',
    ['rayapureddyvardhan2004@gmail.com']
  );
  
  if (result.isEmpty) {
    print('❌ USER NOT FOUND IN DATABASE!');
  } else {
    final row = result.first;
    final email = row['email'];
    final hash = row['password_hash'];
    
    print('\n✅ User found in database');
    print('📧 Stored Email: $email');
    print('🔐 Hash: $hash');
    print('\n🧪 Password Verification:');
    
    final matches = BCrypt.checkpw('Rvav@2004', hash);
    print('   Match: $matches');
    
    if (matches) {
      print('\n✅✅✅ PASSWORD VERIFICATION SUCCESSFUL!');
      print('The password "Rvav@2004" correctly matches the stored BCrypt hash.');
      print('The database is correct and ready for login.');
    } else {
      print('\n❌ Password does NOT match!');
      print('Testing other passwords...');
      final tests = {
        'Test123456': BCrypt.checkpw('Test123456', hash),
        'Rvav22004': BCrypt.checkpw('Rvav22004', hash),
        'rvav@2004': BCrypt.checkpw('rvav@2004', hash),
      };
      tests.forEach((pwd, result) {
        print('   "$pwd": $result');
      });
    }
  }
  
  db.dispose();
}
