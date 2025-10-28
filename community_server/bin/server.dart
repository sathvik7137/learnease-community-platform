import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

// In-memory storage (replace with database in production)
List<Map<String, dynamic>> contributions = [];
int nextId = 1;

void main(List<String> args) async {
  final router = Router();

  // Real-time contributions stream (Server-Sent Events)
  router.get('/api/contributions/stream', (Request request) {
    final category = request.url.queryParameters['category'] ?? 'java';
    
    final controller = StreamController<String>();

    final timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final filtered = contributions
          .where((c) => c['category']?.toLowerCase() == category.toLowerCase())
          .toList();
      controller.add('data: ${jsonEncode(filtered)}\n\n');
    });

    controller.onCancel = () {
      timer.cancel();
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
    <p><strong>Total Contributions:</strong> ${contributions.length}</p>
    
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

  // Get all contributions
  router.get('/api/contributions', (Request request) {
    return Response.ok(
      jsonEncode(contributions),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Get contributions by category
  router.get('/api/contributions/<category>', (Request request, String category) {
    final filtered = contributions
        .where((c) => c['category']?.toLowerCase() == category.toLowerCase())
        .toList();
    return Response.ok(
      jsonEncode(filtered),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Add new contribution
  router.post('/api/contributions', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      
      // Add server-generated ID
      data['serverId'] = nextId++;
      data['serverCreatedAt'] = DateTime.now().toIso8601String();
      
      contributions.add(data);
      
      // Save to file for persistence
      await _saveToFile();
      
      return Response.ok(
        jsonEncode({'success': true, 'id': data['serverId']}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to add contribution: $e'}),
      );
    }
  });

  // Update contribution
  router.put('/api/contributions/<id>', (Request request, String id) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      
      final index = contributions.indexWhere(
        (c) => c['id'] == id || c['serverId'].toString() == id,
      );
      
      if (index == -1) {
        return Response.notFound(
          jsonEncode({'error': 'Contribution not found'}),
        );
      }
      
      // Update while preserving serverId and serverCreatedAt
      data['serverId'] = contributions[index]['serverId'];
      data['serverCreatedAt'] = contributions[index]['serverCreatedAt'];
      data['updatedAt'] = DateTime.now().toIso8601String();
      
      contributions[index] = data;
      await _saveToFile();
      
      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update contribution: $e'}),
      );
    }
  });

  // Delete contribution
  router.delete('/api/contributions/<id>', (Request request, String id) async {
    try {
      contributions.removeWhere(
        (c) => c['id'] == id || c['serverId'].toString() == id,
      );
      
      await _saveToFile();
      
      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete contribution: $e'}),
      );
    }
  });

  // CORS headers for web access - UPDATED for Cloudflare Tunnel
  final handler = Pipeline()
      .addMiddleware(corsHeaders(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
        'Access-Control-Expose-Headers': 'Content-Length, Content-Type',
        'Access-Control-Max-Age': '86400',
        'Access-Control-Allow-Credentials': 'false',
      }))
      .addMiddleware(logRequests())
      .addHandler(router);

  // Load existing contributions from file
  await _loadFromFile();

  // Start server
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('🚀 Community Server running on http://localhost:${server.port}');
  print('📝 Total contributions: ${contributions.length}');
}

// Save contributions to file
Future<void> _saveToFile() async {
  try {
    final file = File('contributions.json');
    await file.writeAsString(jsonEncode(contributions));
  } catch (e) {
    print('Warning: Could not save to file: $e');
  }
}

// Load contributions from file
Future<void> _loadFromFile() async {
  try {
    final file = File('contributions.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      final List<dynamic> data = jsonDecode(content);
      contributions = data.cast<Map<String, dynamic>>();
      
      // Find highest ID
      if (contributions.isNotEmpty) {
        nextId = contributions
            .map((c) => c['serverId'] as int? ?? 0)
            .reduce((a, b) => a > b ? a : b) + 1;
      }
      
      print('✅ Loaded ${contributions.length} contributions from file');
    }
  } catch (e) {
    print('Warning: Could not load from file: $e');
  }
}
