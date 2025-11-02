import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  final db = sqlite3.open('users.db');
  
  final email = 'rayapureddyvardhan2004@gmail.com';
  const newPassword = 'Rvav@2004';
  
  // Hash the new password
  final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
  
  // Update in database
  db.execute('''
    UPDATE users 
    SET password_hash = ? 
    WHERE email = ?
  ''', [hash, email]);
  
  print('✅ Password reset for $email');
  print('🔑 Password: $newPassword');
  
  db.dispose();
}
