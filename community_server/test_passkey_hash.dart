import 'package:bcrypt/bcrypt.dart';

void main() {
  const String passkey = '052026';
  final String hash = r'$2a$10$XzG0CgFj7qMryV1bF/icqOsDY5ZLWSAb0/wpIfo7sdr7aHX6NRo5K';
  
  print('Testing passkey verification:');
  print('Passkey: $passkey');
  print('Hash: $hash');
  
  try {
    final result = BCrypt.checkpw(passkey, hash);
    print('Result: $result');
    if (result) {
      print('✅ Passkey matches!');
    } else {
      print('❌ Passkey does NOT match!');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
  
  // Also try hashing a fresh one
  print('\nTesting fresh hash:');
  final freshHash = BCrypt.hashpw(passkey, BCrypt.gensalt());
  print('Fresh hash: $freshHash');
  final freshCheck = BCrypt.checkpw(passkey, freshHash);
  print('Fresh check: $freshCheck');
}
