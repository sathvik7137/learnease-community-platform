import 'dart:io';
import 'dart:convert';
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
  print('🔄 Importing users from SQLite export to MongoDB...\n');
  
  try {
    // Read the exported JSON file
    final jsonFile = File('users_export.json');
    if (!jsonFile.existsSync()) {
      print('❌ users_export.json not found!');
      print('   Run export_sqlite_users.dart first');
      exit(1);
    }
    
    final jsonContent = jsonFile.readAsStringSync();
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;
    
    final users = data['users'] as List;
    final sessions = data['sessions'] as List;
    final emailOtps = data['email_otps'] as List;
    
    print('📊 Found in export:');
    print('   Users: ${users.length}');
    print('   Sessions: ${sessions.length}');
    print('   Email OTPs: ${emailOtps.length}');
    print('');
    
    // Connect to MongoDB (reads from .env file)
    var mongoUri = Platform.environment['MONGODB_URI'];
    mongoUri ??= _readLocalEnv('MONGODB_URI', path: '.env');
    
    if (mongoUri == null || mongoUri.isEmpty) {
      print('❌ MONGODB_URI not found in environment or .env file!');
      print('   Make sure .env file exists with MONGODB_URI');
      exit(1);
    }
    
    print('🔌 Connecting to MongoDB...');
    final db = await Db.create(mongoUri);
    await db.open();
    print('✅ Connected to MongoDB\n');
    
    // Get collections
    final usersCollection = db.collection('users');
    final sessionsCollection = db.collection('sessions');
    final emailOtpsCollection = db.collection('email_otps');
    
    // Import users
    print('📤 Importing users...');
    int usersImported = 0;
    for (var user in users) {
      try {
        // Check if user already exists
        final existing = await usersCollection.findOne(where.eq('email', user['email']));
        if (existing != null) {
          print('   ⏭️  Skipped ${user['email']} (already exists)');
          continue;
        }
        
        await usersCollection.insert(user);
        print('   ✅ Imported ${user['email']} (${user['username']})');
        usersImported++;
      } catch (e) {
        print('   ❌ Failed to import ${user['email']}: $e');
      }
    }
    
    // Import sessions
    print('\n📤 Importing sessions...');
    int sessionsImported = 0;
    for (var session in sessions) {
      try {
        // Check if session already exists
        final existing = await sessionsCollection.findOne(where.eq('id', session['id']));
        if (existing != null) {
          continue; // Skip silently
        }
        
        await sessionsCollection.insert(session);
        sessionsImported++;
      } catch (e) {
        print('   ❌ Failed to import session: $e');
      }
    }
    print('   ✅ Imported $sessionsImported sessions');
    
    // Import email OTPs (these are probably expired, but for completeness)
    print('\n📤 Importing email OTPs...');
    int otpsImported = 0;
    for (var otp in emailOtps) {
      try {
        final existing = await emailOtpsCollection.findOne(where.eq('email', otp['email']));
        if (existing != null) {
          continue; // Skip silently
        }
        
        await emailOtpsCollection.insert(otp);
        otpsImported++;
      } catch (e) {
        print('   ❌ Failed to import OTP: $e');
      }
    }
    print('   ✅ Imported $otpsImported email OTPs');
    
    // Summary
    print('\n' + '='*50);
    print('✅ MIGRATION COMPLETE!');
    print('='*50);
    print('📊 Summary:');
    print('   Users imported: $usersImported / ${users.length}');
    print('   Sessions imported: $sessionsImported / ${sessions.length}');
    print('   Email OTPs imported: $otpsImported / ${emailOtps.length}');
    print('');
    
    // Verify
    final totalUsers = await usersCollection.count();
    final totalSessions = await sessionsCollection.count();
    final totalOtps = await emailOtpsCollection.count();
    
    print('📊 MongoDB now has:');
    print('   Total users: $totalUsers');
    print('   Total sessions: $totalSessions');
    print('   Total email OTPs: $totalOtps');
    
    await db.close();
    print('\n🎉 All done!');
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
