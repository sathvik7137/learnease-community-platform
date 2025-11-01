import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  try {
    print('🗑️  Deleting all contributions from MongoDB...\n');
    
    final db = Db('mongodb://rayapureddyvardhan2004:4ArqM4OQHY1udO07@cluster0-shard-00-00.sufzx.mongodb.net:27017,cluster0-shard-00-01.sufzx.mongodb.net:27017,cluster0-shard-00-02.sufzx.mongodb.net:27017/learnease?ssl=true&replicaSet=Cluster0-shard-0&authSource=admin');
    
    await db.open();
    print('✅ Connected to MongoDB');
    
    final collection = db.collection('contributions');
    
    // Get count before
    final countBefore = await collection.count();
    print('Contributions before deletion: $countBefore');
    
    // Delete all contributions
    final result = await collection.deleteMany({});
    print('Deleted: ${result.nRemoved} documents');
    
    // Get count after
    final countAfter = await collection.count();
    print('Contributions after deletion: $countAfter');
    
    if (countAfter == 0) {
      print('\n✅ SUCCESS! All contributions have been deleted.');
    }
    
    await db.close();
  } catch (e) {
    print('❌ Error: $e');
  }
}
