  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:google_sign_in/google_sign_in.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  class AuthService {
  Future<Map<String, dynamic>> sendSignupOtp(String email) async {
    final uri = Uri.parse('$_base/api/auth/send-signup-otp');
    
    // Retry logic for SMTP connection issues
    int maxRetries = 3;
    Duration timeout = const Duration(seconds: 45); // Increased timeout for SMTP
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('[AuthService] Sending signup OTP (attempt $attempt/$maxRetries) to: $email');
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        ).timeout(timeout);
        
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (resp.statusCode != 200) {
          return {'error': data['error'] ?? 'Request failed', 'sent': false};
        }
        print('[AuthService] ✅ Signup OTP sent successfully');
        return data;
      } catch (e) {
        print('[AuthService] ❌ Attempt $attempt failed: $e');
        if (attempt < maxRetries) {
          final delaySeconds = 2 * attempt;
          print('[AuthService] Retrying in ${delaySeconds}s...');
          await Future.delayed(Duration(seconds: delaySeconds));
        } else {
          return {'error': 'Network error after $maxRetries attempts: $e'};
        }
      }
    }
    return {'error': 'Failed to send OTP after multiple attempts'};
  }
    final String _base = "http://localhost:8080";
    String? _pendingPassword;
    bool _isRefreshing = false;
    final List<void Function(String?)> _refreshCallbacks = [];

    Future<void> saveTokens(String accessToken, String refreshToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);
    }

    Future<void> saveToken(String token) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
    }

    Future<void> clearTokens() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    }

    Future<String?> getToken() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    }

    Future<String?> getRefreshToken() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('refresh_token');
    }

    Future<void> saveUserEmail(String email) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
    }

    Future<String?> getUserEmail() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_email');
    }

    Future<Map<String, dynamic>> sendResetOtp(String email) async {
      final uri = Uri.parse('$_base/api/auth/send-reset-otp');
      
      // Retry logic for SMTP connection issues
      int maxRetries = 3;
      Duration timeout = const Duration(seconds: 45);
      
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          print('[AuthService] Sending reset OTP (attempt $attempt/$maxRetries) to: $email');
          final resp = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          ).timeout(timeout);
          
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          if (resp.statusCode != 200) {
            return {'error': data['error'] ?? 'Request failed', 'sent': false};
          }
          print('[AuthService] ✅ Reset OTP sent successfully');
          return data;
        } catch (e) {
          print('[AuthService] ❌ Reset OTP attempt $attempt failed: $e');
          if (attempt < maxRetries) {
            final delaySeconds = 2 * attempt;
            print('[AuthService] Retrying in ${delaySeconds}s...');
            await Future.delayed(Duration(seconds: delaySeconds));
          } else {
            return {'error': 'Network error after $maxRetries attempts: $e'};
          }
        }
      }
      return {'error': 'Failed to send OTP after multiple attempts'};
    }

    Future<Map<String, dynamic>> verifyResetOtp(String email, String code, String newPassword) async {
      final uri = Uri.parse('$_base/api/auth/verify-reset-otp');
      try {
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}),
        ).timeout(const Duration(seconds: 10));
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (e) {
        return {'error': 'Network error: $e'};
      }
    }

    // Validate reset OTP without updating password (used before password entry)
    Future<Map<String, dynamic>> validateResetOtp(String email, String code) async {
      final uri = Uri.parse('$_base/api/auth/validate-reset-otp');
      try {
        print('[AuthService] Validating reset OTP for: $email, code: $code');
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'code': code}),
        ).timeout(const Duration(seconds: 10));
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        print('[AuthService] OTP validation response: ${resp.statusCode} - $data');
        if (resp.statusCode == 200) {
          return {'valid': true};
        } else {
          final error = data['error'] ?? 'OTP validation failed';
          return {'error': error, 'valid': false};
        }
      } catch (e) {
        print('[AuthService] OTP validation error: $e');
        return {'error': 'Network error: $e', 'valid': false};
      }
    }

    Future<Map<String, dynamic>> verifyEmailOtp(String email, String code, {String? password, String? username}) async {
      _pendingPassword = password;
      final uri = Uri.parse('$_base/api/auth/verify-email-otp');
      try {
        final bodyData = {
          'email': email, 
          'code': code, 
          'password': password
        };
        if (username != null) {
          bodyData['username'] = username;
        }
        
        print('[AuthService] Verifying email OTP:');
        print('[AuthService]   URI: $uri');
        print('[AuthService]   Email: $email');
        print('[AuthService]   Code: $code');
        print('[AuthService]   Has Password: ${password != null}');
        
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(bodyData),
        ).timeout(const Duration(seconds: 10));
        
        print('[AuthService] Response status: ${resp.statusCode}');
        print('[AuthService] Response body: ${resp.body.substring(0, 200)}');
        
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data.containsKey('token') && data.containsKey('refreshToken')) {
          await saveTokens(data['token'] as String, data['refreshToken'] as String);
          await saveUserEmail(email);  // Save email after successful login
          print('[AuthService] ✅ OTP verified, tokens saved');
        } else if (data.containsKey('accessToken') && data.containsKey('refreshToken')) {
          await saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
          await saveUserEmail(email);  // Save email after successful login
          print('[AuthService] ✅ OTP verified, tokens saved');
        } else if (data.containsKey('token')) {
          await saveToken(data['token'] as String);
          await saveUserEmail(email);  // Save email after successful login
          print('[AuthService] ✅ OTP verified, token saved');
        } else {
          print('[AuthService] ❌ No tokens in response');
        }
        return data;
      } catch (e) {
        print('[AuthService] ❌ Exception: $e');
        return {'error': 'Network error: $e'};
      }
    }

    Future<Map<String, dynamic>> signInWithGoogle() async {
      try {
        GoogleSignIn _googleSignIn;
        // Use correct clientId for web
        if (identical(0, 0.0)) {
          // Web
          _googleSignIn = GoogleSignIn(
            clientId: '988248324580-1u79snc9ajutnas9or3mpene2upk8k0a.apps.googleusercontent.com',
          );
        } else {
          // Mobile
          _googleSignIn = GoogleSignIn();
        }
        final account = await _googleSignIn.signIn();
        if (account == null) return {'error': 'cancelled'};
        final auth = await account.authentication;
        final idToken = auth.idToken;
        if (idToken == null) return {'error': 'No idToken returned'};
        final uri = Uri.parse('$_base/api/auth/google');
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'idToken': idToken}),
        );
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data.containsKey('accessToken') && data.containsKey('refreshToken')) {
          await saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
        } else if (data.containsKey('token')) {
          await saveToken(data['token'] as String);
        }
        return data;
      } catch (e) {
        return {'error': 'Google sign-in error: $e'};
      }
    }

    Future<Map<String, dynamic>> refreshAccessToken() async {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        return {'error': 'No refresh token available'};
      }
      try {
        final uri = Uri.parse('$_base/api/auth/refresh');
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          if (data.containsKey('accessToken') && data.containsKey('refreshToken')) {
            await saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
            return data;
          }
        }
        return {'error': 'Token refresh failed', 'statusCode': resp.statusCode};
      } catch (e) {
        return {'error': 'Token refresh error: $e'};
      }
    }

    Future<http.Response> authenticatedRequest(
      String method,
      String endpoint, {
      Map<String, dynamic>? body,
      Map<String, String>? additionalHeaders,
    }) async {
      final token = await getToken();
      if (token == null) {
        return http.Response(jsonEncode({'error': 'Not authenticated'}), 401);
      }
      final uri = Uri.parse('$_base$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        ...?additionalHeaders,
      };
      http.Response resp;
      switch (method.toUpperCase()) {
        case 'GET':
          resp = await http.get(uri, headers: headers);
          break;
        case 'POST':
          resp = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        case 'PUT':
          resp = await http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        case 'DELETE':
          resp = await http.delete(uri, headers: headers);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
      // If 401, try to refresh token and retry
      if (resp.statusCode == 401) {
        if (_isRefreshing) {
          final newToken = await _waitForTokenRefresh();
          if (newToken != null) {
            headers['Authorization'] = 'Bearer $newToken';
            switch (method.toUpperCase()) {
              case 'GET':
                resp = await http.get(uri, headers: headers);
                break;
              case 'POST':
                resp = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
                break;
              case 'PUT':
                resp = await http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
                break;
              case 'DELETE':
                resp = await http.delete(uri, headers: headers);
                break;
            }
          }
        } else {
          _isRefreshing = true;
          final refreshResult = await refreshAccessToken();
          _isRefreshing = false;
          if (refreshResult.containsKey('accessToken')) {
            final newToken = refreshResult['accessToken'] as String;
            for (final callback in _refreshCallbacks) {
              callback(newToken);
            }
            _refreshCallbacks.clear();
            headers['Authorization'] = 'Bearer $newToken';
            switch (method.toUpperCase()) {
              case 'GET':
                resp = await http.get(uri, headers: headers);
                break;
              case 'POST':
                resp = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
                break;
              case 'PUT':
                resp = await http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
                break;
              case 'DELETE':
                resp = await http.delete(uri, headers: headers);
                break;
            }
          } else {
            await clearTokens();
            _refreshCallbacks.clear();
          }
        }
      }
      return resp;
    }

    Future<String?> _waitForTokenRefresh() async {
      final completer = <String?>[];
      _refreshCallbacks.add((token) => completer.add(token));
      var attempts = 0;
      while (_isRefreshing && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (completer.isNotEmpty) {
        return completer.first;
      }
      return await getToken();
    }

    Future<Map<String, dynamic>> revokeToken() async {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        await clearTokens();
        return {'success': true};
      }
      try {
        final uri = Uri.parse('$_base/api/auth/revoke');
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );
        await clearTokens();
        if (resp.statusCode == 200) {
          return {'success': true};
        }
        return {'error': 'Token revocation failed', 'statusCode': resp.statusCode};
      } catch (e) {
        await clearTokens();
        return {'error': 'Token revocation error: $e'};
      }
    }

    Future<Map<String, dynamic>> register(String email, String password, {String? phone}) async {
      final uri = Uri.parse('$_base/api/auth/register');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'phone': phone}),
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data.containsKey('accessToken') && data.containsKey('refreshToken')) {
        await saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
      } else if (data.containsKey('token')) {
        await saveToken(data['token'] as String);
      }
      return data;
    }

    Future<Map<String, dynamic>> login(String email, String password) async {
      final uri = Uri.parse('$_base/api/auth/login');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data.containsKey('accessToken') && data.containsKey('refreshToken')) {
        await saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
      } else if (data.containsKey('token')) {
        await saveToken(data['token'] as String);
      }
      return data;
    }

    Future<Map<String, dynamic>> sendOtp(String phone) async {
      final uri = Uri.parse('$_base/api/auth/send-otp');
      try {
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        ).timeout(const Duration(seconds: 10));
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (e) {
        return {'error': 'Network error: $e'};
      }
    }

    Future<Map<String, dynamic>> sendEmailOtp(String email, {String? password}) async {
      final uri = Uri.parse('$_base/api/auth/send-email-otp');
      
      // Retry logic for SMTP connection issues
      int maxRetries = 3;
      Duration timeout = const Duration(seconds: 45); // Increased timeout for SMTP
      
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final bodyData = {'email': email};
          if (password != null) {
            bodyData['password'] = password;
          }
          
          print('[AuthService] Sending email OTP request (attempt $attempt/$maxRetries):');
          print('[AuthService]   URI: $uri');
          print('[AuthService]   Email: $email');
          print('[AuthService]   Has Password: ${password != null}');
          
          final resp = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bodyData),
          ).timeout(timeout);
          
          print('[AuthService] Response status: ${resp.statusCode}');
          print('[AuthService] Response body: ${resp.body}');
          
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          // If status code is not 200, treat it as an error
          if (resp.statusCode != 200) {
            print('[AuthService] ❌ Request failed with status ${resp.statusCode}');
            return {'error': data['error'] ?? 'Request failed', 'sent': false};
          }
          print('[AuthService] ✅ OTP sent successfully');
          return data;
        } catch (e) {
          print('[AuthService] ❌ Attempt $attempt failed: $e');
          
          if (attempt < maxRetries) {
            // Wait before retrying (exponential backoff: 2s, 4s)
            final delaySeconds = 2 * attempt;
            print('[AuthService] Retrying in ${delaySeconds}s...');
            await Future.delayed(Duration(seconds: delaySeconds));
          } else {
            // Final attempt failed
            return {'error': 'Network error after $maxRetries attempts: $e'};
          }
        }
      }
      
      return {'error': 'Failed to send OTP after multiple attempts'};
    }


    Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
      final uri = Uri.parse('$_base/api/auth/verify-otp');
      try {
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'code': code}),
        ).timeout(const Duration(seconds: 10));
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data.containsKey('token') && data.containsKey('refreshToken')) {
          await saveTokens(data['token'] as String, data['refreshToken'] as String);
        } else if (data.containsKey('accessToken') && data.containsKey('refreshToken')) {
          await saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
        } else if (data.containsKey('token')) {
          await saveToken(data['token'] as String);
        }
        return data;
      } catch (e) {
        return {'error': 'Network error: $e'};
      }
    }

    // Get user profile
    Future<Map<String, dynamic>> getUserProfile() async {
      final uri = Uri.parse('$_base/api/user/profile');
      try {
        final token = await getToken();
        if (token == null) {
          return {'error': 'Not authenticated'};
        }
        
        final resp = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));
        
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (resp.statusCode != 200) {
          return {'error': data['error'] ?? 'Request failed'};
        }
        return data;
      } catch (e) {
        return {'error': 'Network error: $e'};
      }
    }

    // Update user profile
    Future<Map<String, dynamic>> updateUserProfile({required String username}) async {
      final uri = Uri.parse('$_base/api/user/profile');
      try {
        final token = await getToken();
        if (token == null) {
          return {'error': 'Not authenticated'};
        }
        
        final resp = await http.put(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'username': username}),
        ).timeout(const Duration(seconds: 10));
        
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (resp.statusCode != 200) {
          return {'error': data['error'] ?? 'Request failed'};
        }
        return data;
      } catch (e) {
        return {'error': 'Network error: $e'};
      }
    }
  }

