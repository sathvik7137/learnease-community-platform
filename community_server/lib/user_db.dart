// User Database Abstraction Layer
// Provides a unified interface for user operations that works with both MongoDB and SQLite

import 'package:mongo_dart/mongo_dart.dart';
import 'package:sqlite3/sqlite3.dart';

class UserDb {
  final Database? sqliteDb;
  final DbCollection? mongoUsersCollection;
  final DbCollection? mongoSessionsCollection;
  final DbCollection? mongoOtpsCollection;
  final DbCollection? mongoEmailOtpsCollection;
  
  UserDb({
    this.sqliteDb,
    this.mongoUsersCollection,
    this.mongoSessionsCollection,
    this.mongoOtpsCollection,
    this.mongoEmailOtpsCollection,
  });
  
  // Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    // Try MongoDB first
    if (mongoUsersCollection != null) {
      final doc = await mongoUsersCollection!.findOne(where.eq('email', email));
      return doc;
    }
    
    // Fallback to SQLite
    if (sqliteDb != null) {
      final rs = sqliteDb!.select('SELECT * FROM users WHERE email = ?;', [email]);
      if (rs.isNotEmpty) {
        return rs.first;
      }
    }
    
    return null;
  }
  
  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(String id) async {
    // Try MongoDB first
    if (mongoUsersCollection != null) {
      final doc = await mongoUsersCollection!.findOne(where.eq('id', id));
      return doc;
    }
    
    // Fallback to SQLite
    if (sqliteDb != null) {
      final rs = sqliteDb!.select('SELECT * FROM users WHERE id = ?;', [id]);
      if (rs.isNotEmpty) {
        return rs.first;
      }
    }
    
    return null;
  }
  
  // Get user by phone
  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    // Try MongoDB first
    if (mongoUsersCollection != null) {
      final doc = await mongoUsersCollection!.findOne(where.eq('phone', phone));
      return doc;
    }
    
    // Fallback to SQLite
    if (sqliteDb != null) {
      final rs = sqliteDb!.select('SELECT * FROM users WHERE phone = ?;', [phone]);
      if (rs.isNotEmpty) {
        return rs.first;
      }
    }
    
    return null;
  }
  
  // Insert new user
  Future<void> insertUser(Map<String, dynamic> userData) async {
    // Insert to MongoDB
    if (mongoUsersCollection != null) {
      await mongoUsersCollection!.insert(userData);
    }
    
    // Also insert to SQLite for local development
    if (sqliteDb != null) {
      sqliteDb!.execute(
        'INSERT INTO users (id, email, password_hash, phone, google_id, created_at, username) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          userData['id'],
          userData['email'],
          userData['password_hash'],
          userData['phone'],
          userData['google_id'],
          userData['created_at'],
          userData['username'],
        ],
      );
    }
  }
  
  // Update user password
  Future<void> updateUserPassword(String userId, String newPasswordHash) async {
    // Update in MongoDB
    if (mongoUsersCollection != null) {
      await mongoUsersCollection!.updateOne(
        where.eq('id', userId),
        modify.set('password_hash', newPasswordHash),
      );
    }
    
    // Update in SQLite
    if (sqliteDb != null) {
      sqliteDb!.execute(
        'UPDATE users SET password_hash = ? WHERE id = ?',
        [newPasswordHash, userId],
      );
    }
  }
  
  // Update username
  Future<void> updateUsername(String userId, String newUsername) async {
    // Update in MongoDB
    if (mongoUsersCollection != null) {
      await mongoUsersCollection!.updateOne(
        where.eq('id', userId),
        modify.set('username', newUsername),
      );
    }
    
    // Update in SQLite
    if (sqliteDb != null) {
      sqliteDb!.execute(
        'UPDATE users SET username = ? WHERE id = ?',
        [newUsername, userId],
      );
    }
  }
  
  // Delete user
  Future<void> deleteUser(String userId) async {
    // Delete from MongoDB
    if (mongoUsersCollection != null) {
      await mongoUsersCollection!.remove(where.eq('id', userId));
    }
    
    // Delete from SQLite
    if (sqliteDb != null) {
      sqliteDb!.execute('DELETE FROM users WHERE id = ?', [userId]);
    }
  }
  
  // Get all users (admin function)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    // Try MongoDB first
    if (mongoUsersCollection != null) {
      final docs = await mongoUsersCollection!.find().toList();
      return docs;
    }
    
    // Fallback to SQLite
    if (sqliteDb != null) {
      final rs = sqliteDb!.select('SELECT id, email, phone, google_id, created_at, username FROM users;');
      return rs.toList();
    }
    
    return [];
  }
  
  // Count users
  Future<int> countUsers() async {
    // Try MongoDB first
    if (mongoUsersCollection != null) {
      return await mongoUsersCollection!.count();
    }
    
    // Fallback to SQLite
    if (sqliteDb != null) {
      final rs = sqliteDb!.select('SELECT COUNT(*) as count FROM users;');
      return rs.first['count'] as int;
    }
    
    return 0;
  }
  
  // Session operations
  Future<Map<String, dynamic>?> getSessionByRefreshToken(String refreshToken) async {
    // Try MongoDB first
    if (mongoSessionsCollection != null) {
      final doc = await mongoSessionsCollection!.findOne(where.eq('id', refreshToken));
      return doc;
    }
    
    // Fallback to SQLite
    if (sqliteDb != null) {
      final rs = sqliteDb!.select('SELECT * FROM sessions WHERE refresh_token = ?;', [refreshToken]);
      if (rs.isNotEmpty) {
        return rs.first;
      }
    }
    
    return null;
  }
  
  // Insert session
  Future<void> insertSession(Map<String, dynamic> sessionData) async {
    // Insert to MongoDB
    if (mongoSessionsCollection != null) {
      await mongoSessionsCollection!.insert(sessionData);
    }
    
    // Also insert to SQLite for local development
    if (sqliteDb != null) {
      sqliteDb!.execute(
        'INSERT INTO sessions (id, user_id) VALUES (?, ?)',
        [sessionData['id'], sessionData['user_id']],
      );
    }
  }
  
  // OTP operations
  Future<Map<String, dynamic>?> getOtpByEmail(String email) async {
    // Try MongoDB first
    if (mongoEmailOtpsCollection != null) {
      final doc = await mongoEmailOtpsCollection!.findOne(where.eq('email', email));
      return doc;
    }
    
    // Fallback to SQLite
    if (sqliteDb != null) {
      final rs = sqliteDb!.select('SELECT * FROM email_otps WHERE email = ?;', [email]);
      if (rs.isNotEmpty) {
        return rs.first;
      }
    }
    
    return null;
  }
  
  // Save or update email OTP
  Future<void> saveEmailOtp(String email, String code, String expiresAt) async {
    // Save to MongoDB
    if (mongoEmailOtpsCollection != null) {
      await mongoEmailOtpsCollection!.update(
        where.eq('email', email),
        {
          'email': email,
          'code': code,
          'expires_at': expiresAt,
          'attempts': 0,
        },
        upsert: true,
      );
    }
    
    // Save to SQLite
    if (sqliteDb != null) {
      sqliteDb!.execute(
        'INSERT OR REPLACE INTO email_otps (email, code, expires_at, attempts) VALUES (?, ?, ?, 0)',
        [email, code, expiresAt],
      );
    }
  }
  
  // Delete email OTP
  Future<void> deleteEmailOtp(String email) async {
    // Delete from MongoDB
    if (mongoEmailOtpsCollection != null) {
      await mongoEmailOtpsCollection!.remove(where.eq('email', email));
    }
    
    // Delete from SQLite
    if (sqliteDb != null) {
      sqliteDb!.execute('DELETE FROM email_otps WHERE email = ?', [email]);
    }
  }
}
