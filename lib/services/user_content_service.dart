import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/user_content.dart';
import 'dart:async';

class UserContentService {
  // Check email uniqueness via backend
  static Future<bool> isEmailTaken(String email) async {
    try {
      final url = Uri.parse('$_serverUrl/api/auth/check-email?email=$email');
      final response = await http.get(url).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['taken'] == true;
      }
    } catch (e) {
      print('Email check failed: $e');
    }
  // If check fails, assume not taken to avoid false positives
  return false;
  }
  // Check username uniqueness via backend
  static Future<bool> isUsernameTaken(String username) async {
    try {
      final url = Uri.parse('$_serverUrl/api/auth/check-username?username=$username');
      final response = await http.get(url).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['taken'] == true;
      }
    } catch (e) {
      print('Username check failed: $e');
    }
  // If check fails, assume not taken to avoid false positives
  return false;
  }
  static const String _contentKey = 'user_contributions';
  static const String _usernameKey = 'user_name';
  
  // Server URL - change this to your deployed server URL
  static const String _serverUrl = String.fromEnvironment(
    'SERVER_URL',
  defaultValue: 'http://localhost:8080',
  );
  static const Duration _timeout = Duration(seconds: 10);
  
  // Stream controller for real-time updates
  static final StreamController<List<UserContent>> _contributionsStreamController = 
      StreamController<List<UserContent>>.broadcast();
  
  static Stream<List<UserContent>> get contributionsStream => _contributionsStreamController.stream;
  
  // Get or set username
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }
  
  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username.trim());
  }
  
  // Get all user contributions (from server with local fallback)
  static Future<List<UserContent>> getAllContributions({bool forceRefresh = false}) async {
    try {
      // Try to fetch from server first
      final response = await AuthService().authenticatedRequest('GET', '/api/contributions');
      
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        final contributions = jsonList
            .map((json) => UserContent.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Cache locally for offline access
        await _cacheContributions(contributions);
        
        // Notify listeners of the updated list
        if (forceRefresh) {
          _contributionsStreamController.add(contributions);
        }
        
        return contributions;
      }
    } catch (e) {
      print('Server fetch failed: $e, falling back to local cache');
    }
    
    // Fallback to local cache
    return await _getLocalContributions();
  }
  
  // Get contributions from local cache
  static Future<List<UserContent>> _getLocalContributions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_contentKey);
    
    if (storedData == null || storedData.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(storedData) as List<dynamic>;
      return jsonList
          .map((json) => UserContent.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Cache contributions locally
  static Future<void> _cacheContributions(List<UserContent> contributions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = contributions.map((c) => c.toJson()).toList();
      await prefs.setString(_contentKey, jsonEncode(jsonList));
    } catch (e) {
      print('Failed to cache contributions: $e');
    }
  }
  
  // Get contributions by type
  static Future<List<UserContent>> getContributionsByType(ContentType type) async {
    final allContributions = await getAllContributions();
    return allContributions.where((c) => c.type == type).toList();
  }
  
  // Get contributions by category (Java or DBMS)
  static Future<List<UserContent>> getContributionsByCategory(CourseCategory category) async {
    final allContributions = await getAllContributions();
    return allContributions.where((c) => c.category == category).toList();
  }
  
  // Get contributions by both type and category
  static Future<List<UserContent>> getContributionsByTypeAndCategory(
    ContentType type,
    CourseCategory category,
  ) async {
    final allContributions = await getAllContributions();
    return allContributions
        .where((c) => c.type == type && c.category == category)
        .toList();
  }

  // Get contributions with optional filters
  static Future<List<UserContent>> getContributions({
    CourseCategory? category,
    ContentType? type,
  }) async {
    final allContributions = await getAllContributions();
    
    return allContributions.where((c) {
      final matchCategory = category == null || c.category == category;
      final matchType = type == null || c.type == type;
      return matchCategory && matchType;
    }).toList();
  }
  
  // Start listening to real-time updates via polling (SSE alternative for web)
  static Timer? _pollingTimer;
  
  static void startRealtimeUpdates() {
    // Poll every 3 seconds for updates
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final contributions = await getAllContributions();
        _contributionsStreamController.add(contributions);
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }
  
  static void stopRealtimeUpdates() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
  
  // Add new contribution (to server with local fallback)
  static Future<bool> addContribution(UserContent content) async {
    try {
      // Try to add to server
      final url = Uri.parse('$_serverUrl/api/contributions');
  final response = await AuthService().authenticatedRequest(
        'POST',
        '/api/contributions',
        body: content.toJson(),
      );
      
      if (response.statusCode == 200) {
        // Success - refresh local cache
        await getAllContributions();
        return true;
      }
    } catch (e) {
      print('Server add failed: $e, saving locally');
    }
    
    // Fallback to local storage
    try {
      final allContributions = await _getLocalContributions();
      allContributions.add(content);
      await _cacheContributions(allContributions);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Batch add multiple contributions
  static Future<Map<String, dynamic>> batchAddContributions(List<UserContent> contents) async {
    int successCount = 0;
    int failureCount = 0;
    final List<String> errors = [];

    for (final content in contents) {
      try {
        final success = await addContribution(content);
        if (success) {
          successCount++;
        } else {
          failureCount++;
          errors.add('Failed to add contribution');
        }
      } catch (e) {
        failureCount++;
        errors.add('Error adding contribution: $e');
      }
    }

    return {
      'successCount': successCount,
      'failureCount': failureCount,
      'errors': errors,
    };
  }
  
  // Update existing contribution (on server with local fallback)
  static Future<bool> updateContribution(String id, UserContent updatedContent) async {
    try {
      // Try to update on server
      final response = await AuthService().authenticatedRequest(
        'PUT',
        '/api/contributions/$id',
        body: updatedContent.toJson(),
      );
      
      if (response.statusCode == 200) {
        // Success - refresh local cache and notify listeners
        await getAllContributions(forceRefresh: true);
        return true;
      } else {
        print('Server responded with status ${response.statusCode}');
        // Try local update as fallback
        final allContributions = await _getLocalContributions();
        final index = allContributions.indexWhere((c) => c.id == id);
        
        if (index != -1) {
          allContributions[index] = updatedContent;
          await _cacheContributions(allContributions);
        }
        return false; // Still report failure so user knows server update failed
      }
    } catch (e) {
      print('Server update failed: $e, updating locally');
      // Fallback to local storage
      try {
        final allContributions = await _getLocalContributions();
        final index = allContributions.indexWhere((c) => c.id == id);
        
        if (index == -1) {
          return false;
        }
        
        allContributions[index] = updatedContent;
        await _cacheContributions(allContributions);
        return false; // Report partial success
      } catch (e) {
        print('Local update also failed: $e');
        return false;
      }
    }
  }
  
  // Delete contribution (from server with local fallback)
  static Future<bool> deleteContribution(String id) async {
    try {
      // Try to delete from server
      final response = await AuthService().authenticatedRequest('DELETE', '/api/contributions/$id');
      
      if (response.statusCode == 200) {
        // Success - refresh local cache and notify listeners
        await getAllContributions(forceRefresh: true);
        return true;
      } else {
        print('Server responded with status ${response.statusCode}');
        // Try local deletion as fallback
        final allContributions = await _getLocalContributions();
        allContributions.removeWhere((c) => c.id == id);
        await _cacheContributions(allContributions);
        return false; // Still report failure so user knows server delete failed
      }
    } catch (e) {
      print('Server delete failed: $e, deleting locally');
      // Fallback to local storage
      try {
        final allContributions = await _getLocalContributions();
        allContributions.removeWhere((c) => c.id == id);
        await _cacheContributions(allContributions);
        return false; // Report partial success
      } catch (e) {
        print('Local delete also failed: $e');
        return false;
      }
    }
  }
  
  // Get contribution by ID
  static Future<UserContent?> getContributionById(String id) async {
    final allContributions = await getAllContributions();
    try {
      return allContributions.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Validate JSON input for content creation
  static Map<String, dynamic>? validateAndParseJson(String jsonString) {
    try {
      final parsed = jsonDecode(jsonString);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      throw FormatException('JSON root must be an object');
    } catch (e) {
      // Re-throw FormatException to provide detailed message to caller
      if (e is FormatException) rethrow;
      throw FormatException(e.toString());
    }
  }
  
  // Create UserContent from parsed JSON
  static UserContent? createContentFromJson(
    Map<String, dynamic> json,
    String authorName,
    CourseCategory category,
    {ContentType? defaultType}
  ) {
    try {
      // Type can come from JSON or be passed as parameter
      final typeString = json['type'] as String?;
      ContentType? contentType = defaultType;
      
      if (typeString != null) {
        // If type is in JSON, use it
        switch (typeString.toLowerCase()) {
          case 'topic':
            contentType = ContentType.topic;
            break;
          case 'quiz':
            contentType = ContentType.quiz;
            break;
          case 'fillblank':
          case 'fill_blank':
            contentType = ContentType.fillBlank;
            break;
          case 'codeexample':
          case 'code_example':
            contentType = ContentType.codeExample;
            break;
        }
      }
      
      // If still no type, we can't create content
      if (contentType == null) return null;
      
      // Remove type from content as it's stored separately
      final contentData = Map<String, dynamic>.from(json);
      contentData.remove('type');
      
      final now = DateTime.now();
      return UserContent(
        id: '${authorName}_${now.millisecondsSinceEpoch}',
        authorName: authorName,
        type: contentType,
        category: category,
        createdAt: now,
        updatedAt: now,
        content: contentData,
      );
    } catch (e) {
      print('Error creating content from JSON: $e');
      return null;
    }
  }
}
