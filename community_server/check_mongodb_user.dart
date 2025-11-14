import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  try {
    // Read MongoDB URI from .env
    final envFile = File('.env');
    String? mongoUri;
    
    if (await envFile.exists()) {
      final lines = await envFile.readAsLines();
      for (final line in lines) {
        if (line.startsWith('MONGODB_URI=')) {
          mongoUri = line.substring('MONGODB_URI='.length).trim();
          break;
        }
      }
    }
    
    if (mongoUri == null) {
      print('❌ MONGODB_URI not found in .env file');
      exit(1);
    }
    
    print('🔌 Connecting to MongoDB...');
    final db = Db(mongoUri);
    await db.open();
    
    final usersCollection = db.collection('users');
    
    // Find the user
    final user = await usersCollection.findOne(where.eq('email', 'vardhangaming08@gmail.com'));
    
    if (user == null) {
      print('❌ User not found in MongoDB');
    } else {
      print('✅ User found in MongoDB:');
      print('   Email: ${user['email']}');
      print('   ID: ${user['id']}');
      print('   Username: ${user['username']}');
      print('   Password Hash: ${user['password_hash'] ?? 'NULL - NO PASSWORD SET'}');
      print('   Google ID: ${user['google_id'] ?? 'NULL'}');
      print('   Phone: ${user['phone'] ?? 'NULL'}');
      print('   Created At: ${user['created_at']}');
      print('');
      print('📋 Full document:');
      print(user);
    }
    
    await db.close();
    print('');
    print('✅ Check complete');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
