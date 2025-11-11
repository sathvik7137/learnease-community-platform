import 'dart:io';
import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';

void main() {
  print('📤 Exporting users from SQLite to JSON...\n');
  
  try {
    // Open the SQLite database
    final db = sqlite3.open('users.db');
    print('✅ Opened users.db');
    
    // Export users
    final users = db.select('SELECT * FROM users');
    print('📊 Found ${users.length} users');
    
    // Export OTPs
    final otps = db.select('SELECT * FROM otps');
    print('📊 Found ${otps.length} OTPs');
    
    // Export sessions
    final sessions = db.select('SELECT * FROM sessions');
    print('📊 Found ${sessions.length} sessions');
    
    // Export email_otps
    final emailOtps = db.select('SELECT * FROM email_otps');
    print('📊 Found ${emailOtps.length} email OTPs');
    
    // Convert to JSON-friendly format
    final exportData = {
      'users': users.map((row) => {
        'id': row['id'],
        'email': row['email'],
        'password_hash': row['password_hash'],
        'phone': row['phone'],
        'google_id': row['google_id'],
        'created_at': row['created_at'],
        'username': row['username'],
      }).toList(),
      'otps': otps.map((row) => {
        'phone': row['phone'],
        'code': row['code'],
        'expires_at': row['expires_at'],
        'attempts': row['attempts'],
      }).toList(),
      'sessions': sessions.map((row) => {
        'id': row['id'],
        'user_id': row['user_id'],
      }).toList(),
      'email_otps': emailOtps.map((row) => {
        'email': row['email'],
        'code': row['code'],
        'expires_at': row['expires_at'],
        'attempts': row['attempts'],
      }).toList(),
      'exported_at': DateTime.now().toIso8601String(),
    };
    
    // Write to JSON file
    final jsonFile = File('users_export.json');
    jsonFile.writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(exportData)
    );
    
    print('\n✅ Exported to users_export.json');
    print('📝 Users: ${users.length}');
    print('📝 OTPs: ${otps.length}');
    print('📝 Sessions: ${sessions.length}');
    print('📝 Email OTPs: ${emailOtps.length}');
    
    db.dispose();
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
