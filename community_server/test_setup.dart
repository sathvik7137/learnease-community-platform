import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  print('🔍 LearnEase Setup Diagnostic');
  print('=' * 50);
  
  // Check SQLite database
  print('\n📊 Checking SQLite Database...');
  try {
    final dbPath = 'users.db';
    final dbFile = File(dbPath);
    if (dbFile.existsSync()) {
      print('✅ users.db exists at: ${dbFile.absolute.path}');
      print('   Size: ${dbFile.lengthSync()} bytes');
      
      // Open and check tables
      final db = sqlite3.open(dbPath);
      print('\n   📋 Tables:');
      final tables = db.select("SELECT name FROM sqlite_master WHERE type='table';");
      for (final row in tables) {
        print('      - ${row['name']}');
      }
      
      // Check users
      print('\n   👥 Users in database:');
      try {
        final users = db.select('SELECT id, email, phone, created_at FROM users;');
        if (users.isEmpty) {
          print('      ⚠️  No users found in database');
        } else {
          for (int i = 0; i < users.length; i++) {
            final u = users[i];
            print('      $i. Email: ${u['email']}, Phone: ${u['phone']}, Created: ${u['created_at']}');
          }
        }
      } catch (e) {
        print('      ❌ Error querying users: $e');
      }
    } else {
      print('❌ users.db not found at: ${dbFile.absolute.path}');
    }
  } catch (e) {
    print('❌ SQLite error: $e');
  }
  
  // Check MongoDB connection capability
  print('\n🌐 Checking MongoDB Connection...');
  try {
    final mongoUp = Process.runSync('tasklist', ['/FI', 'IMAGENAME eq mongod.exe'], runInShell: true);
    if (mongoUp.stdout.toString().contains('mongod.exe')) {
      print('✅ MongoDB (mongod.exe) is currently running');
    } else {
      print('⚠️  MongoDB (mongod.exe) is NOT running');
      print('   To start MongoDB: mongod --dbpath "C:\\data\\db"');
    }
  } catch (e) {
    print('❌ Could not check MongoDB process: $e');
  }
  
  // Check environment variables
  print('\n🔐 Checking Environment...');
  final mongoUri = Platform.environment['MONGODB_URI'];
  if (mongoUri != null) {
    print('✅ MONGODB_URI set: ${mongoUri.replaceAll(RegExp(r':[^@]*@'), ':****@')}');
  } else {
    print('⚠️  MONGODB_URI not set (using default: mongodb://localhost:27017/learnease)');
  }
  
  final jwtSecret = Platform.environment['JWT_SECRET'];
  if (jwtSecret != null) {
    print('✅ JWT_SECRET set (${jwtSecret.length} chars)');
  } else {
    print('⚠️  JWT_SECRET not set (using dev secret)');
  }
  
  print('\n' + '=' * 50);
  print('🎯 Troubleshooting Steps:');
  print('1. Ensure mongod.exe is running (see above)');
  print('2. Check that users.db has data and correct structure');
  print('3. Verify email addresses are stored in lowercase');
  print('4. Restart server: dart run community_server/bin/server.dart');
}
