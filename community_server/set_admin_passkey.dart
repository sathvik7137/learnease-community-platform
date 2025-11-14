import 'package:mongo_dart/mongo_dart.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:io';

/// This script sets a KNOWN passkey for admin@learnease.com
/// Run this on your LOCAL machine, it will update the PRODUCTION MongoDB
void main() async {
  // ⚠️ IMPORTANT: Set your desired passkey here
  final String newPasskey = '052026';  // User's actual passkey
  
  print('🔐 Setting Admin Passkey Tool\n');
  print('=' * 60);
  print('Email: admin@learnease.com');
  print('New Passkey: $newPasskey');
  print('=' * 60);
  print('');
  
  print('⚠️  WARNING: This will UPDATE the admin_passkey in PRODUCTION MongoDB!');
  print('Do you want to continue? (yes/no): ');
  
  final confirmation = stdin.readLineSync();
  if (confirmation?.toLowerCase() != 'yes' && confirmation?.toLowerCase() != 'y') {
    print('❌ Aborted');
    exit(0);
  }
  
  // Read from environment variable (Vardhan's MongoDB Atlas account)
  final mongoUri = Platform.environment['MONGODB_URI'];
  
  if (mongoUri == null) {
    print('❌ ERROR: MONGODB_URI environment variable not set!');
    print('💡 This should use Vardhan\'s MongoDB Atlas credentials');
    exit(1);
  }
  
  try {
    print('\n🔌 Connecting to MongoDB...');
    final db = await Db.create(mongoUri);
    await db.open();
    print('✅ Connected to MongoDB\n');
    
    final usersCollection = db.collection('users');
    
    // Find admin user
    print('📋 Looking for admin@learnease.com...');
    final admin = await usersCollection.findOne(where.eq('email', 'admin@learnease.com'));
    
    if (admin == null) {
      print('❌ Admin user NOT found in database!');
      print('\n💡 Create admin user first using setup_admin_user.dart');
      await db.close();
      exit(1);
    }
    
    print('✅ Admin user found!\n');
    
    // Hash the new passkey
    print('🔐 Hashing passkey with BCrypt...');
    final hashedPasskey = BCrypt.hashpw(newPasskey, BCrypt.gensalt());
    print('✅ Passkey hashed: ${hashedPasskey.substring(0, 20)}...\n');
    
    // Update the admin_passkey field
    print('💾 Updating admin_passkey in MongoDB...');
    final result = await usersCollection.updateOne(
      where.eq('email', 'admin@learnease.com'),
      modify.set('admin_passkey', hashedPasskey),
    );
    
    if (result.isSuccess) {
      print('✅ SUCCESS! Admin passkey updated!\n');
      print('=' * 60);
      print('CREDENTIALS TO USE:');
      print('=' * 60);
      print('Email: admin@learnease.com');
      print('Password: (your existing admin password)');
      print('Passkey: $newPasskey');
      print('=' * 60);
      print('');
      print('🎉 You can now login with these credentials!');
      print('   Go to Admin Access and use the passkey: $newPasskey');
    } else {
      print('❌ Update failed: ${result.writeError}');
    }
    
    await db.close();
    print('\n✅ Done!');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
