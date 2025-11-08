import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/api_config.dart';

/// AIService (Gemini/proxy-only)
/// Client-side wrapper that posts user messages to a server-side AI proxy.
class AIService {
  final String provider; // always 'gemini' for this app
  final String baseUrl; // proxy base, e.g. http://localhost:8080/api/ai
  final String model; // e.g. 'models/gemini-1'
  final Duration timeout;

  AIService._(this.provider, this.baseUrl, this.model, this.timeout);

  factory AIService.fromEnv() {
    // Safe dotenv reads (dotenv may not be initialized on web builds)
    String safeEnv(String key, [String? fallback]) {
      try {
        final v = dotenv.env[key];
        if (v == null || v.trim().isEmpty) return fallback ?? '';
        return v.trim();
      } catch (_) {
        return fallback ?? '';
      }
    }

    final proxyBase = safeEnv('AI_PROXY_BASE', safeEnv('AI_API_BASE', '${ApiConfig.webBaseUrl}/api/ai'));
    final timeoutMs = int.tryParse(safeEnv('AI_TIMEOUT_MS', '15000')) ?? 15000;
    final model = safeEnv('AI_MODEL', 'models/gemini-1');

    return AIService._('gemini', proxyBase, model, Duration(milliseconds: timeoutMs));
  }

  /// Sends a single user message to the server proxy and returns the assistant reply as text.
  Future<String> sendMessage(String message) async {
    final uri = Uri.parse(baseUrl);
    final body = jsonEncode({'provider': provider, 'model': model, 'input': message});
    final headers = {'Content-Type': 'application/json'};

  final resp = await AuthService().authenticatedRequest(
      'POST',
      uri.path,
      body: {'provider': provider, 'model': model, 'input': message},
      additionalHeaders: headers,
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw http.ClientException('Proxy AI error: ${resp.statusCode} ${resp.body}');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is Map && decoded['reply'] != null) return decoded['reply'].toString();
    return resp.body;
  }
}
