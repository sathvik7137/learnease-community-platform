import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

String? _readEnv(String key) {
  try {
    final file = File('community_server/.env');
    if (!file.existsSync()) {
      return null;
    }
    final lines = file.readAsLinesSync();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx > 0) {
        final k = trimmed.substring(0, idx).trim();
        if (k == key) {
          return trimmed.substring(idx + 1).trim();
        }
      }
    }
  } catch (e) {
    print('⚠️ Error reading .env: $e');
  }
  return null;
}

void main() async {
  print('🚀 Starting contribution deletion...');
  final mongoUri = _readEnv('MONGODB_URI');
  
  if (mongoUri == null) {
    print('❌ MONGODB_URI not found in .env file');
    exit(1);
  }
  
  print('🗑️ Connecting to MongoDB...');
  print('📝 URI found, attempting connection...');
  
  Db? db;
  
  try {
    db = Db(mongoUri);
    print('⏳ Opening connection...');
    await db.open().timeout(Duration(seconds: 15));
    print('✅ Connected to MongoDB');
    
    final contribCollection = db.collection('contributions');
    
    // Get count before deletion
    final countBefore = await contribCollection.count();
    print('📊 Contributions before deletion: $countBefore');
    
    if (countBefore > 0) {
      // Delete all contributions
      final result = await contribCollection.deleteMany({});
      print('🗑️ Deleted ${result.nRemoved} contributions');
      
      // Verify deletion
      final countAfter = await contribCollection.count();
      print('✅ Contributions after deletion: $countAfter');
      
      if (countAfter == 0) {
        print('✅ All contributions have been successfully deleted!');
      }
    } else {
      print('ℹ️ No contributions to delete');
    }
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  } finally {
    if (db != null) {
      await db.close();
      print('✅ Database connection closed');
    }
  }
}
