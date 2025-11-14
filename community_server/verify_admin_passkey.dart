import 'package:mongo_dart/mongo_dart.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:io';

void main() async {
  // Test passkey
  final testPasskey = 'admin1';  // Replace with your actual 6-character passkey
  
  print('🔐 Admin Passkey Verification Tool\n');
  print('Testing with passkey: $testPasskey\n');
  
  // Read from environment variable (Vardhan's MongoDB Atlas account)
  final mongoUri = Platform.environment['MONGODB_URI'];
  
  if (mongoUri == null) {
    print('❌ ERROR: MONGODB_URI environment variable not set!');
    print('💡 This should use Vardhan\'s MongoDB Atlas credentials');
    exit(1);
  }
  
  try {
    print('🔌 Connecting to MongoDB...');
    final db = await Db.create(mongoUri);
    await db.open();
    print('✅ Connected to MongoDB\n');
    
    final usersCollection = db.collection('users');
    
    print('📋 Looking for admin@learnease.com...\n');
    final admin = await usersCollection.findOne(where.eq('email', 'admin@learnease.com'));
    
    if (admin == null) {
      print('❌ Admin user NOT found in database!');
      print('\n💡 You need to create the admin user first.');
      await db.close();
      exit(1);
    }
    
    print('✅ Admin user found!\n');
    print('📄 User structure:');
    print('  ID: ${admin['id']}');
    print('  Email: ${admin['email']}');
    print('  Username: ${admin['username']}');
    print('  Password Hash: ${admin['password_hash'] != null ? "✅ EXISTS" : "❌ MISSING"}');
    print('  Admin Passkey Hash: ${admin['admin_passkey'] != null ? "✅ EXISTS" : "❌ MISSING"}');
    print('');
    
    // Check password_hash field
    final passwordHash = admin['password_hash'] as String?;
    if (passwordHash == null) {
      print('❌ PROBLEM: password_hash field is NULL');
      print('   The admin user needs a password set\n');
    } else {
      print('✅ password_hash field is present (${passwordHash.length} chars)');
    }
    
    // Check admin_passkey field
    final passkeyHash = admin['admin_passkey'] as String?;
    if (passkeyHash == null) {
      print('❌ PROBLEM: admin_passkey field is NULL');
      print('   The admin user needs a passkey set\n');
      print('💡 Setting passkey to: $testPasskey');
      
      // Hash the test passkey
      final hashedPasskey = BCrypt.hashpw(testPasskey, BCrypt.gensalt());
      
      // Update the user
      await usersCollection.updateOne(
        where.eq('email', 'admin@learnease.com'),
        modify.set('admin_passkey', hashedPasskey),
      );
      
      print('✅ Passkey set successfully!\n');
      print('🔑 Your admin passkey is now: $testPasskey');
      print('   Use this in the "Admin Passkey" field\n');
    } else {
      print('✅ admin_passkey field is present (${passkeyHash.length} chars)');
      print('');
      
      // Test if the provided passkey matches
      print('🧪 Testing passkey: $testPasskey');
      final matches = BCrypt.checkpw(testPasskey, passkeyHash);
      
      if (matches) {
        print('✅ SUCCESS! Passkey "$testPasskey" is CORRECT!');
        print('   Use this passkey to login\n');
      } else {
        print('❌ FAILED! Passkey "$testPasskey" does NOT match');
        print('   Try a different passkey or reset it\n');
        print('💡 Do you want to set a new passkey? (yes/no)');
        final response = stdin.readLineSync();
        
        if (response?.toLowerCase() == 'yes' || response?.toLowerCase() == 'y') {
          print('Enter new 6-character passkey:');
          final newPasskey = stdin.readLineSync();
          
          if (newPasskey != null && newPasskey.length >= 6) {
            final hashedPasskey = BCrypt.hashpw(newPasskey, BCrypt.gensalt());
            await usersCollection.updateOne(
              where.eq('email', 'admin@learnease.com'),
              modify.set('admin_passkey', hashedPasskey),
            );
            print('✅ Passkey updated to: $newPasskey\n');
          }
        }
      }
    }
    
    print('\n' + '=' * 60);
    print('SUMMARY:');
    print('=' * 60);
    print('Email: admin@learnease.com');
    print('Password Hash: ${passwordHash != null ? "✅ Set" : "❌ Missing"}');
    print('Admin Passkey: ${passkeyHash != null ? "✅ Set" : "❌ Missing"}');
    print('Passkey Match: ${passkeyHash != null ? (BCrypt.checkpw(testPasskey, passkeyHash) ? "✅ YES" : "❌ NO") : "❌ N/A"}');
    print('=' * 60);
    
    await db.close();
    print('\n✅ Done!');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
