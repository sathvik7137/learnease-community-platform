import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mongo_dart/mongo_dart.dart';

// In-memory storage (replace with database in production)
// MongoDB connection for contributions
Db? mongoDb;
DbCollection? contribCollection;
// Simple local env reader (can be used during startup)
String? _readLocalEnvTop(String key, {String? path}) {
  try {
    final filePath = path ?? '.env';
    final f = File(filePath);
    if (!f.existsSync()) return null;
    final lines = f.readAsLinesSync();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx <= 0) continue;
      final k = trimmed.substring(0, idx).trim();
      var v = trimmed.substring(idx + 1).trim();
      if (v.startsWith('"') && v.endsWith('"')) v = v.substring(1, v.length - 1);
      if (k == key) return v;
    }
  } catch (_) {}
  return null;
}

// Convert mongodb+srv URI to standard mongodb URI
String convertMongoDbSrvUri(String uri) {
  if (uri.startsWith('mongodb+srv://')) {
    // Convert mongodb+srv:// to mongodb+srv:// by keeping it as is
    // mongo_dart will handle it, but if not, we need to use a workaround
    // For now, let's try using it directly first
    return uri;
  }
  return uri;
}
// Simple JWT secret (override via .env in production)
final jwtSecret = Platform.environment['JWT_SECRET'] ?? _readLocalEnvTop('JWT_SECRET') ?? 'dev_secret_change_me';
final uuid = Uuid();

// SQLite database handle (users persist here)
late final Database db;
bool dbAvailable = true;
final List<Map<String, dynamic>> usersCache = [];
final List<Map<String, dynamic>> sessionsCache = [];

// Username uniqueness enforcement

