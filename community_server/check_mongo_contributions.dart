import 'package:mongo_dart/mongo_dart.dart';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  // Read .env file manually
  String? mongoUri;
  try {
    final envContent = File('.env').readAsStringSync();
    for (final line in envContent.split('\n')) {
      if (line.startsWith('MONGODB_URI=')) {
        mongoUri = line.substring(12).trim();
        break;
      }
    }
  } catch (_) {}
  
  mongoUri = mongoUri ?? 'mongodb://localhost:27017/learnease';
  
  print('📡 Connecting to MongoDB: $mongoUri');
  
  Db? db;
  try {
    db = Db(mongoUri);
    await db.open();
    
    print('✅ Connected to MongoDB');
    
    final collection = db.collection('contributions');
    
    print('\n📋 All contributions in MongoDB:');
    final all = await collection.find().toList();
    print('Total documents: ${all.length}');
    
    for (int i = 0; i < all.length; i++) {
      print('\n--- Document $i ---');
      print('ID: ${all[i]['_id']}');
      print('Type: ${all[i]['type']}');
      print('Status: ${all[i]['status']}');
      print('Author: ${all[i]['authorName']}');
      print('Content field type: ${all[i]['content'].runtimeType}');
      print('Content: ${jsonEncode(all[i]['content'])}');
    }
    
    print('\n\n🔍 Approved contributions:');
    final approved = await collection.find({'status': 'approved'}).toList();
    print('Found ${approved.length} approved');
    
    for (final doc in approved) {
      print('\n✅ ${doc['type']} - ${doc['authorName']}');
      print('Content type: ${doc['content'].runtimeType}');
      final content = doc['content'];
      if (content is Map) {
        print('Content keys: ${(content).keys.toList()}');
      }
      print('Raw content: ${jsonEncode(content)}');
    }
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db?.close();
  }
}
