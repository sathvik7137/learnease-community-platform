import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

// Simple .env file reader
String? _readLocalEnv(String key, {String path = '.env'}) {
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
    
    final lines = file.readAsLinesSync();
    for (final line in lines) {
      if (line.trim().startsWith('#')) continue;
      if (line.contains('=')) {
        final parts = line.split('=');
        if (parts[0].trim() == key) {
          return parts.sublist(1).join('=').trim();
        }
      }
    }
  } catch (e) {
    // Ignore errors
  }
  return null;
}

void main() async {
  print('🔍 Testing MongoDB field names...\n');
  
  try {
    // Connect to MongoDB
    var mongoUri = Platform.environment['MONGODB_URI'];
    mongoUri ??= _readLocalEnv('MONGODB_URI', path: '.env');
    
    if (mongoUri == null || mongoUri.isEmpty) {
      print('❌ MONGODB_URI not found!');
      exit(1);
    }
    
    print('🔌 Connecting to MongoDB...');
    final db = await Db.create(mongoUri);
    await db.open();
    print('✅ Connected!\n');
    
    // Get users collection
    final usersCollection = db.collection('users');
    
    // Find one user
    print('📋 Fetching user: vardhangaming08@gmail.com');
    final user = await usersCollection.findOne(where.eq('email', 'vardhangaming08@gmail.com'));
    
    if (user == null) {
      print('❌ User not found!');
    } else {
      print('✅ User found!');
      print('\n📦 Raw MongoDB document:');
      print(user);
      
      print('\n🔑 Field names and values:');
      user.forEach((key, value) {
        final displayValue = key == 'password_hash' || key == 'passwordHash' 
            ? (value?.toString().substring(0, 30) ?? 'null') + '...'
            : value?.toString() ?? 'null';
        print('  $key: $displayValue');
      });
      
      print('\n🧪 Testing field access:');
      print('  user["password_hash"]: ${user["password_hash"] != null ? "EXISTS" : "NULL"}');
      print('  user["passwordHash"]: ${user["passwordHash"] != null ? "EXISTS" : "NULL"}');
      print('  user["google_id"]: ${user["google_id"] != null ? (user["google_id"] ?? "null") : "NULL"}');
      print('  user["googleId"]: ${user["googleId"] != null ? (user["googleId"] ?? "null") : "NULL"}');
    }
    
    await db.close();
    print('\n✅ Test complete!');
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
