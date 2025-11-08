import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

void main() {
  try {
    final db = sqlite3.open('users.db');
    print('🔧 Inserting sample contributions...\n');
    
    // Sample contributions data
    final contributions = [
      {
        'title': 'Introduction to Java Generics',
        'content': 'A comprehensive guide covering Java generics, wildcards, and bounded types.',
        'category': 'Java',
        'type': 'Tutorial',
        'authorEmail': 'test@example.com',
        'authorName': 'TestUser',
        'status': 'approved',
      },
      {
        'title': 'Advanced SQL Query Optimization',
        'content': 'Learn techniques to optimize your SQL queries for better database performance.',
        'category': 'DBMS',
        'type': 'Article',
        'authorEmail': 'test@example.com',
        'authorName': 'TestUser',
        'status': 'approved',
      },
      {
        'title': 'Java Collections Framework Deep Dive',
        'content': 'Explore lists, sets, maps, and queues in Java with practical examples.',
        'category': 'Java',
        'type': 'Video',
        'authorEmail': 'demo@example.com',
        'authorName': 'DemoUser',
        'status': 'approved',
      },
      {
        'title': 'NoSQL Databases vs Relational Databases',
        'content': 'Comparison of SQL and NoSQL databases with use cases.',
        'category': 'DBMS',
        'type': 'Article',
        'authorEmail': 'demo@example.com',
        'authorName': 'DemoUser',
        'status': 'approved',
      },
      {
        'title': 'Multi-threading in Java',
        'content': 'Complete guide to threads, synchronization, and concurrent programming.',
        'category': 'Java',
        'type': 'Tutorial',
        'authorEmail': 'test@example.com',
        'authorName': 'TestUser',
        'status': 'pending',
      },
    ];

    int inserted = 0;
    for (final contrib in contributions) {
      final id = const Uuid().v4();
      final now = DateTime.now().toIso8601String();
      
      try {
        db.execute(
          '''INSERT INTO contributions 
             (id, title, content, category, type, authorEmail, authorName, status, createdAt, updatedAt) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
          [
            id,
            contrib['title'],
            contrib['content'],
            contrib['category'],
            contrib['type'],
            contrib['authorEmail'],
            contrib['authorName'],
            contrib['status'],
            now,
            now,
          ],
        );
        inserted++;
        print('✅ ${contrib['title']} (${contrib['status']})');
      } catch (e) {
        print('⚠️  Error inserting ${contrib['title']}: $e');
      }
    }

    print('\n📊 Total inserted: $inserted contributions');
    print('✨ Sample data ready for testing!');
    
    db.dispose();
  } catch (e) {
    print('❌ Error: $e');
  }
}
