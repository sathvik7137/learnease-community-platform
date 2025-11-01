import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  print('Starting direct server-like database test...\n');
  
  // Simulate what the server does
  late final Database db;
  bool dbAvailable = true;
  
  try {
    db = sqlite3.open('users.db');
    print('✅ Database opened');
    dbAvailable = true;
  } catch (e) {
    print('❌ Database open failed: $e');
    dbAvailable = false;
    return;
  }
  
  // Test _dbGetUserByEmail function
  print('\nTesting _dbGetUserByEmail function...\n');
  
  String email = 'vardhangaming08@gmail.com';
  final normalizedEmail = email.trim().toLowerCase();
  print('Input email: "$email"');
  print('Normalized: "$normalizedEmail"');
  print('DB Available: $dbAvailable\n');
  
  // Execute the EXACT same query as the server
  print('Executing query: SELECT * FROM users WHERE LOWER(email) = LOWER(?)');
  print('With parameter: "$normalizedEmail"\n');
  
  final ResultSet rs = db.select(
    'SELECT * FROM users WHERE LOWER(email) = LOWER(?);', 
    [normalizedEmail]
  );
  
  print('Query result rows: ${rs.length}');
  
  if (rs.isEmpty) {
    print('❌ NO USER FOUND - This is the problem!');
  } else {
    print('✅ User found!');
    final row = rs.first;
    final user = {
      'id': row['id'] as String,
      'email': row['email'] as String?,
      'passwordHash': row['password_hash'] as String?,
      'phone': row['phone'] as String?,
      'googleId': row['google_id'] as String?,
      'createdAt': row['created_at'] as String?,
      'username': row['username'] as String?,
    };
    
    print('\nUser data:');
    print('  ID: ${user['id']}');
    print('  Email: ${user['email']}');
    print('  Hash exists: ${(user['passwordHash'] != null && (user['passwordHash'] as String).isNotEmpty)}');
    print('  Username: ${user['username']}');
    
    // Now test password verification
    print('\nPassword verification:');
    final password = 'Test123456';
    final storedHash = user['passwordHash'];
    
    if (storedHash == null || storedHash.isEmpty) {
      print('❌ No password hash found');
    } else {
      try {
        final pwdValid = BCrypt.checkpw(password, storedHash);
        print('  Password "$password": ${pwdValid ? "✅ VALID" : "❌ INVALID"}');
      } catch (e) {
        print('  ⚠️ BCrypt error: $e');
      }
    }
  }
  
  db.dispose();
}
