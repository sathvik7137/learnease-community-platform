import 'package:bcrypt/bcrypt.dart';

void main() {
  const String passkey = '052026';
  final String hash = r'$2a$10$XzG0CgFj7qMryV1bF/icqOsDY5ZLWSAb0/wpIfo7sdr7aHX6NRo5K';
  
  print('Testing exact hash from database:');
  print('Passkey: $passkey');
  print('Hash: $hash');
  print('Hash length: ${hash.length}');
  
  try {
    final result = BCrypt.checkpw(passkey, hash);
    print('Result: $result');
    
    if (result) {
      print('✅ Hash is VALID for passkey "052026"');
    } else {
      print('❌ Hash does NOT match "052026"!');
      print('\nThe hash in the database is for a DIFFERENT passkey!');
      print('We need to regenerate the hash.');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
