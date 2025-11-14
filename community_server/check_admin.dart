import 'package:mongo_dart/mongo_dart.dart';
import 'dart:io';

void main() async {
  // Read from environment variable (Vardhan's MongoDB Atlas account)
  final mongoUri = Platform.environment['MONGODB_URI'];
  
  if (mongoUri == null) {
    print('❌ ERROR: MONGODB_URI environment variable not set!');
    print('💡 This should use Vardhan\'s MongoDB Atlas credentials');
    exit(1);
  }
  
  print('🔌 Connecting to MongoDB...');
  final db = await Db.create(mongoUri);
  await db.open();
  print('✅ Connected to MongoDB\n');
  
  final usersCollection = db.collection('users');
  
  print('📋 Looking for admin@learnease.com...\n');
  final admin = await usersCollection.findOne(where.eq('email', 'admin@learnease.com'));
  
  if (admin == null) {
    print('❌ Admin user not found!');
    await db.close();
    exit(1);
  }
  
  print('✅ Admin user found!');
  print('📄 Full document structure:\n');
  
  admin.forEach((key, value) {
    if (key == 'password_hash' || key == 'passwordHash' || key == 'admin_passkey' || key == 'adminPasskey') {
      print('  $key: ***hidden*** (${value != null ? "present" : "null"})');
    } else {
      print('  $key: $value');
    }
  });
  
  print('\n🔍 Checking specific fields:');
  print('  password_hash (snake_case): ${admin['password_hash'] != null ? "✅ EXISTS" : "❌ MISSING"}');
  print('  passwordHash (camelCase): ${admin['passwordHash'] != null ? "✅ EXISTS" : "❌ MISSING"}');
  print('  admin_passkey (snake_case): ${admin['admin_passkey'] != null ? "✅ EXISTS" : "❌ MISSING"}');
  print('  adminPasskey (camelCase): ${admin['adminPasskey'] != null ? "✅ EXISTS" : "❌ MISSING"}');
  
  await db.close();
  print('\n✅ Done!');
}
