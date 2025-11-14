import 'package:mongo_dart/mongo_dart.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:io';

void main() async {
  final mongoUri = Platform.environment['MONGODB_URI'] ?? 
      'mongodb+srv://sathvik7137:S%40thvik2004@learnease.4dvte.mongodb.net/learnease?retryWrites=true&w=majority';
  
  print('🔍 Checking Admin User in MongoDB\n');
  
  try {
    print('🔌 Connecting to MongoDB...');
    final db = await Db.create(mongoUri);
    await db.open();
    print('✅ Connected!\n');
    
    final usersCollection = db.collection('users');
    
    // Find admin user
    print('📋 Looking for admin@learnease.com...');
    final admin = await usersCollection.findOne(where.eq('email', 'admin@learnease.com'));
    
    if (admin == null) {
      print('❌ PROBLEM: Admin user does NOT exist in MongoDB!');
      print('\n💡 Solution: You need to CREATE the admin user first.');
      print('   Run: dart run community_server/setup_admin_user.dart');
      await db.close();
      exit(1);
    }
    
    print('✅ Admin user found!\n');
    print('=' * 60);
    print('ADMIN USER DETAILS:');
    print('=' * 60);
    print('ID: ${admin['id']}');
    print('Email: ${admin['email']}');
    print('Username: ${admin['username']}');
    print('');
    
    // Check password_hash
    final passwordHash = admin['password_hash'] as String?;
    if (passwordHash == null) {
      print('❌ password_hash: MISSING (NULL)');
    } else {
      print('✅ password_hash: EXISTS (${passwordHash.length} chars)');
      print('   Starts with: ${passwordHash.substring(0, 10)}...');
      
      // Test password
      print('\n🧪 Testing password: "Admin@2024"');
      final matches = BCrypt.checkpw('Admin@2024', passwordHash);
      if (matches) {
        print('   ✅ Password "Admin@2024" MATCHES!');
      } else {
        print('   ❌ Password "Admin@2024" does NOT match');
        print('   💡 The password hash is set to something else');
      }
    }
    
    print('');
    
    // Check admin_passkey
    final passkeyHash = admin['admin_passkey'] as String?;
    if (passkeyHash == null) {
      print('❌ admin_passkey: MISSING (NULL)');
    } else {
      print('✅ admin_passkey: EXISTS (${passkeyHash.length} chars)');
      print('   Starts with: ${passkeyHash.substring(0, 10)}...');
      
      // Test passkey
      print('\n🧪 Testing passkey: "052026"');
      final matches = BCrypt.checkpw('052026', passkeyHash);
      if (matches) {
        print('   ✅ Passkey "052026" MATCHES!');
      } else {
        print('   ❌ Passkey "052026" does NOT match');
        print('   💡 The passkey hash is set to something else');
      }
    }
    
    print('\n' + '=' * 60);
    print('SUMMARY:');
    print('=' * 60);
    
    if (passwordHash != null && BCrypt.checkpw('Admin@2024', passwordHash)) {
      print('✅ Password is CORRECT: Admin@2024');
    } else if (passwordHash == null) {
      print('❌ Password is NOT SET');
    } else {
      print('❌ Password is WRONG (not Admin@2024)');
    }
    
    if (passkeyHash != null && BCrypt.checkpw('052026', passkeyHash)) {
      print('✅ Passkey is CORRECT: 052026');
    } else if (passkeyHash == null) {
      print('❌ Passkey is NOT SET');
    } else {
      print('❌ Passkey is WRONG (not 052026)');
    }
    
    print('=' * 60);
    
    // Offer to fix
    if (passwordHash == null || passkeyHash == null || 
        !BCrypt.checkpw('Admin@2024', passwordHash ?? '') ||
        !BCrypt.checkpw('052026', passkeyHash ?? '')) {
      print('\n💡 SOLUTION: Run the fix script to set correct credentials');
      print('   Command: dart run community_server/fix_admin_credentials.dart');
    }
    
    await db.close();
    print('\n✅ Done!');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