void _initDb() {
  try {
    // Use absolute path to ensure database persists in the community_server directory
    // Get the directory where this script is running from
    final scriptDir = File(Platform.script.toFilePath()).parent.parent.path;
    final dbPath = '$scriptDir${Platform.pathSeparator}users.db';
    db = sqlite3.open(dbPath);
    
    print('📂 Database path: $dbPath');
    
    // Create tables if they don't exist
    db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        password_hash TEXT,
        phone TEXT UNIQUE,
        google_id TEXT,
        created_at TEXT,
        username TEXT
      );
      CREATE TABLE IF NOT EXISTS otps (
        phone TEXT PRIMARY KEY,
        code TEXT,
        expires_at TEXT,
        attempts INTEGER
      );
      CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        refresh_token TEXT UNIQUE,
        created_at TEXT,
        expires_at TEXT,
        revoked INTEGER DEFAULT 0
      );
      CREATE TABLE IF NOT EXISTS email_otps (
        email TEXT PRIMARY KEY,
        code TEXT,
        expires_at TEXT,
        attempts INTEGER,
        created_at TEXT
      );
    ''');
    
    // Add username column if it doesn't exist (migration)
    try {
      db.execute('ALTER TABLE users ADD COLUMN username TEXT;');
      print('✅ Added username column to existing users table');
    } catch (e) {
      // Column already exists, which is fine
      if (!e.toString().contains('duplicate column name')) {
        print('⚠️ Username column migration issue: $e');
      }
    }
    
    // Verify tables were created
    final tables = db.select("SELECT name FROM sqlite_master WHERE type='table';");
    print('✅ Database tables: ${tables.map((t) => t['name']).join(', ')}');
    print('✅ users.db opened and tables ensured');
    
    // Log existing users on startup
    final existingUsers = db.select('SELECT COUNT(*) as count FROM users;');
    print('📊 Existing users in database: ${existingUsers.first['count']}');
    
    dbAvailable = true;
  } catch (e) {
    // If native sqlite3 DLL is missing (common on some Windows setups), fall back to in-memory users cache
    dbAvailable = false;
    print('⚠️ SQLite initialization failed, falling back to in-memory users cache: $e');
  }
}

// Helper to issue JWTs with refresh token
Map<String, String> _issueTokens(String userId, String? email) {
  final accessJwt = JWT(
    {
      'sub': userId,
      'email': email,
      'iat': DateTime.now().millisecondsSinceEpoch,
      'type': 'access',
    },
  );
  final accessToken = accessJwt.sign(SecretKey(jwtSecret), expiresIn: const Duration(hours: 1));
  
  final refreshJwt = JWT(
    {
      'sub': userId,
      'iat': DateTime.now().millisecondsSinceEpoch,
      'type': 'refresh',
    },
  );
  final refreshToken = refreshJwt.sign(SecretKey(jwtSecret), expiresIn: const Duration(days: 30));
  
  // Store session in DB
  final sessionId = uuid.v4();
  final createdAt = DateTime.now().toIso8601String();
  final expiresAt = DateTime.now().add(const Duration(days: 30)).toIso8601String();
  _dbSaveSession(sessionId, userId, refreshToken, createdAt, expiresAt);
  
  return {'accessToken': accessToken, 'refreshToken': refreshToken};
}

// Helper to verify JWT and return user ID or null if invalid/expired
String? _verifyJWT(String token) {
  try {
    final jwt = JWT.verify(token, SecretKey(jwtSecret));
    final userId = jwt.payload['sub'] as String?;
    return userId;
  } catch (e) {
    print('❌ JWT verification failed: $e');
    return null;
  }
}

// Session DB helpers
void _dbSaveSession(String id, String userId, String refreshToken, String createdAt, String expiresAt) {
  if (!dbAvailable) {
    sessionsCache.add({'id': id, 'userId': userId, 'refreshToken': refreshToken, 'createdAt': createdAt, 'expiresAt': expiresAt, 'revoked': 0});
    return;
  }
  final stmt = db.prepare('INSERT INTO sessions (id, user_id, refresh_token, created_at, expires_at, revoked) VALUES (?, ?, ?, ?, ?, 0);');
  try {
    stmt.execute([id, userId, refreshToken, createdAt, expiresAt]);
  } finally {
    stmt.dispose();
  }
}

Map<String, dynamic>? _dbGetSessionByRefreshToken(String refreshToken) {
  if (!dbAvailable) {
    try {
      return sessionsCache.firstWhere((s) => s['refreshToken'] == refreshToken && (s['revoked'] as int) == 0);
    } catch (_) {
      return null;
    }
  }
  final rs = db.select('SELECT id, user_id, refresh_token, created_at, expires_at, revoked FROM sessions WHERE refresh_token = ? AND revoked = 0;', [refreshToken]);
  if (rs.isEmpty) return null;
  final r = rs.first;
  return {'id': r['id'], 'userId': r['user_id'], 'refreshToken': r['refresh_token'], 'createdAt': r['created_at'], 'expiresAt': r['expires_at'], 'revoked': r['revoked']};
}

void _dbRevokeSession(String refreshToken) {
  if (!dbAvailable) {
    final idx = sessionsCache.indexWhere((s) => s['refreshToken'] == refreshToken);
    if (idx != -1) sessionsCache[idx]['revoked'] = 1;
    return;
  }
  final stmt = db.prepare('UPDATE sessions SET revoked = 1 WHERE refresh_token = ?;');
  try {
    stmt.execute([refreshToken]);
  } finally {
    stmt.dispose();
  }
}

// User helpers (DB-backed)
Map<String, dynamic>? _dbGetUserByEmail(String email) {
  if (!dbAvailable) {
    try {
      return usersCache.firstWhere((u) => u['email'] == email);
    } catch (_) {
      return null;
    }
  }
  final ResultSet rs = db.select('SELECT * FROM users WHERE email = ?;', [email]);
  if (rs.isEmpty) return null;
  final row = rs.first;
  return {
    'id': row['id'] as String,
    'email': row['email'] as String?,
    'passwordHash': row['password_hash'] as String?,
    'phone': row['phone'] as String?,
    'googleId': row['google_id'] as String?,
    'createdAt': row['created_at'] as String?,
    'username': row['username'] as String?,
  };
}

Map<String, dynamic>? _dbGetUserByPhone(String phone) {
  if (!dbAvailable) {
    try {
      return usersCache.firstWhere((u) => u['phone'] == phone);
    } catch (_) {
      return null;
    }
  }
  final ResultSet rs = db.select('SELECT * FROM users WHERE phone = ?;', [phone]);
  if (rs.isEmpty) return null;
  final row = rs.first;
  return {
    'id': row['id'] as String,
    'email': row['email'] as String?,
    'passwordHash': row['password_hash'] as String?,
    'phone': row['phone'] as String?,
    'googleId': row['google_id'] as String?,
    'createdAt': row['created_at'] as String?,
    'username': row['username'] as String?,
  };
}

Map<String, dynamic>? _dbGetUserById(String id) {
  if (!dbAvailable) {
    try {
      return usersCache.firstWhere((u) => u['id'] == id);
    } catch (_) {
      return null;
    }
  }
  final ResultSet rs = db.select('SELECT * FROM users WHERE id = ?;', [id]);
  if (rs.isEmpty) return null;
  final row = rs.first;
  return {
    'id': row['id'] as String,
    'email': row['email'] as String?,
    'passwordHash': row['password_hash'] as String?,
    'phone': row['phone'] as String?,
    'googleId': row['google_id'] as String?,
    'createdAt': row['created_at'] as String?,
    'username': row['username'] as String?,
  };
}

void _dbInsertUser({required String id, String? email, String? passwordHash, String? phone, String? googleId, required String createdAt, String? username}) {
  if (!dbAvailable) {
    usersCache.add({'id': id, 'email': email, 'passwordHash': passwordHash, 'phone': phone, 'googleId': googleId, 'createdAt': createdAt, 'username': username});
    return;
  }
  final stmt = db.prepare('INSERT INTO users (id, email, password_hash, phone, google_id, created_at, username) VALUES (?, ?, ?, ?, ?, ?, ?);');
  try {
    stmt.execute([id, email, passwordHash, phone, googleId, createdAt, username]);
  } finally {
    stmt.dispose();
  }
}

void _dbUpdateGoogleId(String id, String googleId) {
  if (!dbAvailable) {
    final idx = usersCache.indexWhere((u) => u['id'] == id);
    if (idx != -1) usersCache[idx]['googleId'] = googleId;
    return;
  }
  final stmt = db.prepare('UPDATE users SET google_id = ? WHERE id = ?;');
  try {
    stmt.execute([googleId, id]);
  } finally {
    stmt.dispose();
  }
}
// OTP store: phone -> {code, expiresAt, attemptCount}
final Map<String, Map<String, dynamic>> otps = {};
// Email OTP store: email -> {code, expiresAt, attemptCount}
final Map<String, Map<String, dynamic>> emailOtps = {};

// OTP DB helpers
void _dbSaveOtp(String phone, String code, String expiresAt, int attempts) {
  if (!dbAvailable) {
    otps[phone] = {'code': code, 'expiresAt': expiresAt, 'attempts': attempts};
    return;
  }
  final stmt = db.prepare('INSERT OR REPLACE INTO otps (phone, code, expires_at, attempts) VALUES (?, ?, ?, ?);');
  try {
    stmt.execute([phone, code, expiresAt, attempts]);
  } finally {
    stmt.dispose();
  }
}

Map<String, dynamic>? _dbGetOtp(String phone) {
  if (!dbAvailable) return otps[phone];
  final rs = db.select('SELECT phone, code, expires_at, attempts FROM otps WHERE phone = ?;', [phone]);
  if (rs.isEmpty) return null;
  final r = rs.first;
  return {'phone': r['phone'], 'code': r['code'], 'expiresAt': r['expires_at'], 'attempts': r['attempts']};
}

void _dbDeleteOtp(String phone) {
  if (!dbAvailable) {
    otps.remove(phone);
    return;
  }
  final stmt = db.prepare('DELETE FROM otps WHERE phone = ?;');
  try {
    stmt.execute([phone]);
  } finally {
    stmt.dispose();
  }
}

// Email OTP helpers
void _dbSaveEmailOtp(String email, String code, String expiresAt, int attempts) {
  if (!dbAvailable) {
    emailOtps[email] = {'code': code, 'expiresAt': expiresAt, 'attempts': attempts};
    return;
  }
  final stmt = db.prepare('INSERT OR REPLACE INTO email_otps (email, code, expires_at, attempts, created_at) VALUES (?, ?, ?, ?, ?);');
  try {
    stmt.execute([email, code, expiresAt, attempts, DateTime.now().toIso8601String()]);
    print('💾 Email OTP saved to database: $email');
  } finally {
    stmt.dispose();
  }
}

Map<String, dynamic>? _dbGetEmailOtp(String email) {
  if (!dbAvailable) return emailOtps[email];
  final rs = db.select('SELECT email, code, expires_at, attempts FROM email_otps WHERE email = ?;', [email]);
  if (rs.isEmpty) return null;
  final r = rs.first;
  return {'email': r['email'], 'code': r['code'], 'expiresAt': r['expires_at'], 'attempts': r['attempts']};
}

void _dbDeleteEmailOtp(String email) {
  if (!dbAvailable) {
    emailOtps.remove(email);
    return;
  }
  final stmt = db.prepare('DELETE FROM email_otps WHERE email = ?;');
  try {
    stmt.execute([email]);
    print('🗑️ Email OTP deleted from database: $email');
  } finally {
    stmt.dispose();
  }
}

// Send email via SMTP (Gmail)
Future<bool> _sendEmail(String to, String subject, String body) async {
  print('[EMAIL] Attempting to send email to: $to');
  try {
    // Try environment variables first, then .env files in order
    var smtpUser = Platform.environment['SMTP_USER'];
    smtpUser ??= _readLocalEnvTop('SMTP_USER', path: 'community_server/.env');
    smtpUser ??= _readLocalEnvTop('SMTP_USER', path: '.env');
    
    var smtpPass = Platform.environment['SMTP_PASSWORD'];
    smtpPass ??= _readLocalEnvTop('SMTP_PASSWORD', path: 'community_server/.env');
    smtpPass ??= _readLocalEnvTop('SMTP_PASSWORD', path: '.env');
    
    print('[EMAIL] SMTP_USER: ' + (smtpUser ?? 'null'));
    print('[EMAIL] SMTP_PASSWORD: ' + (smtpPass != null ? '***hidden***' : 'null'));
    if (smtpUser == null || smtpPass == null) {
      print('⚠️ Email not configured (SMTP_USER or SMTP_PASSWORD missing). OTP: Check console.');
      return false;
    }
    
    // Retry logic for SMTP connection issues (Gmail SMTP can be flaky)
    int maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('[EMAIL] Attempt $attempt/$maxRetries to send email...');
        final smtpServer = gmail(smtpUser, smtpPass);
        final message = Message()
          ..from = Address(smtpUser, 'LearnEase')
          ..recipients.add(to)
          ..subject = subject
          ..html = body;
        
        await send(message, smtpServer).timeout(const Duration(seconds: 30));
        print('✅ Email sent successfully to $to (attempt $attempt)');
        return true;
      } on MailerException catch (e) {
        print('[EMAIL] ❌ Attempt $attempt failed (MailerException): ${e.toString()}');
        for (var p in e.problems) {
          print('[EMAIL]    Problem: ${p.code}: ${p.msg}');
        }
        
        if (attempt < maxRetries) {
          // Wait before retrying (exponential backoff: 3s, 6s)
          final delaySeconds = 3 * attempt;
          print('[EMAIL] Retrying in ${delaySeconds}s...');
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      } on TimeoutException catch (e) {
        print('[EMAIL] ❌ Attempt $attempt failed (Timeout): $e');
        if (attempt < maxRetries) {
          final delaySeconds = 3 * attempt;
          print('[EMAIL] Retrying in ${delaySeconds}s...');
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }
    }
    
    // All retries exhausted
    print('❌ Email send failed after $maxRetries attempts to $to');
    return false;
  } catch (e) {
    print('❌ Email configuration error: $e');
    return false;
  }
}
// Simple JWT secret (override via .env in production)
// duplicate declarations removed

void main(List<String> args) async {
  final router = Router();
  
  // Handle OPTIONS requests for CORS preflight
  router.options('/<path|.*>', (Request request) {
    return Response.ok('', headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
      'Access-Control-Max-Age': '86400',
    });
  });
  
  // Connect to MongoDB
  try {
    // Try to read from environment first, then from .env files (in order of priority)
    var mongoUri = Platform.environment['MONGODB_URI'];
    
    if (mongoUri == null) {
      // Try community_server/.env
      mongoUri = _readLocalEnvTop('MONGODB_URI', path: 'community_server/.env');
    }
    
    if (mongoUri == null) {
      // Try .env in current directory
      mongoUri = _readLocalEnvTop('MONGODB_URI', path: '.env');
    }
    
    if (mongoUri == null) {
      throw Exception('MONGODB_URI not found in environment or .env files');
    }
    
    print('🔌 Attempting to connect to MongoDB...');
    print('📝 Connection URI: ${mongoUri.replaceAll(RegExp(r':[^@]+@'), ':***@')}'); // Log URI with password masked
    mongoDb = Db(mongoUri);
    await mongoDb!.open().timeout(const Duration(seconds: 10));
    contribCollection = mongoDb?.collection('contributions');
    print('✅ MongoDB connected successfully');
  } catch (e) {
    print('⚠️ MongoDB connection failed: $e');
    print('⚠️ Contributions feature will be unavailable. Attempting to use local cache...');
    // Set mongoDb and contribCollection to null to indicate offline mode
    mongoDb = null;
    contribCollection = null;
  }

  // Real-time contributions stream (Server-Sent Events)
  router.get('/api/contributions/stream', (Request request) async {
    final category = request.url.queryParameters['category'] ?? 'java';
    final controller = StreamController<String>();
    Timer? timer;
    timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (contribCollection != null) {
        final filtered = await contribCollection?.find({'category': category}).toList() ?? [];
        controller.add('data: ${jsonEncode(filtered)}\n\n');
      } else {
        controller.add('data: []\n\n');
      }
    });
    controller.onCancel = () {
      timer?.cancel();
    };
    return Response.ok(
      controller.stream,
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    );
  });
  // Root endpoint - API documentation
  router.get('/', (Request request) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <title>LearnEase Community API</title>
  <style>
    body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; background: #f5f5f5; }
    .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    h1 { color: #2c3e50; }
    .endpoint { background: #ecf0f1; padding: 15px; margin: 10px 0; border-radius: 5px; }
    .method { display: inline-block; padding: 5px 10px; border-radius: 3px; font-weight: bold; color: white; }
    .get { background: #3498db; }
    .post { background: #2ecc71; }
    .put { background: #f39c12; }
    .delete { background: #e74c3c; }
    code { background: #34495e; color: #ecf0f1; padding: 2px 6px; border-radius: 3px; }
    .status { color: #27ae60; font-weight: bold; }
    a { color: #3498db; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🚀 LearnEase Community API</h1>
    <p class="status">✅ Server is running!</p>
  <!-- <p><strong>Total Contributions:</strong> ...</p> -->
    
    <h2>📚 Available Endpoints</h2>
    
    <div class="endpoint">
      <span class="method get">GET</span>
      <strong>/health</strong>
      <p>Check if the server is running</p>
      <a href="/health" target="_blank">Try it →</a>
    </div>
    
    <div class="endpoint">
      <span class="method get">GET</span>
      <strong>/api/contributions</strong>
      <p>Get all contributions</p>
      <a href="/api/contributions" target="_blank">Try it →</a>
    </div>
    
    <div class="endpoint">
      <span class="method get">GET</span>
      <strong>/api/contributions/{category}</strong>
      <p>Get contributions by category (java or dbms)</p>
      <a href="/api/contributions/java" target="_blank">Try Java →</a> | 
      <a href="/api/contributions/dbms" target="_blank">Try DBMS →</a>
    </div>
    
    <div class="endpoint">
      <span class="method post">POST</span>
      <strong>/api/contributions</strong>
      <p>Add a new contribution</p>
      <code>Content-Type: application/json</code>
    </div>
    
    <div class="endpoint">
      <span class="method put">PUT</span>
      <strong>/api/contributions/{id}</strong>
      <p>Update a contribution</p>
      <code>Content-Type: application/json</code>
    </div>
    
    <div class="endpoint">
      <span class="method delete">DELETE</span>
      <strong>/api/contributions/{id}</strong>
      <p>Delete a contribution</p>
    </div>
    
    <h2>📖 Quick Test</h2>
    <p>Try fetching contributions:</p>
    <pre style="background: #2c3e50; color: #ecf0f1; padding: 15px; border-radius: 5px; overflow-x: auto;">curl ${request.requestedUri.scheme}://${request.requestedUri.host}/api/contributions</pre>
    
    <hr style="margin: 30px 0; border: none; border-top: 1px solid #ecf0f1;">
    <p style="text-align: center; color: #7f8c8d;">
      <small>LearnEase Community Server | 
      <a href="https://github.com/yourusername/learnease" target="_blank">Documentation</a>
      </small>
    </p>
  </div>
</body>
</html>
    ''';
    return Response.ok(
      html,
      headers: {'Content-Type': 'text/html'},
    );
  });

  // Health check
  router.get('/health', (Request request) {
    return Response.ok('Community Server is running!');
  });

  // --- AUTH ROUTES ---
  // Register (email/password)
  router.post('/api/auth/register', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final email = (data['email'] as String?)?.trim().toLowerCase();
      final password = data['password'] as String?;
      final phone = (data['phone'] as String?)?.trim();
      final username = (data['username'] as String?)?.trim();
      
      if (email == null || password == null || email.isEmpty || password.length < 6) {
        return Response(400, body: jsonEncode({'error': 'Invalid email or password (min 6 chars)'}), headers: {'Content-Type': 'application/json'});
      }

      final existing = _dbGetUserByEmail(email);
      if (existing != null) {
        return Response(409, body: jsonEncode({'error': 'Email already registered'}), headers: {'Content-Type': 'application/json'});
      }

      final hash = BCrypt.hashpw(password, BCrypt.gensalt());
      final newId = uuid.v4();
      final createdAt = DateTime.now().toIso8601String();
      final defaultUsername = username ?? email.split('@')[0];
      _dbInsertUser(id: newId, email: email, passwordHash: hash, phone: phone, googleId: null, createdAt: createdAt, username: defaultUsername);
      final tokens = _issueTokens(newId, email);
      return Response.ok(jsonEncode({'token': tokens['accessToken'], 'refreshToken': tokens['refreshToken'], 'user': {'id': newId, 'email': email, 'phone': phone, 'username': defaultUsername}}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Login (email/password)
  router.post('/api/auth/login', (Request request) async {
    try {
      final body = await request.readAsString();
      print('🔐 [LOGIN] Raw body: $body');
      final data = jsonDecode(body) as Map<String, dynamic>;
      final email = (data['email'] as String?)?.trim().toLowerCase();
      final password = data['password'] as String?;
      print('🔐 [LOGIN] Parsed email: $email, password length: ${password?.length}');
      print('🔐 [LOGIN] Attempt for email: $email');
      if (email == null || password == null) {
        print('❌ [LOGIN] Missing credentials');
        return Response(400, body: jsonEncode({'error': 'Missing credentials'}), headers: {'Content-Type': 'application/json'});
      }

      final user = _dbGetUserByEmail(email);
      if (user == null) {
        print('❌ [LOGIN] User not found for email: $email');
        return Response(401, body: jsonEncode({'error': 'Invalid credentials'}), headers: {'Content-Type': 'application/json'});
      }
      print('✅ [LOGIN] User found: ${user['email']}');
      print('🔐 [LOGIN] User data: id=${user['id']}, email=${user['email']}, hasHash=${user['passwordHash'] != null}');
      
      final hash = user['passwordHash'] as String?;
      if (hash == null) {
        print('❌ [LOGIN] No password hash found for user');
        return Response(401, body: jsonEncode({'error': 'Invalid credentials'}), headers: {'Content-Type': 'application/json'});
      }
      
      print('🔐 [LOGIN] Checking password with hash: ${hash.substring(0, 20)}...');
      final ok = BCrypt.checkpw(password, hash);
      print('🔐 [LOGIN] BCrypt result: $ok');
      if (!ok) {
        print('❌ [LOGIN] Password check failed for $email');
        return Response(401, body: jsonEncode({'error': 'Invalid credentials'}), headers: {'Content-Type': 'application/json'});
      }
      print('✅ [LOGIN] Password verified for $email');
      
      final tokens = _issueTokens(user['id'] as String, email);
      print('✅ [LOGIN] Tokens issued for $email');
      return Response.ok(jsonEncode({'token': tokens['accessToken'], 'refreshToken': tokens['refreshToken'], 'user': {'id': user['id'], 'email': user['email'], 'phone': user['phone']}}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('❌ [LOGIN] Exception: $e');
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Send OTP to phone (placeholder - logs to console). In production plug Twilio or other SMS provider.
  router.post('/api/auth/send-otp', (Request request) async {
    try {
      final body = await request.readAsString();
    // Send OTP for registration (always sends, does NOT check if user exists)
    router.post('/api/auth/send-signup-otp', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final email = (data['email'] as String?)?.trim().toLowerCase();
        if (email == null || !email.contains('@')) {
          return Response(400, body: jsonEncode({'error': 'Invalid email'}), headers: {'Content-Type': 'application/json'});
        }
        final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 899999)).toString();
        final expires = DateTime.now().add(const Duration(minutes: 5));
        _dbSaveEmailOtp(email, code, expires.toIso8601String(), 0);
        print('[SIGNUP OTP] Email OTP saved for $email: $code (expires ${expires.toIso8601String()})');
        final subject = 'LearnEase Registration OTP';
        final body_text = 'Your LearnEase registration OTP is: $code\nValid for 5 minutes.';
        final sent = await _sendEmail(email, subject, body_text);
        print('[SIGNUP OTP] Email send result: ' + (sent ? 'SUCCESS' : 'FAILURE - using console fallback'));
        
        // Return success regardless of email send status (for development)
        // In production, you would want email to succeed
        return Response.ok(jsonEncode({'sent': true, 'code': code, 'message': sent ? 'Email sent' : 'Check console for OTP'}), headers: {'Content-Type': 'application/json'});
      } catch (e) {
        print('[SIGNUP OTP] Exception: $e');
        return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
      }
    });
      final data = jsonDecode(body) as Map<String, dynamic>;
      final phone = (data['phone'] as String?)?.trim();
      if (phone == null || phone.length < 6) return Response(400, body: jsonEncode({'error': 'Invalid phone'}), headers: {'Content-Type': 'application/json'});
      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 899999)).toString();
      final expires = DateTime.now().add(const Duration(minutes: 5));
      _dbSaveOtp(phone, code, expires.toIso8601String(), 0);
      print('✅ OTP saved for $phone: $code (expires ${expires.toIso8601String()})');
      
      var sentVia = 'console';
      
      // Try MSG91 first (Indian service - cheapest)
      final msg91Key = Platform.environment['MSG91_AUTH_KEY'] ?? _readLocalEnvTop('MSG91_AUTH_KEY');
      final msg91Route = Platform.environment['MSG91_ROUTE'] ?? _readLocalEnvTop('MSG91_ROUTE') ?? '4';
      
      if (msg91Key != null && msg91Key != 'YOUR_MSG91_AUTH_KEY_HERE') {
        try {
          final uri = Uri.parse('https://api.msg91.com/apiv5/flow/send').replace(queryParameters: {
            'authkey': msg91Key,
            'mobiles': phone,
            'message': 'Your LearnEase OTP is: $code. Valid for 5 minutes.',
            'route': msg91Route,
            'sender': 'LRNEASE',
          });
          final resp = await http.get(uri).timeout(const Duration(seconds: 10));
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            sentVia = 'msg91';
            print('📱 SMS sent via MSG91 to $phone');
          } else {
            print('❌ MSG91 send failed (${resp.statusCode}): ${resp.body}');
          }
        } catch (e) {
          print('❌ MSG91 exception: $e');
        }
      }
      
      // Fallback to Twilio if MSG91 not configured
      if (sentVia == 'console') {
        final twSid = Platform.environment['TWILIO_ACCOUNT_SID'] ?? _readLocalEnvTop('TWILIO_ACCOUNT_SID');
        final twToken = Platform.environment['TWILIO_AUTH_TOKEN'] ?? _readLocalEnvTop('TWILIO_AUTH_TOKEN');
        final twFrom = Platform.environment['TWILIO_FROM'] ?? _readLocalEnvTop('TWILIO_FROM');
        
        if (twSid != null && twToken != null && twFrom != null) {
          try {
            final uri = Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$twSid/Messages.json');
            final bodyMap = {'From': twFrom, 'To': phone, 'Body': 'Your LearnEase OTP is: $code'};
            final resp = await http.post(uri, headers: {
              'Authorization': 'Basic ' + base64Encode(utf8.encode('$twSid:$twToken'))
            }, body: bodyMap).timeout(const Duration(seconds: 10));
            if (resp.statusCode >= 200 && resp.statusCode < 300) {
              sentVia = 'twilio';
              print('📱 SMS sent via Twilio to $phone');
            } else {
              print('❌ Twilio send failed (${resp.statusCode}): ${resp.body}');
            }
          } catch (e) {
            print('❌ Twilio exception: $e');
          }
        }
      }
      
      if (sentVia == 'console') print('📋 OTP for $phone: $code (check terminal)');
      return Response.ok(jsonEncode({'sent': true}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Send OTP to email (for LOGIN - requires existing user)
  router.post('/api/auth/send-email-otp', (Request request) async {
    try {
      final body = await request.readAsString();
      print('[LOGIN OTP] Received send-email-otp request: ' + body);
      final data = jsonDecode(body) as Map<String, dynamic>;
      var email = (data['email'] as String?)?.trim().toLowerCase();
      final password = data['password'] as String?;
      
      print('[LOGIN OTP] Parsed email: "$email"');
      print('[LOGIN OTP] Password received: ${password != null ? "YES (length=${password.length})" : "NO"}');
      
      if (email == null || email.isEmpty) {
        print('[LOGIN OTP] ❌ Email is empty or null');
        return Response(400, body: jsonEncode({'error': 'Email is required'}), headers: {'Content-Type': 'application/json'});
      }
      
      if (!email.contains('@')) {
        print('[LOGIN OTP] ❌ Invalid email format: $email');
        return Response(400, body: jsonEncode({'error': 'Invalid email format'}), headers: {'Content-Type': 'application/json'});
      }
      
      // Ensure email is lowercase and trimmed
      email = email.trim().toLowerCase();
      print('[LOGIN OTP] Final email (normalized): "$email"');
      
      // Check if user exists before sending OTP (security fix)
      print('[LOGIN OTP] 🔍 Looking up user with email: "$email"');
      final user = _dbGetUserByEmail(email);
      if (user == null) {
        // Return error for non-existent email for login attempts
        print('[LOGIN OTP] ❌ Email not registered: $email');
        print('[LOGIN OTP] ❌ Checking all registered emails in database:');
        try {
          final allUsers = db.select('SELECT LOWER(email) as email FROM users;');
          for (final row in allUsers) {
            print('[LOGIN OTP]   • ${row['email']}');
          }
        } catch (e) {
          print('[LOGIN OTP]   Error listing users: $e');
        }
        return Response(401, body: jsonEncode({'error': 'Email not registered. Please sign up first.', 'sent': false}), headers: {'Content-Type': 'application/json'});
      }
      
      print('[LOGIN OTP] ✅ User found: email=${user['email']}, hasPassword=${user['passwordHash'] != null && (user['passwordHash'] as String).isNotEmpty}');
      print('[LOGIN OTP] 🔑 Password to verify: "$password" (length=${password?.length ?? 0})');
      
      // Validate password if provided (for login flow)
      if (password != null && password.isNotEmpty) {
        print('[LOGIN OTP] Validating password (length=${password.length})...');
        final storedHash = user['passwordHash'] as String?;
        
        if (storedHash == null || storedHash.isEmpty) {
          print('[LOGIN OTP] ❌ No password hash found for user - account may have been created via OAuth');
          return Response(401, body: jsonEncode({'error': 'This account does not have a password set. Please use social login or reset your password.', 'sent': false}), headers: {'Content-Type': 'application/json'});
        }
        
        // Verify password
        print('[LOGIN OTP] Testing BCrypt...');
        print('[LOGIN OTP] 🔐 Stored Hash: ${storedHash.substring(0, 30)}...');
        print('[LOGIN OTP] 🔑 Plain Password: "$password"');
        bool pwdValid = false;
        try {
          pwdValid = BCrypt.checkpw(password, storedHash);
        } catch (bcryptErr) {
          print('[LOGIN OTP] ❌ BCrypt error: $bcryptErr');
          print('[LOGIN OTP] ❌ BCrypt Stack: ${bcryptErr.runtimeType}');
          return Response(401, body: jsonEncode({'error': 'Password verification failed. Please try again.', 'sent': false}), headers: {'Content-Type': 'application/json'});
        }
        
        print('[LOGIN OTP] BCrypt result: $pwdValid');
        if (!pwdValid) {
          print('[LOGIN OTP] ❌ Invalid password for: $email');
          return Response(401, body: jsonEncode({'error': 'Incorrect password. Please try again.', 'sent': false}), headers: {'Content-Type': 'application/json'});
        }
        print('[LOGIN OTP] ✅ Password verified for: $email');
      }
      
      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 899999)).toString();
      final expires = DateTime.now().add(const Duration(minutes: 5));
      _dbSaveEmailOtp(email, code, expires.toIso8601String(), 0);
      print('[LOGIN OTP] ✅ Email OTP saved for $email: $code (expires ${expires.toIso8601String()})');
      
      final subject = 'LearnEase Login OTP';
      final body_text = 'Your LearnEase login OTP is: $code\nValid for 5 minutes.';
      final sent = await _sendEmail(email, subject, body_text);
      print('[LOGIN OTP] Email send result: ' + (sent ? 'SUCCESS' : 'FAILURE (dev mode - check console)'));
      
      // Always return success for OTP sending (in dev, console fallback is available)
      return Response.ok(jsonEncode({'sent': sent, 'code': code, 'message': sent ? 'OTP sent to your email' : 'Check console for OTP'}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[LOGIN OTP] ❌ Exception: $e');
      print('[LOGIN OTP] Stack: ${e.runtimeType}');
      return Response.internalServerError(body: jsonEncode({'error': 'Server error: ${e.toString()}'}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Send OTP to email (for SIGNUP - creates new user)
  router.post('/api/auth/send-signup-otp', (Request request) async {
    try {
      final body = await request.readAsString();
      print('[SIGNUP OTP] Received send-signup-otp request: ' + body);
      final data = jsonDecode(body) as Map<String, dynamic>;
      final email = (data['email'] as String?)?.trim().toLowerCase();
      if (email == null || !email.contains('@')) return Response(400, body: jsonEncode({'error': 'Invalid email'}), headers: {'Content-Type': 'application/json'});
      
      // Check if user already exists
      final user = _dbGetUserByEmail(email);
      if (user != null) {
        print('[SIGNUP OTP] ❌ Email already registered: $email');
        return Response(409, body: jsonEncode({'error': 'Email already registered', 'sent': false}), headers: {'Content-Type': 'application/json'});
      }
      
      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 899999)).toString();
      final expires = DateTime.now().add(const Duration(minutes: 5));
      _dbSaveEmailOtp(email, code, expires.toIso8601String(), 0);
      print('[SIGNUP OTP] Email OTP saved for $email: $code (expires ${expires.toIso8601String()})');
      
      final subject = 'LearnEase Signup OTP';
      final body_text = 'Your LearnEase signup OTP is: $code\nValid for 5 minutes.';
      final sent = await _sendEmail(email, subject, body_text);
      print('[SIGNUP OTP] Email send result: ' + (sent ? 'SUCCESS' : 'FAILURE'));
      return Response.ok(jsonEncode({'sent': sent}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[SIGNUP OTP] Exception: $e');
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Verify password reset OTP and set new password
  router.post('/api/auth/verify-reset-otp', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final email = (data['email'] as String?)?.trim().toLowerCase();
      final code = data['code'] as String?;
      final newPassword = data['newPassword'] as String?;
      print('[RESET OTP] Verify attempt: email=$email, code=$code');
      if (email == null || code == null || newPassword == null || newPassword.length < 6) {
        return Response(400, body: jsonEncode({'error': 'Missing or invalid fields'}), headers: {'Content-Type': 'application/json'});
      }
      final record = _dbGetEmailOtp(email);
      print('[RESET OTP] 🔍 Looking up OTP for "$email"');
      print('[RESET OTP] OTP record found: ${record != null ? '✅ YES' : '❌ NO'}');
      if (record != null) {
        print('[RESET OTP] 📋 Stored Code: ${record['code']}, Provided: $code');
      } else {
        print('[RESET OTP] ❌ NO OTP FOUND for email: "$email"');
        print('[RESET OTP] 🗂️ Available emails in emailOtps: ${emailOtps.keys.toList()}');
      }
      if (record == null) return Response(400, body: jsonEncode({'error': 'No OTP requested'}), headers: {'Content-Type': 'application/json'});
      final expires = DateTime.parse(record['expiresAt'] as String);
      if (DateTime.now().isAfter(expires)) {
        return Response(400, body: jsonEncode({'error': 'OTP expired'}), headers: {'Content-Type': 'application/json'});
      }
      if (record['code'] != code) {
        final attempts = (record['attempts'] as int? ?? 0) + 1;
        _dbSaveEmailOtp(email, record['code'] as String, record['expiresAt'] as String, attempts);
        return Response(401, body: jsonEncode({'error': 'Invalid code'}), headers: {'Content-Type': 'application/json'});
      }
      // OTP valid, update password
      final user = _dbGetUserByEmail(email);
      if (user == null) return Response(404, body: jsonEncode({'error': 'User not found'}), headers: {'Content-Type': 'application/json'});
      final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      final stmt = db.prepare('UPDATE users SET password_hash = ? WHERE id = ?;');
      try {
        stmt.execute([hash, user['id']]);
      } finally {
        stmt.dispose();
      }
      _dbDeleteEmailOtp(email);
      print('[RESET OTP] Password updated for $email');
      return Response.ok(jsonEncode({'success': true}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[RESET OTP] Exception: $e');
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Validate reset OTP without changing password (used before user enters new password)
  router.post('/api/auth/validate-reset-otp', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final email = (data['email'] as String?)?.trim().toLowerCase();
      final code = data['code'] as String?;
      print('[VALIDATE RESET OTP] Checking: email=$email, code=$code');
      
      if (email == null || code == null) {
        return Response(400, body: jsonEncode({'error': 'Missing email or code'}), headers: {'Content-Type': 'application/json'});
      }
      
      final record = _dbGetEmailOtp(email);
      print('[VALIDATE RESET OTP] 🔍 Looking up OTP for "$email"');
      if (record == null) {
        return Response(400, body: jsonEncode({'error': 'No OTP requested for this email'}), headers: {'Content-Type': 'application/json'});
      }
      
      // Check expiry
      final expires = DateTime.parse(record['expiresAt'] as String);
      if (DateTime.now().isAfter(expires)) {
        print('[VALIDATE RESET OTP] ⏰ OTP expired');
        return Response(400, body: jsonEncode({'error': 'OTP has expired'}), headers: {'Content-Type': 'application/json'});
      }
      
      // Check code match
      if (record['code'] != code) {
        print('[VALIDATE RESET OTP] ❌ Code mismatch. Expected: ${record['code']}, Got: $code');
        final attempts = (record['attempts'] as int? ?? 0) + 1;
        _dbSaveEmailOtp(email, record['code'] as String, record['expiresAt'] as String, attempts);
        return Response(401, body: jsonEncode({'error': 'Invalid OTP code'}), headers: {'Content-Type': 'application/json'});
      }
      
      print('[VALIDATE RESET OTP] ✅ OTP is valid');
      return Response.ok(jsonEncode({'valid': true}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[VALIDATE RESET OTP] Exception: $e');
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  router.post('/api/auth/verify-otp', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final phone = (data['phone'] as String?)?.trim();
      final code = data['code'] as String?;
      print('🔍 Verify OTP attempt: phone=$phone, code=$code');
      if (phone == null || code == null) return Response(400, body: jsonEncode({'error': 'Missing phone or code'}), headers: {'Content-Type': 'application/json'});
      final record = _dbGetOtp(phone);
      print('📋 OTP record found: ${record != null ? '✅ YES' : '❌ NO'}');
      if (record != null) print('   Stored OTP: ${record['code']}, Provided: $code');
      if (record == null) return Response(400, body: jsonEncode({'error': 'No OTP requested'}), headers: {'Content-Type': 'application/json'});
      final expires = DateTime.parse(record['expiresAt'] as String);
      if (DateTime.now().isAfter(expires)) {
        print('⏰ OTP expired');
        return Response(400, body: jsonEncode({'error': 'OTP expired'}), headers: {'Content-Type': 'application/json'});
      }
      if (record['code'] != code) {
        print('❌ OTP code mismatch');
        final attempts = (record['attempts'] as int? ?? 0) + 1;
        _dbSaveOtp(phone, record['code'] as String, record['expiresAt'] as String, attempts);
        return Response(401, body: jsonEncode({'error': 'Invalid code'}), headers: {'Content-Type': 'application/json'});
      }
      print('✅ OTP verified successfully');
      // OTP valid - find or create user by phone
      var user = _dbGetUserByPhone(phone);
      if (user == null) {
        final newId = uuid.v4();
        final createdAt = DateTime.now().toIso8601String();
        _dbInsertUser(id: newId, email: null, passwordHash: null, phone: phone, googleId: null, createdAt: createdAt);
        user = _dbGetUserById(newId);
        print('👤 New user created: $newId');
      }
      // consume OTP
      _dbDeleteOtp(phone);
      final found = user!;
      final tokens = _issueTokens(found['id'] as String, found['email'] as String?);
      return Response.ok(jsonEncode({'token': tokens['accessToken'], 'refreshToken': tokens['refreshToken'], 'user': {'id': found['id'], 'phone': found['phone'], 'email': found['email']}}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('❌ Error in verify-otp: $e');
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Verify email OTP for login or registration with password
  router.post('/api/auth/verify-email-otp', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final email = (data['email'] as String?)?.trim().toLowerCase();
      final code = data['code'] as String?;
      final password = data['password'] as String?;
      final username = (data['username'] as String?)?.trim();
      
      print('[EMAIL OTP] Verify attempt: email=$email, code=$code, hasPassword=${password != null}, username=$username');
      
      if (email == null || code == null) {
        return Response(400, body: jsonEncode({'error': 'Missing email or code'}), headers: {'Content-Type': 'application/json'});
      }
      
      // Check OTP
      final record = _dbGetEmailOtp(email);
      print('[EMAIL OTP] OTP record found: ${record != null ? '✅ YES' : '❌ NO'}');
      if (record != null) print('   Stored OTP: ${record['code']}, Provided: $code');
      
      if (record == null) {
        return Response(400, body: jsonEncode({'error': 'No OTP requested'}), headers: {'Content-Type': 'application/json'});
      }
      
      final expires = DateTime.parse(record['expiresAt'] as String);
      if (DateTime.now().isAfter(expires)) {
        print('[EMAIL OTP] ⏰ OTP expired');
        return Response(400, body: jsonEncode({'error': 'OTP expired'}), headers: {'Content-Type': 'application/json'});
      }
      
      final storedCode = record['code'] as String;
      print('[EMAIL OTP] 🔍 Code Comparison:');
      print('[EMAIL OTP]   Stored Type: ${storedCode.runtimeType}, Value: "$storedCode" (length=${storedCode.length})');
      print('[EMAIL OTP]   Provided Type: ${code.runtimeType}, Value: "$code" (length=${code.length})');
      print('[EMAIL OTP]   Match: ${storedCode == code}');
      
      if (storedCode != code) {
        print('[EMAIL OTP] ❌ OTP code mismatch: "$storedCode" != "$code"');
        final attempts = (record['attempts'] as int? ?? 0) + 1;
        _dbSaveEmailOtp(email, storedCode, record['expiresAt'] as String, attempts);
        return Response(401, body: jsonEncode({'error': 'Invalid OTP code'}), headers: {'Content-Type': 'application/json'});
      }
      
      print('[EMAIL OTP] ✅ OTP verified successfully');
      
      // Check if this is for login (user exists) or registration (user doesn't exist)
      var user = _dbGetUserByEmail(email);
      
      if (user != null) {
        // LOGIN: User exists, verify password
        if (password == null) {
          return Response(400, body: jsonEncode({'error': 'Password required for login'}), headers: {'Content-Type': 'application/json'});
        }
        
        final hash = user['passwordHash'] as String?;
        if (hash == null) {
          return Response(401, body: jsonEncode({'error': 'Account has no password set'}), headers: {'Content-Type': 'application/json'});
        }
        
        final passwordValid = BCrypt.checkpw(password, hash);
        if (!passwordValid) {
          return Response(401, body: jsonEncode({'error': 'Invalid password'}), headers: {'Content-Type': 'application/json'});
        }
        
        print('[EMAIL OTP] 🔐 Password verified for existing user');
        
      } else {
        // REGISTRATION: Create new user
        if (password == null || password.length < 6) {
          return Response(400, body: jsonEncode({'error': 'Password must be at least 6 characters'}), headers: {'Content-Type': 'application/json'});
        }
        
        final newId = uuid.v4();
        final createdAt = DateTime.now().toIso8601String();
        final hash = BCrypt.hashpw(password, BCrypt.gensalt());
        final defaultUsername = username ?? email.split('@')[0];
        
        _dbInsertUser(
          id: newId, 
          email: email, 
          passwordHash: hash, 
          phone: null, 
          googleId: null, 
          createdAt: createdAt,
          username: defaultUsername
        );
        
        user = _dbGetUserById(newId);
        print('[EMAIL OTP] 👤 New user created: $newId with username: $defaultUsername');
      }
      
      // Consume OTP
      _dbDeleteEmailOtp(email);
      
      // Issue tokens
      final found = user!;
      final tokens = _issueTokens(found['id'] as String, found['email'] as String?);
      
      return Response.ok(jsonEncode({
        'token': tokens['accessToken'], 
        'accessToken': tokens['accessToken'], 
        'refreshToken': tokens['refreshToken'], 
        'user': {
          'id': found['id'], 
          'email': found['email'], 
          'phone': found['phone']
        }
      }), headers: {'Content-Type': 'application/json'});
      
    } catch (e) {
      print('[EMAIL OTP] ❌ Error: $e');
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Google token verification (id_token) - verify with Google's tokeninfo endpoint
  router.post('/api/auth/google', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final idToken = data['idToken'] as String?;
      if (idToken == null) return Response(400, body: jsonEncode({'error': 'Missing idToken'}), headers: {'Content-Type': 'application/json'});
      final verifyUri = Uri.parse('https://oauth2.googleapis.com/tokeninfo?id_token=$idToken');
      final resp = await http.get(verifyUri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return Response(401, body: jsonEncode({'error': 'Invalid Google token', 'raw': resp.body}), headers: {'Content-Type': 'application/json'});
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      // decoded contains 'email', 'sub' (user id), 'email_verified'
      final email = (decoded['email'] as String?)?.toLowerCase();
      final googleId = decoded['sub'] as String?;
      if (email == null || googleId == null) return Response(400, body: jsonEncode({'error': 'Invalid token payload'}), headers: {'Content-Type': 'application/json'});
      // find or create user by email
      var user = _dbGetUserByEmail(email);
      if (user == null) {
        final newId = uuid.v4();
        final createdAt = DateTime.now().toIso8601String();
        _dbInsertUser(id: newId, email: email, passwordHash: null, phone: null, googleId: googleId, createdAt: createdAt);
        user = _dbGetUserById(newId);
      } else {
        // ensure google id is stored/updated
  final found = user;
  _dbUpdateGoogleId(found['id'] as String, googleId);
  user = _dbGetUserById(found['id'] as String);
      }
      final tokens = _issueTokens(user!['id'] as String, email);
      return Response.ok(jsonEncode({'token': tokens['accessToken'], 'refreshToken': tokens['refreshToken'], 'user': {'id': user['id'], 'email': user['email']}}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Refresh access token using refresh token
  router.post('/api/auth/refresh', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final refreshToken = data['refreshToken'] as String?;
      if (refreshToken == null) return Response(400, body: jsonEncode({'error': 'Missing refreshToken'}), headers: {'Content-Type': 'application/json'});
      
      final session = _dbGetSessionByRefreshToken(refreshToken);
      if (session == null) return Response(401, body: jsonEncode({'error': 'Invalid or revoked refresh token'}), headers: {'Content-Type': 'application/json'});
      
      final expiresAt = DateTime.parse(session['expiresAt'] as String);
      if (DateTime.now().isAfter(expiresAt)) return Response(401, body: jsonEncode({'error': 'Refresh token expired'}), headers: {'Content-Type': 'application/json'});
      
      final userId = session['userId'] as String;
      final user = _dbGetUserById(userId);
      if (user == null) return Response(401, body: jsonEncode({'error': 'User not found'}), headers: {'Content-Type': 'application/json'});
      
      // Issue new tokens and create new session
      final tokens = _issueTokens(userId, user['email'] as String?);
      return Response.ok(jsonEncode({'token': tokens['accessToken'], 'refreshToken': tokens['refreshToken']}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Revoke refresh token (logout)
  router.post('/api/auth/revoke', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final refreshToken = data['refreshToken'] as String?;
      if (refreshToken == null) return Response(400, body: jsonEncode({'error': 'Missing refreshToken'}), headers: {'Content-Type': 'application/json'});
      
      _dbRevokeSession(refreshToken);
      return Response.ok(jsonEncode({'success': true}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Get user profile
  router.get('/api/user/profile', (Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401, body: jsonEncode({'error': 'Authentication required'}), headers: {'Content-Type': 'application/json'});
      }
      final token = authHeader.substring(7);
      
      final userId = _verifyJWT(token);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Invalid or expired token'}), headers: {'Content-Type': 'application/json'});
      }
      
      final user = _dbGetUserById(userId);
      if (user == null) {
        return Response(404, body: jsonEncode({'error': 'User not found'}), headers: {'Content-Type': 'application/json'});
      }
      
      return Response.ok(jsonEncode({
        'email': user['email'],
        'username': user['username'] ?? '',
        'createdAt': user['createdAt'],
      }), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[PROFILE] Error: $e');
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Update user profile (username only for now)
  router.put('/api/user/profile', (Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401, body: jsonEncode({'error': 'Authentication required'}), headers: {'Content-Type': 'application/json'});
      }
      final token = authHeader.substring(7);
      
      final userId = _verifyJWT(token);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Invalid or expired token'}), headers: {'Content-Type': 'application/json'});
      }
      
      final body = await request.readAsString();
      print('[UPDATE PROFILE] Received update request: $body');
      final data = jsonDecode(body) as Map<String, dynamic>;
      final username = data['username'] as String?;
      
      if (username == null || username.trim().isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Username is required'}), headers: {'Content-Type': 'application/json'});
      }
      
      final trimmedUsername = username.trim();
      
      // Check if username is already taken by another user
      final existingUser = db.select('SELECT id FROM users WHERE username = ? AND id != ?', [trimmedUsername, userId]);
      if (existingUser.isNotEmpty) {
        return Response(400, body: jsonEncode({'error': 'Username is already taken'}), headers: {'Content-Type': 'application/json'});
      }
      
      // Update username
      db.execute('UPDATE users SET username = ? WHERE id = ?', [trimmedUsername, userId]);
      print('[UPDATE PROFILE] ✅ Updated username for user $userId to: $trimmedUsername');
      
      return Response.ok(jsonEncode({
        'success': true,
        'username': trimmedUsername
      }), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[UPDATE PROFILE] Error: $e');
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Dev-only: return list of users from DB for integration tests/debugging
  router.get('/internal/debug/users', (Request request) {
    final allow = (Platform.environment['DEV_ALLOW_DEBUG'] ?? _readLocalEnvTop('DEV_ALLOW_DEBUG') ?? '').toLowerCase();
    if (!(allow == '1' || allow == 'true' || allow == 'yes')) {
      return Response.forbidden(jsonEncode({'error': 'Debug endpoint disabled'}), headers: {'Content-Type': 'application/json'});
    }
    try {
      if (!dbAvailable) {
        return Response.ok(jsonEncode({'users': usersCache}), headers: {'Content-Type': 'application/json'});
      }
      final rows = db.select('SELECT id, email, phone, google_id, created_at FROM users;');
      final out = rows.map((r) => {
        'id': r['id'],
        'email': r['email'],
        'phone': r['phone'],
        'googleId': r['google_id'],
        'createdAt': r['created_at'],
      }).toList();
      return Response.ok(jsonEncode({'users': out}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Get all contributions
  router.get('/api/contributions', (Request request) async {
    if (contribCollection == null) {
      return Response.ok(
        jsonEncode([]),
        headers: {'Content-Type': 'application/json'},
      );
    }
    final all = await contribCollection?.find().toList() ?? [];
    return Response.ok(
      jsonEncode(all),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Get contributions by category
  router.get('/api/contributions/<category>', (Request request, String category) async {
    if (contribCollection == null) {
      return Response.ok(
        jsonEncode([]),
        headers: {'Content-Type': 'application/json'},
      );
    }
    final filtered = await contribCollection?.find({'category': category}).toList() ?? [];
    return Response.ok(
      jsonEncode(filtered),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Add new contribution (only for logged-in users)
  router.post('/api/contributions', (Request request) async {
    try {
      if (contribCollection == null) {
        return Response(503,
          body: jsonEncode({'error': 'MongoDB connection unavailable'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.forbidden(jsonEncode({'error': 'Authentication required'}), headers: {'Content-Type': 'application/json'});
      }
      final token = authHeader.substring(7);
      
      final userId = _verifyJWT(token);
      if (userId == null) {
        return Response.unauthorized(jsonEncode({'error': 'Invalid or expired token'}), headers: {'Content-Type': 'application/json'});
      }
      final user = _dbGetUserById(userId);
      if (user == null) {
        return Response.forbidden(jsonEncode({'error': 'User not found'}), headers: {'Content-Type': 'application/json'});
      }
      final username = user['username'] ?? 'Unknown';
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      data['serverCreatedAt'] = DateTime.now().toIso8601String();
      data['authorId'] = userId;
      data['authorUsername'] = username;
      final result = await contribCollection?.insertOne(data);
      return Response.ok(
        jsonEncode({'success': result?.isSuccess ?? false, 'id': result?.id?.toHexString()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to add contribution: $e'}),
      );
    }
  });

  // Update contribution (only owner can edit)
  router.put('/api/contributions/<id>', (Request request, String id) async {
    try {
      if (contribCollection == null) {
        return Response(503,
          body: jsonEncode({'error': 'MongoDB connection unavailable'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      print('🔵 PUT /api/contributions/$id received');
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        print('❌ Auth header missing or invalid');
        return Response.forbidden(jsonEncode({'error': 'Authentication required'}), headers: {'Content-Type': 'application/json'});
      }
      final token = authHeader.substring(7);
      
      final userId = _verifyJWT(token);
      if (userId == null) {
        print('❌ JWT verification failed');
        return Response.unauthorized(jsonEncode({'error': 'Invalid or expired token'}), headers: {'Content-Type': 'application/json'});
      }
      print('✅ User authenticated: $userId');
      
      // Parse the ObjectId
      ObjectId docId;
      try {
        docId = ObjectId.parse(id);
        print('✅ ObjectId parsed: $id');
      } catch (e) {
        print('❌ Failed to parse ObjectId: $id - $e');
        return Response.badRequest(body: jsonEncode({'error': 'Invalid document ID format: $e'}));
      }
      
      final doc = await contribCollection?.findOne({'_id': docId});
      if (doc == null) {
        print('❌ Document not found: $id');
        return Response.notFound(
          jsonEncode({'error': 'Contribution not found'}),
        );
      }
      print('✅ Document found');
      
      if (doc['authorId'] != userId) {
        print('❌ User is not the author. Doc author: ${doc['authorId']}, User: $userId');
        return Response.forbidden(jsonEncode({'error': 'You can only edit your own contributions'}), headers: {'Content-Type': 'application/json'});
      }
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      print('✅ Payload decoded, updating document...');
      
      // Preserve serverCreatedAt, authorId, authorUsername
      data['serverCreatedAt'] = doc['serverCreatedAt'];
      data['authorId'] = doc['authorId'];
      data['authorUsername'] = doc['authorUsername'];
      data['updatedAt'] = DateTime.now().toIso8601String();
      
      await contribCollection?.updateOne({'_id': docId}, {'\$set': data});
      print('✅ Document updated successfully');
      
      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Update error: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update contribution: $e'}),
      );
    }
  });

  // Delete contribution (only owner can delete)
  router.delete('/api/contributions/<id>', (Request request, String id) async {
    try {
      if (contribCollection == null) {
        return Response(503,
          body: jsonEncode({'error': 'MongoDB connection unavailable'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      print('🔵 DELETE /api/contributions/$id received');
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        print('❌ Auth header missing or invalid');
        return Response(401, body: jsonEncode({'error': 'Authentication required'}), headers: {'Content-Type': 'application/json'});
      }
      final token = authHeader.substring(7);
      
      // Verify JWT token
      final userId = _verifyJWT(token);
      if (userId == null) {
        print('❌ JWT verification failed');
        return Response(401, body: jsonEncode({'error': 'Invalid or expired token'}), headers: {'Content-Type': 'application/json'});
      }
      print('✅ User authenticated: $userId');
      
      // Parse the ObjectId
      ObjectId docId;
      try {
        docId = ObjectId.parse(id);
        print('✅ ObjectId parsed: $id');
      } catch (e) {
        print('❌ Failed to parse ObjectId: $id - $e');
        return Response.badRequest(body: jsonEncode({'error': 'Invalid document ID format: $e'}));
      }
      
      final doc = await contribCollection?.findOne({'_id': docId});
      if (doc == null) {
        print('❌ Document not found: $id');
        return Response.notFound(
          jsonEncode({'error': 'Contribution not found'}),
        );
      }
      print('✅ Document found');
      
      // Check authorization - try both authorId and authorUsername matching
      final docAuthorId = doc['authorId'] as String?;
      final docAuthorName = doc['authorName'] as String? ?? doc['authorUsername'] as String?;
      print('   Document authorId: $docAuthorId, authorName: $docAuthorName');
      print('   Current userId: $userId');
      
      // First, try to match by authorId (for new contributions)
      if (docAuthorId != null && docAuthorId == userId) {
        print('✅ Authorization check passed (ID match), deleting document...');
      } else if (docAuthorId != null && docAuthorId != userId) {
        // ID doesn't match, try username fallback
        print('⚠️ AuthorId mismatch, trying username match...');
        
        // Get current user to get their username
        if (!dbAvailable) {
          // Use cache if DB not available
          try {
            final currentUserData = usersCache.firstWhere((u) => u['id'] == userId);
            final currentUsername = currentUserData['username'] as String?;
            print('   Current user username (from cache): $currentUsername');
            
            if (docAuthorName != null && docAuthorName == currentUsername) {
              print('✅ Authorization check passed (username match), deleting document...');
            } else {
              print('❌ User is not the author. Doc author: $docAuthorName, User: $currentUsername');
              return Response.forbidden(jsonEncode({'error': 'You can only delete your own contributions'}), headers: {'Content-Type': 'application/json'});
            }
          } catch (_) {
            print('❌ Could not find current user in cache');
            return Response.forbidden(jsonEncode({'error': 'You can only delete your own contributions'}), headers: {'Content-Type': 'application/json'});
          }
        } else {
          // Try to get from database
          try {
            final userRows = db.select('SELECT username FROM users WHERE id = ?', [userId]);
            if (userRows.isEmpty) {
              print('❌ Current user not found in database');
              return Response.forbidden(jsonEncode({'error': 'You can only delete your own contributions'}), headers: {'Content-Type': 'application/json'});
            }
            final currentUsername = userRows.first['username'] as String?;
            print('   Current user username (from DB): $currentUsername');
            
            if (docAuthorName != null && docAuthorName == currentUsername) {
              print('✅ Authorization check passed (username match), deleting document...');
            } else {
              print('❌ User is not the author. Doc author: $docAuthorName, User: $currentUsername');
              return Response.forbidden(jsonEncode({'error': 'You can only delete your own contributions'}), headers: {'Content-Type': 'application/json'});
            }
          } catch (e) {
            print('❌ Error checking username: $e');
            return Response.forbidden(jsonEncode({'error': 'You can only delete your own contributions'}), headers: {'Content-Type': 'application/json'});
          }
        }
      } else {
        // No authorId but we have a name, check by name only
        print('⚠️ Document has no authorId, checking by username...');
        
        if (docAuthorName == null) {
          // Can't verify ownership at all
          print('⚠️ Document has no authorId and no authorName, allowing deletion based on JWT authentication');
        } else {
          // Get current user username and compare
          if (!dbAvailable) {
            try {
              final currentUserData = usersCache.firstWhere((u) => u['id'] == userId);
              final currentUsername = currentUserData['username'] as String?;
              if (docAuthorName != currentUsername) {
                print('❌ User is not the author. Doc author: $docAuthorName, User: $currentUsername');
                return Response.forbidden(jsonEncode({'error': 'You can only delete your own contributions'}), headers: {'Content-Type': 'application/json'});
              }
            } catch (_) {
              print('❌ Could not verify current user');
              return Response.forbidden(jsonEncode({'error': 'You can only delete your own contributions'}), headers: {'Content-Type': 'application/json'});
            }
          } else {
            try {
              final userRows = db.select('SELECT username FROM users WHERE id = ?', [userId]);
              if (userRows.isEmpty) {
                print('❌ Current user not found in database');
                return Response.forbidden(jsonEncode({'error': 'You can only delete your own contributions'}), headers: {'Content-Type': 'application/json'});
              }
              final currentUsername = userRows.first['username'] as String?;
              if (docAuthorName != currentUsername) {
                print('❌ User is not the author. Doc author: $docAuthorName, User: $currentUsername');
                return Response.forbidden(jsonEncode({'error': 'You can only delete your own contributions'}), headers: {'Content-Type': 'application/json'});
              }
            } catch (e) {
              print('❌ Error checking username: $e');
              return Response.forbidden(jsonEncode({'error': 'You can only delete your own contributions'}), headers: {'Content-Type': 'application/json'});
            }
          }
        }
      }
      
      print('✅ Authorization verified, proceeding with deletion...');
      
      await contribCollection?.deleteOne({'_id': docId});
      print('✅ Document deleted successfully');
      
      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Delete error: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete contribution: $e'}),
      );
    }
  });

  // CORS headers for web access - UPDATED for Flutter Web
  final handler = Pipeline()
      .addMiddleware(corsHeaders(headers: {
        'Access-Control-Allow-Origin': '*', // Allow all origins for development
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
        'Access-Control-Expose-Headers': 'Content-Length, Content-Type',
        'Access-Control-Max-Age': '86400',
        'Access-Control-Allow-Credentials': 'false', // Changed to false for broader compatibility
      }))
      .addMiddleware(logRequests())
      .addHandler((Request request) async {
        final response = await router(request);
        if (response.statusCode == 404) {
          return Response.notFound(
            jsonEncode({'error': 'Route not found'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        return response;
      });

  // Initialize DB for users
  _initDb();

  // AI proxy endpoint (Gemini-only). Server must set GEMINI_API_KEY in env or community_server/.env
  // Check in environment, then community_server/.env, then repo root ../.env for convenience
  final geminiKey = Platform.environment['GEMINI_API_KEY'] ??
  _readLocalEnvTop('GEMINI_API_KEY') ??
  _readLocalEnvTop('GEMINI_API_KEY', path: '../.env') ??
  _readLocalEnvTop('GOOGLE_API_KEY') ??
  _readLocalEnvTop('GOOGLE_API_KEY', path: '../.env');

  router.post('/api/ai', (Request request) async {
    try {
      final body = await request.readAsString();
      final Map<String, dynamic> data = body.isEmpty ? {} : jsonDecode(body);
      final model = (data['model'] as String?) ?? 'models/gemini-1';
      final input = (data['input'] as String?) ?? data['message'] as String? ?? '';

      if (input.isEmpty) {
        return Response(400, body: jsonEncode({'error': 'No input provided'}), headers: {'Content-Type': 'application/json'});
      }

      if (geminiKey == null || geminiKey.isEmpty) {
        return Response(502, body: jsonEncode({'error': 'GEMINI_API_KEY not configured on server'}), headers: {'Content-Type': 'application/json'});
      }

      // Add a small system instruction to keep replies focused on this project's domain.
      final systemPrompt =
          'You are an assistant for the LearnEase project. Answer only about topics relevant to this project (Java, DBMS, quizzes, code examples, contributions, Flutter integration, server API). Be concise and avoid unrelated content.';
      final payload = jsonEncode({
        'prompt': {
          'text': '$systemPrompt\nUser: $input'
        },
        'temperature': 0.2
      });

      // Helper to call Gemini for a given model string
      Future<http.Response> _callGemini(String m) async {
        final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta2/$m:generateText?key=$geminiKey');
        return await http.post(uri, headers: {'Content-Type': 'application/json'}, body: payload).timeout(const Duration(seconds: 30));
      }

      // Try the requested model first, then fallback to a short list of known models if we get NOT_FOUND.
  final envDefault = _readLocalEnvTop('AI_MODEL') ?? _readLocalEnvTop('AI_MODEL', path: '../.env');
  final List<String> tryModels = [model, envDefault, 'models/text-bison-001', 'models/chat-bison-001']
          .where((s) => s != null && s.trim().isNotEmpty)
          .map((s) => s!.trim())
          .toList();

      http.Response? resp;
      for (final tryModel in tryModels) {
        try {
          resp = await _callGemini(tryModel);
        } catch (e) {
          // network/timeout — continue to next
          resp = null;
        }
        if (resp == null) continue;
        if (resp.statusCode == 200) break; // success
        // If the model was not found, try next; for other errors, stop and surface it
        if (resp.statusCode == 404) {
          // try next model
          continue;
        } else {
          // some other error — stop trying
          break;
        }
      }

      if (resp == null) {
        // Gemini network/timeout — fall back to local responder
        final local = _localAnswer(input);
        return Response.ok(jsonEncode({'reply': local, 'provider': 'local', 'raw': {'error': 'Gemini network/timeout'}}), headers: {'Content-Type': 'application/json'});
      }

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        // Gemini failed — try Hugging Face inference as a fallback, otherwise return local responder
        try {
          final hfModel = Platform.environment['HF_MODEL'] ?? _readLocalEnvTop('HF_MODEL') ?? _readLocalEnvTop('HF_MODEL', path: '../.env') ?? 'google/flan-t5-small';
          final hfKey = Platform.environment['HF_API_KEY'] ?? _readLocalEnvTop('HF_API_KEY') ?? _readLocalEnvTop('HF_API_KEY', path: '../.env');
          final hfUri = Uri.parse('https://api-inference.huggingface.co/models/$hfModel');
          final hfHeaders = <String, String>{'Content-Type': 'application/json'};
          if (hfKey != null && hfKey.isNotEmpty) hfHeaders['Authorization'] = 'Bearer $hfKey';
          final hfBody = jsonEncode({'inputs': input, 'options': {'wait_for_model': true}});
          final hfResp = await http.post(hfUri, headers: hfHeaders, body: hfBody).timeout(const Duration(seconds: 30));
          if (hfResp.statusCode >= 200 && hfResp.statusCode < 300) {
            dynamic hfDecoded;
            try {
              hfDecoded = jsonDecode(hfResp.body);
            } catch (_) {
              hfDecoded = hfResp.body;
            }
            String hfReply = '';
            if (hfDecoded is List && hfDecoded.isNotEmpty) {
              final first = hfDecoded[0];
              if (first is Map && first['generated_text'] != null) hfReply = first['generated_text'].toString();
            }
            if (hfReply.isEmpty && hfDecoded is Map && hfDecoded['generated_text'] != null) hfReply = hfDecoded['generated_text'].toString();
            if (hfReply.isEmpty && hfDecoded is String) hfReply = hfDecoded;
            if (hfReply.isEmpty) hfReply = hfResp.body;
            return Response.ok(jsonEncode({'reply': hfReply, 'provider': 'huggingface', 'raw': hfDecoded}), headers: {'Content-Type': 'application/json'});
          }
        } catch (e) {
          // ignore
        }

        // Both Gemini and HF failed — return local responder output along with provider error
        final local = _localAnswer(input);
        return Response.ok(jsonEncode({'reply': local, 'provider': 'local', 'raw': {'gemini_status': resp.statusCode, 'gemini_body': resp.body}}), headers: {'Content-Type': 'application/json'});
      }

      final decoded = jsonDecode(resp.body);
      String reply = '';
      if (decoded is Map) {
        if (decoded['candidates'] is List && decoded['candidates'].isNotEmpty) {
          final cand = decoded['candidates'][0];
          if (cand is Map && cand['content'] != null) reply = cand['content'].toString();
        }
        if (reply.isEmpty && decoded['output'] is Map && decoded['output']['text'] != null) {
          reply = decoded['output']['text'].toString();
        }
      }
      if (reply.isEmpty) reply = resp.body;
      return Response.ok(jsonEncode({'reply': reply, 'provider': 'gemini', 'raw': decoded}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Send password reset OTP to email
  router.post('/api/auth/send-reset-otp', (Request request) async {
    try {
      final body = await request.readAsString();
      final logMsg = '[RESET OTP] Received send-reset-otp request: ' + body;
      print(logMsg);
      File('reset_otp_debug.log').writeAsStringSync(logMsg + '\n', mode: FileMode.append);
      final data = jsonDecode(body) as Map<String, dynamic>;
      final email = (data['email'] as String?)?.trim().toLowerCase();
      if (email == null || !email.contains('@')) return Response(400, body: jsonEncode({'error': 'Invalid email'}), headers: {'Content-Type': 'application/json'});
      
      final user = _dbGetUserByEmail(email);
      if (user == null) {
        // Return clear error for password reset when email not found
        File('reset_otp_debug.log').writeAsStringSync('[RESET OTP] Email not registered: $email\n', mode: FileMode.append);
        return Response(404, body: jsonEncode({'sent': false, 'error': 'No account found with this email address. Please check your email or create a new account.'}), headers: {'Content-Type': 'application/json'});
      }
      
      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 899999)).toString();
      final expires = DateTime.now().add(const Duration(minutes: 5));
      _dbSaveEmailOtp(email, code, expires.toIso8601String(), 0);
      File('reset_otp_debug.log').writeAsStringSync('[RESET OTP] OTP Saved: email=$email, code=$code\n', mode: FileMode.append);
      print('[RESET OTP] Email OTP saved for $email: $code (expires ${expires.toIso8601String()})');
      final subject = 'LearnEase Password Reset OTP';
      final body_text = 'Your LearnEase password reset OTP is: $code\nValid for 5 minutes.';
      final sent = await _sendEmail(email, subject, body_text);
      print('[RESET OTP] Email send result: ' + (sent ? 'SUCCESS' : 'FAILURE'));
      return Response.ok(jsonEncode({'sent': sent}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[RESET OTP] Exception: $e');
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  // Username uniqueness check endpoint
  router.get('/api/auth/check-username', (Request request) {
    final username = request.url.queryParameters['username']?.trim();
    if (username == null || username.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'Missing username'}), headers: {'Content-Type': 'application/json'});
    }
    // Check in users table (SQLite)
    bool taken = false;
    if (dbAvailable) {
      final rs = db.select('SELECT id FROM users WHERE username = ?;', [username]);
      taken = rs.isNotEmpty;
    } else {
      taken = usersCache.any((u) => u['username'] == username);
    }
    return Response.ok(jsonEncode({'taken': taken}), headers: {'Content-Type': 'application/json'});
  });

  // Email uniqueness check endpoint
  router.get('/api/auth/check-email', (Request request) {
    final email = request.url.queryParameters['email']?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'Missing email'}), headers: {'Content-Type': 'application/json'});
    }
    // Check in users table (SQLite)
    final user = _dbGetUserByEmail(email);
    return Response.ok(jsonEncode({'taken': user != null}), headers: {'Content-Type': 'application/json'});
  });

  // Start server
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('🚀 Community Server running on http://localhost:${server.port}');
}
// ...existing code...
// Send password reset OTP to email
// ...existing code...

// Local responder: simple keyword search over docs and contributions for offline replies
String _localAnswer(String input) {
  try {
    final docs = <String>[];
    // Add project documentation if present
    final docFile = File('../PROJECT_DOCUMENTATION.md');
    if (docFile.existsSync()) {
      docs.add(docFile.readAsStringSync());
    }
    final readme = File('../README.md');
    if (readme.existsSync()) docs.add(readme.readAsStringSync());

    // Add contributions content
    final contribFile = File('contributions.json');
    if (contribFile.existsSync()) {
      try {
        final raw = contribFile.readAsStringSync();
        final List<dynamic> arr = jsonDecode(raw);
        for (final item in arr) {
          try {
            if (item is Map && item['content'] != null) {
              final c = item['content'];
              if (c is Map) {
                if (c['title'] != null) docs.add(c['title'].toString());
                if (c['explanation'] != null) docs.add(c['explanation'].toString());
                if (c['codeSnippet'] != null) docs.add(c['codeSnippet'].toString());
              }
            }
          } catch (_) {}
        }
      } catch (_) {}
    }

    final corpus = docs.join('\n');
    if (corpus.trim().isEmpty) return 'Sorry, no local documentation is available to answer that right now.';

    // Simple keyword matching: pick sentences containing any input keywords
    final keywords = input
        .toLowerCase()
        .split(RegExp(r"\W+"))
        .where((s) => s.length > 2)
        .toSet()
        .toList();
    if (keywords.isEmpty) return 'Could you rephrase? I need a few keywords to search the docs.';

    // Break corpus into sentences and score by keyword matches
  final sentences = corpus.split(RegExp(r'(?<=[\.\?\!])\s+')).map((s) => s.trim()).where((s) => s.length>20).toList();
    final scored = <Map<String, dynamic>>[];
    for (final s in sentences) {
      final low = s.toLowerCase();
      var score = 0;
      for (final k in keywords) {
        if (low.contains(k)) score++;
      }
      if (score>0) scored.add({'s': s, 'score': score});
    }
    if (scored.isEmpty) return 'I could not find a direct match in the project docs; try asking about Java, DBMS, contributions, or the server API.';
    scored.sort((a,b)=> (b['score'] as int).compareTo(a['score'] as int));
    // Return top 2 sentences joined
    final top = scored.take(2).map((m) => m['s']).join(' ');
    return top;
  } catch (e) {
    return 'Local responder failed: ${e.toString()}';
  }
}
